targetScope = 'subscription'

@description('The name of the compute gallery for managing the images.')
param ComputeGalleryName string = 'cg_aib_d_use'

@description('The name of the deployment script for configuring an existing subnet.')
param DeploymentScriptName string = 'ds-aib-d-use'

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

@description('The name of the image template used to build an image with AIB.')
param ImageTemplateName string = 'it-d-va-win11-22h2-avd'

@description('Determine whether you want to install Microsoft Access in the image.')
param InstallAccess bool = true

@description('Determine whether you want to install Microsoft Excel in the image.')
param InstallExcel bool = true

@description('Determine whether you want to install FSLogix in the image.')
param InstallFSLogix bool = true

@description('Determine whether you want to install Microsoft One Drive for Business in the image.')
param InstallOneDriveForBusiness bool = true

@description('Determine whether you want to install Microsoft OneNote in the image.')
param InstallOneNote bool = true

@description('Determine whether you want to install Microsoft Outlook in the image.')
param InstallOutlook bool = true

@description('Determine whether you want to install Microsoft PowerPoint in the image.')
param InstallPowerPoint bool = true

@description('Determine whether you want to install Microsoft Project in the image.')
param InstallProject bool = true

@description('Determine whether you want to install Microsoft Publisher in the image.')
param InstallPublisher bool = true

@description('Determine whether you want to install Microsoft Skype for Business in the image.')
param InstallSkypeForBusiness bool = true

@description('Determine whether you want to install Microsoft Teams in the image.')
param InstallTeams bool = true

@description('Determine whether you want to execute the Virtual Desktop Optimization Tool on the image. https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool')
param InstallVirtualDesktopOptimizationTool bool = true

@description('Determine whether you want to install Microsoft Visio in the image.')
param InstallVisio bool = true

@description('Determine whether you want to install Microsoft Word in the image.')
param InstallWord bool = true

@description('The location for the resources deployed in this solution.')
param Location string = deployment().location

param ResourceGroupName string = 'rg-aib-d-use'

@description('The subnet name of an existing virtual network.')
param SubnetName string = 'Clients'

param Tags object = {}

@allowed([
  'Commercial'
  'DepartmentOfDefense'
  'GovernmentCommunityCloud'
  'GovernmentCommunityCloudHigh'
])
param TenantType string = 'Commercial'

@description('DO NOT MODIFY THIS VALUE! The timestamp is needed to differentiate deployments for certain Azure resources and must be set using a parameter.')
param Timestamp string = utcNow('yyyyMMddhhmmss')

param UserAssignedIdentityName string = 'uai-aib-d-use'

@description('The size of the virtual machine used for creating the image.  The recommendation is to use a \'Standard_D2_v2\' size or greater for AVD. https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/14_Building_Images_WVD')
param VirtualMachineSize string = 'Standard_D4ds_v5'

@description('The name of an existing virtual network. If choosing a private endpoint for the storage account, the virtual network should contain a DNS server with the appropriate conditional forwarder.')
param VirtualNetworkName string = 'vnet-net-d-eu'

@description('The resource group name of an existing virtual network. If choosing a private endpoint for the storage account, the virtual network should contain a DNS server with the appropriate conditional forwarder.')
param VirtualNetworkResourceGroupName string = 'rg-net-d-eu'

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
    resourceGroup: ResourceGroupName
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
var StagingResourceGroupName = '${ResourceGroupName}-staging-${ImageSku}'
var TeamsUrl = TeamsUrls[TenantType]

// https://learn.microsoft.com/en-us/deployoffice/teams-install
var TeamsUrls = {
  Commercial: 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
  DepartmentOfDefense: 'https://dod.teams.microsoft.us/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
  GovernmentCommunityCloud: 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&ring=general_gcc&download=true'
  GovernmentCommunityCloudHigh: 'https://gov.teams.microsoft.us/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
}

resource rg 'Microsoft.Resources/resourceGroups@2019-10-01' = {
  name: ResourceGroupName
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
    Location: Location
    Name: UserAssignedIdentityName
    Tags: Tags
  }
}

@batchSize(1)
module roleAssignments 'modules/roleAssignment.bicep' = [for i in range(0, length(Roles)): {
  name: 'RoleAssignments_${i}_${Timestamp}'
  scope: resourceGroup(Roles[i].resourceGroup)
  params: {
    PrincipalId: userAssignedIdentity.outputs.PrincipalId
    RoleDefinitionId: roleDefinitions[i].id
  }
}]

module computeGallery 'modules/computeGallery.bicep' = {
  name: 'ComputeGallery_${Timestamp}'
  scope: rg
  params: {
    ComputeGalleryName: ComputeGalleryName
    ImageDefinitionName: ImageDefinitionName
    ImageDefinitionSecurityType: ImageDefinitionSecurityType
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    Location: Location
    Tags: Tags
  }
}

module networkPolicy 'modules/networkPolicy.bicep' = if (!(empty(SubnetName)) && !(empty(VirtualNetworkName)) && !(empty(VirtualNetworkResourceGroupName))) {
  name: 'NetworkPolicy_${Timestamp}'
  scope: rg
  params: {
    DeploymentScriptName: DeploymentScriptName
    Location: Location
    SubnetName: SubnetName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.ResourceId
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
  }
  dependsOn: [
    roleAssignments
  ]
}

module imageTemplate 'modules/imageTemplate.bicep' = {
  name: 'ImageTemplate_${Timestamp}'
  scope: rg
  params: {
    ImageDefinitionResourceId: computeGallery.outputs.ImageDefinitionResourceId
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageStorageAccountType: ImageStorageAccountType
    ImageTemplateName: ImageTemplateName
    ImageVersion: ImageVersion
    InstallAccess: InstallAccess
    InstallExcel: InstallExcel
    InstallFSLogix: InstallFSLogix
    InstallOneDriveForBusiness: InstallOneDriveForBusiness
    InstallOneNote: InstallOneNote
    InstallOutlook: InstallOutlook
    InstallPowerPoint: InstallPowerPoint
    InstallProject: InstallProject
    InstallPublisher: InstallPublisher
    InstallSkypeForBusiness: InstallSkypeForBusiness
    InstallTeams: InstallTeams
    InstallVirtualDesktopOptimizationTool: InstallVirtualDesktopOptimizationTool
    InstallVisio: InstallVisio
    InstallWord: InstallWord
    Location: Location
    StagingResourceGroupName: StagingResourceGroupName
    SubnetName: SubnetName
    Tags: Tags
    TeamsUrl: TeamsUrl
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.ResourceId
    VirtualMachineSize: VirtualMachineSize
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
  }
  dependsOn: [
    networkPolicy
    roleAssignments
  ]
}

module policyExemptions 'modules/exemption.bicep' = [for i in range(0, length(ExemptPolicyAssignmentIds)): if (length(ExemptPolicyAssignmentIds) > 0) {
  name: 'PolicyExemption_${i}'
  scope: resourceGroup(StagingResourceGroupName)
  params: {
    PolicyAssignmentId: ExemptPolicyAssignmentIds[i]
  }
  dependsOn: [
    imageTemplate
  ]
}]
