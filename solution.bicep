targetScope = 'subscription'

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

@description('Determine whether you want to install FSLogix in the image.')
param InstallFSLogix bool = true

@description('Determine whether you want to install Microsoft Office 365 in the image.')
param InstallOffice bool = true

@description('Determine whether you want to install Microsoft One Drive in the image.')
param InstallOneDrive bool = true

@description('Determine whether you want to install Microsoft Project in the image.')
param InstallProject bool = true

@description('Determine whether you want to install Microsoft Teams in the image.')
param InstallTeams bool = true

@description('Determine whether you want to run the Virtual Desktop Optimization Tool on the image. https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool')
param InstallVirtualDesktopOptimizationTool bool = true

@description('Determine whether you want to install Microsoft Visio in the image.')
param InstallVisio bool = true

@description('The location for the resources deployed in this solution.')
param Location string = deployment().location

@allowed([
  'PrivateEndpoint'
  'PublicEndpoint'
  'ServiceEndpoint'
])
@description('')
param StorageEndpoint string

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

var Assets = [
  {
    content: O365Content
    fileName: O365FileName
  }
  {
    content: subscription().tenantId
    fileName: 'tenantId.txt'
  }
  {
    content: loadTextContent('artifacts/Add-FSLogix.ps1')
    fileName: 'Add-FSLogix.ps1'
  }
  {
    content: loadTextContent('artifacts/Add-O365.ps1')
    fileName: 'Add-O365.ps1'
  }
  {
    content: loadTextContent('artifacts/Add-OneDrive.ps1')
    fileName: 'Add-OneDrive.ps1'
  }
  {
    content: loadTextContent('artifacts/Add-Teams.ps1')
    fileName: 'Add-Teams.ps1'
  }
  {
    content: loadTextContent('artifacts/DeprovisioningScript.ps1')
    fileName: 'DeprovisioningScript.ps1'
  }
  {
    content: loadTextContent('artifacts/Get-FSLogix.ps1')
    fileName: 'Get-FSLogix.ps1'
  }
  {
    content: loadTextContent('artifacts/Get-O365.ps1')
    fileName: 'Get-O365.ps1'
  }
  {
    content: loadTextContent('artifacts/Get-OneDrive.ps1')
    fileName: 'Get-OneDrive.ps1'
  }
  {
    content: loadTextContent('artifacts/Get-Teams.ps1')
    fileName: 'Get-Teams.ps1'
  }
  {
    content: loadTextContent('artifacts/Get-VDOT.ps1')
    fileName: 'Get-VDOT.ps1'
  }
  {
    content: loadTextContent('artifacts/Remove-FSLogix.ps1')
    fileName: 'Remove-FSLogix.ps1'
  }
  {
    content: loadTextContent('artifacts/Remove-OneDrive.ps1')
    fileName: 'Remove-OneDrive.ps1'
  }
  {
    content: loadTextContent('artifacts/Set-RegistrySetting.ps1')
    fileName: 'Set-RegistrySetting.ps1'
  }
  {
    content: loadTextContent('artifacts/Set-VDOT.ps1')
    fileName: 'Set-VDOT.ps1'
  }
]
var ContainerName = 'artifacts'
var ContainerUri = 'https://${StorageAccountName}.blob.${StorageSuffix}/${ContainerName}/'
var DeploymentScriptName = 'ds-${NamingStandard}'
var ImageTemplateName = 'it-${toLower(ImageDefinitionName)}-${Environment}-${LocationShortName}'
var LocationShortName = Locations[Location].acronym
var Locations = loadJsonContent('artifacts/locations.json')
var NamingStandard = 'aib-${Environment}-${LocationShortName}'
var O365FileName = 'office365x64.xml'
var O365ConfigHeader = '<Configuration><Add OfficeClientEdition="64" Channel="Current">'
var O365AddOffice = InstallOffice ? '<Product ID="O365ProPlusRetail"><Language ID="en-us" /></Product>' : ''
var O365AddProject = InstallProject ? '<Product ID="ProjectProRetail"><Language ID="en-us" /></Product>' : ''
var O365AddVisio = InstallVisio ? '<Product ID="VisioProRetail"><Language ID="en-us" /></Product>' : ''
var O365ConfigFooter = '</Add><Updates Enabled="FALSE" /><Display Level="None" AcceptEULA="TRUE" /><Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/><Property Name="SharedComputerLicensing" Value="1"/></Configuration>'
var O365Content = '${O365ConfigHeader}${O365AddOffice}${O365AddProject}${O365AddVisio}${O365ConfigFooter}'
var PrivateDnsZoneName = 'privatelink.blob.${StorageSuffix}'
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
var StorageAccountName = 'saaib${Environment}${LocationShortName}'
var StorageSuffix = environment().suffixes.storage

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
    PrincipalId: userAssignedIdentity.outputs.PrincipalId
    RoleDefinitionId: roleDefinitions[i].id
  }
}]

module storageAccount 'modules/storageAccount.bicep' = {
  scope: rg
  name: 'StorageAccount_${Timestamp}'
  params: {
    Assets: Assets
    ContainerName: ContainerName
    DeploymentScriptName: DeploymentScriptName
    Location: Location
    PrivateDnsZoneName: PrivateDnsZoneName
    StorageAccountName: StorageAccountName
    StorageEndpoint: StorageEndpoint
    SubnetName: SubnetName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityPrincipalId: userAssignedIdentity.outputs.PrincipalId
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
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

module networkPolicy 'modules/networkPolicy.bicep' = if (!(empty(SubnetName)) && !(empty(VirtualNetworkName)) && !(empty(VirtualNetworkResourceGroupName))) {
  name: 'NetworkPolicy_${Timestamp}'
  scope: rg
  params: {
    Environment: Environment
    Location: Location
    LocationShortName: LocationShortName
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
    ContainerUri: ContainerUri
    InstallFSLogix: InstallFSLogix
    InstallOffice: InstallOffice
    InstallOneDrive: InstallOneDrive
    InstallProject: InstallProject
    InstallTeams: InstallTeams
    InstallVirtualDesktopOptimizationTool: InstallVirtualDesktopOptimizationTool
    InstallVisio: InstallVisio
    ImageDefinitionResourceId: computeGallery.outputs.ImageDefinitionResourceId
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageStorageAccountType: ImageStorageAccountType
    ImageTemplateName: ImageTemplateName
    ImageVersion: ImageVersion
    Location: Location
    StagingResourceGroupName: StagingResourceGroupName
    SubnetName: SubnetName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.ResourceId
    VirtualMachineSize: VirtualMachineSize
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
  }
  dependsOn: [
    networkPolicy
    roleAssignments
    storageAccount
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
