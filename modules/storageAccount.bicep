param Assets array
param ContainerName string
param DeploymentScriptName string
param Location string
param PrivateDnsZoneName string
param StorageAccountName string
param StorageEndpoint string
param SubnetName string
param Tags object
param Timestamp string
param UserAssignedIdentityPrincipalId string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string

var RoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
var SubnetResourceId = resourceId(VirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, SubnetName)
var VirtualNetworkRules = {
  PrivateEndpoint: []
  PublicEndpoint: []
  ServiceEndpoint: [
    {
      id: SubnetResourceId
      action: 'Allow'
    }
  ]
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: StorageAccountName
  location: Location
  tags: Tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: VirtualNetworkRules[StorageEndpoint]
      ipRules: []
      defaultAction: StorageEndpoint == 'PublicEndpoint' ? 'Allow' : 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'None'
    }
    largeFileSharesState: null
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
  properties: {}
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: 'artifacts'
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}

module uploadBlobs 'deploymentScript.bicep' = [for i in range(0, length(Assets)): {
  name: 'DeploymentScript_UploadBlob_${i}_${Timestamp}'
  params: {
    ContainerName: ContainerName
    Content: Assets[i].content
    DeploymentScriptName: '${DeploymentScriptName}-uploadBlob-${replace(Assets[i].fileName, '.ps1', '')}'
    FileName: Assets[i].fileName
    Location: Location
    StorageAccountName: StorageAccountName
    Tags: Tags
  }
}]

// Assigns the Storage Blob Data Reader role to the User Assigned Identity on the Azure Blobs container so the build VM can access the assets
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: container
  name: guid(UserAssignedIdentityPrincipalId, RoleDefinitionId, container.id)
  properties: {
    roleDefinitionId: RoleDefinitionId
    principalId: UserAssignedIdentityPrincipalId
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: PrivateDnsZoneName
  location: 'global'
  tags: Tags
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-05-01' = {
  name: 'pe-${storageAccount.name}'
  location: Location
  tags: Tags
  properties: {
    subnet: {
      id: SubnetResourceId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${storageAccount.name}_${guid(storageAccount.name)}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: StorageAccountName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZone
  name: 'link-${VirtualNetworkName}'
  location: 'global'
  tags: Tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(VirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks', VirtualNetworkName)
    }
  }
}
