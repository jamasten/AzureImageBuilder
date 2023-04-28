targetScope = 'subscription'


@description('Determine whether you want to install FSLogix in the image.')
param DeployFSLogix bool = true

@description('Determine whether you want to install Microsoft Office 365 in the image.')
param DeployOffice bool = true

@description('Determine whether you want to install Microsoft One Drive in the image.')
param DeployOneDrive bool = true

@description('Determine whether you want to install Microsoft Project in the image.')
param DeployProject bool = true

@description('Determine whether you want to install Microsoft Teams in the image.')
param DeployTeams bool = true

@description('Determine whether you want to run the Virtual Desktop Optimization Tool on the image. https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool')
param DeployVirtualDesktopOptimizationTool bool = true

@description('Determine whether you want to install Microsoft Visio in the image.')
param DeployVisio bool = true

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

@description('Any Azure polices that would affect the AIB build VM should have an exemption for the AIB staging resource group. Common examples are policies that push the Guest Configuration agent or the Microsoft Defender for Endpoint agent. Reference: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-troubleshoot#prerequisites')
param ExemptPolicyAssignmentIds array = [
  '/subscriptions/3764b123-4849-4395-8e6e-ca6d68d8d4b4/providers/Microsoft.Authorization/policyAssignments/ASC provisioning Guest Configuration agent for Windows'
]

@description('The name of the Image Definition for the Shared Image Gallery.')
param ImageDefinitionName string = 'Win11-22h2-avd'

@allowed([
  'ConfidentialVM'
  'ConfidentialVMSupported'
  'Standard'
  'TrustedLaunch'
])
@description('The security type for the Image Definition.')
param ImageDefinitionSecurityType string = 'TrustedLaunch'

@description('The offer of the marketplace image.')
param ImageOffer string = 'windows-11'

@description('The publisher of the marketplace image.')
param ImagePublisher string = 'microsoftwindowsdesktop'

@description('The SKU of the marketplace image.')
param ImageSku string = 'win11-22h2-avd'

@description('The version of the marketplace image.')
param ImageVersion string = 'latest'

@description('The storage SKU for the image version replica in the Shared Image Gallery.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
])
param ImageStorageAccountType string = 'Standard_LRS'

@description('The location for the resources deployed in this solution.')
param Location string = deployment().location

@description('The name for the storage account containing the scripts & application installers.')
param StorageAccountName string = 'sacoredeu'

@description('The resource group name for the storage account containing the scripts & application installers.')
param StorageAccountResourceGroupName string = 'rg-core-d-eu'

@description('The name of the container in the storage account containing the scripts & application installers.')
param StorageContainerName string = 'artifacts'

@description('The subnet name for the custom virtual network.')
param SubnetName string = 'Clients'

param Tags object = {}

@description('DO NOT MODIFY THIS VALUE! The timestamp is needed to differentiate deployments for certain Azure resources and must be set using a parameter.')
param Timestamp string = utcNow('yyyyMMddhhmmss')

@description('The size of the virtual machine used for creating the image.  The recommendation is to use a \'Standard_D2_v2\' size or greater for AVD. https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/14_Building_Images_WVD')
param VirtualMachineSize string = 'Standard_D4ds_v5'

@description('The name for the custom virtual network.')
param VirtualNetworkName string = 'vnet-net-d-eu'

@description('The resource group name for the custom virtual network.')
param VirtualNetworkResourceGroupName string = 'rg-net-d-eu'


var DeploymentScriptName = 'ds-${NamingStandard}'
var ImageTemplateName = 'it-${toLower(ImageDefinitionName)}-${Environment}-${LocationShortName}'
var LocationShortName = Locations[Location].acronym
var Locations = loadJsonContent('artifacts/locations.json')
var NamingStandard = 'aib-${Environment}-${LocationShortName}'
var ResourceGroup = 'rg-${NamingStandard}'
var Roles = [
  {
    resourceGroup: VirtualNetworkResourceGroupName
    name: 'Virtual Network Join'
    description: 'Allow resources to join a subnet'
    permissions: [
      {
        actions: [
          'Microsoft.Network/virtualNetworks/read'
          'Microsoft.Network/virtualNetworks/subnets/read'
          'Microsoft.Network/virtualNetworks/subnets/join/action'
          'Microsoft.Network/virtualNetworks/subnets/write' // Required to update the private link network policy
        ]
      }
    ]
  }
  {
    resourceGroup: ResourceGroup
    name: 'Image Template Contributor'
    description: 'Allow the creation and management of images'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/galleries/read'
          'Microsoft.Compute/galleries/images/read'
          'Microsoft.Compute/galleries/images/versions/read'
          'Microsoft.Compute/galleries/images/versions/write'
          'Microsoft.Compute/images/read'
          'Microsoft.Compute/images/write'
          'Microsoft.Compute/images/delete'
        ]
      }
    ]
  }
]
var StagingResourceGroupName = 'rg-aib-${Environment}-${LocationShortName}-staging-${toLower(ImageDefinitionName)}'
var StorageUri = 'https://${StorageAccountName}.blob.${environment().suffixes.storage}/${StorageContainerName}/'


resource rg 'Microsoft.Resources/resourceGroups@2019-10-01' = {
  name: ResourceGroup
  location: Location
  tags: Tags
  properties: {}
}

resource roleDefinitions 'Microsoft.Authorization/roleDefinitions@2015-07-01' = [for i in range(0, length(Roles)): {
  name: guid(Roles[i].name, subscription().id)
  properties: {
    roleName: '${Roles[i].name} (${subscription().subscriptionId})'
    description: Roles[i].description
    permissions: Roles[i].permissions
    assignableScopes: [
      subscription().id
    ]
  }
}]

module userAssignedIdentity 'modules/userAssignedIdentity.bicep' = {
  name: 'UserAssignedIdentity_${Timestamp}'
  scope: rg
  params: {
    Environment: Environment
    Location: Location
    LocationShortName: LocationShortName
    Tags: Tags
  }
}

@batchSize(1)
module roleAssignments 'modules/roleAssignments.bicep' = [for i in range(0, length(Roles)): {
  name: 'RoleAssignments_${i}_${Timestamp}'
  scope: resourceGroup(Roles[i].resourceGroup)
  params: {
    PrincipalId: userAssignedIdentity.outputs.userAssignedIdentityPrincipalId
    RoleDefinitionId: roleDefinitions[i].id
  }
}]

module roleAssignment_Storage 'modules/roleAssignments.bicep' = {
  name: 'RoleAssignment_${StorageAccountName}_${Timestamp}'
  scope: resourceGroup(StorageAccountResourceGroupName)
  params: {
    PrincipalId: userAssignedIdentity.outputs.userAssignedIdentityPrincipalId
    RoleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
    StorageAccountName: StorageAccountName
  }
}

module computeGallery 'modules/computeGallery.bicep' = {
  name: 'ComputeGallery_${Timestamp}'
  scope: rg
  params: {
    Environment: Environment
    ImageDefinitionName: ImageDefinitionName
    ImageDefinitionSecurityType: ImageDefinitionSecurityType
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    Location: Location
    LocationShortName: LocationShortName
    Tags: Tags
  }
}

module networkPolicy 'modules/networkPolicy.bicep' = if(!(empty(SubnetName)) && !(empty(VirtualNetworkName)) && !(empty(VirtualNetworkResourceGroupName))) {
  name: 'NetworkPolicy_${Timestamp}'
  scope: rg
  params: {
    Environment: Environment
    Location: Location
    LocationShortName: LocationShortName
    SubnetName: SubnetName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.userAssignedIdentityResourceId
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
  }
  dependsOn: [
    roleAssignment_Storage
    roleAssignments
  ]
}

module office365 'modules/o365.bicep' = if(DeployOffice || DeployProject || DeployVisio) {
  scope: rg
  name: 'Office365_Configuration_${Timestamp}'
  params: {
    DeploymentScriptName: DeploymentScriptName
    DeployOffice: DeployOffice
    DeployProject: DeployProject
    DeployVisio: DeployVisio
    Location: Location
    StorageAccountName: StorageAccountName
    StorageAccountResourceGroupName: StorageAccountResourceGroupName
    StorageContainerName: StorageContainerName
    Tags: Tags
  }
}

module oneDrive 'modules/oneDrive.bicep' = if(DeployOneDrive) {
  scope: rg
  name: 'OneDrive_Configuration_${Timestamp}'
  params: {
    DeploymentScriptName: DeploymentScriptName
    Location: Location
    StorageAccountName: StorageAccountName
    StorageAccountResourceGroupName: StorageAccountResourceGroupName
    StorageContainerName: StorageContainerName
    Tags: Tags
  }
}

module imageTemplate 'modules/imageTemplate.bicep' = {
  name: 'ImageTemplate_${Timestamp}'
  scope: rg
  params: {
    DeployFSLogix: DeployFSLogix
    DeployOffice: DeployOffice
    DeployOneDrive: DeployOneDrive
    DeployProject: DeployProject
    DeployTeams: DeployTeams
    DeployVirtualDesktopOptimizationTool: DeployVirtualDesktopOptimizationTool
    DeployVisio: DeployVisio
    ImageDefinitionResourceId: computeGallery.outputs.ImageDefinitionResourceId
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageStorageAccountType: ImageStorageAccountType
    ImageTemplateName: ImageTemplateName
    ImageVersion: ImageVersion
    Location: Location
    StagingResourceGroupName: StagingResourceGroupName
    StorageUri: StorageUri
    SubnetName: SubnetName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.userAssignedIdentityResourceId
    VirtualMachineSize: VirtualMachineSize
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
  }
  dependsOn: [
    networkPolicy
    office365
    oneDrive
    roleAssignment_Storage
    roleAssignments
  ]
}

module policyExemptions 'modules/exemption.bicep' = [for i in range(0, length(ExemptPolicyAssignmentIds)): if(length(ExemptPolicyAssignmentIds) > 0) {
  name: 'PolicyExemption_${i}'
  scope: resourceGroup(StagingResourceGroupName)
  params: {
    PolicyAssignmentId: ExemptPolicyAssignmentIds[i]
  }
  dependsOn: [
    imageTemplate
  ]
}]
