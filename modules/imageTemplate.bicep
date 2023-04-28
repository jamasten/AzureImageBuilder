param ContainerUri string
param InstallFSLogix bool
param InstallOffice bool
param InstallOneDrive bool
param InstallProject bool
param InstallTeams bool
param InstallVirtualDesktopOptimizationTool bool
param InstallVisio bool
param ImageDefinitionResourceId string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageStorageAccountType string
param ImageTemplateName string
param ImageVersion string
param Location string
param StagingResourceGroupName string
param SubnetName string
param Tags object
param Timestamp string
param UserAssignedIdentityResourceId string
param VirtualMachineSize string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string


var CreateTempDir = [
  {
    type: 'PowerShell'
    name: 'Create TEMP Directory'
    runElevated: true
    runAsSystem: true
    inline: [
      'New-Item -Path "C:\\" -Name "temp" -ItemType "Directory" -Force | Out-Null; Write-Host "Created Temp Directory"'
    ]
  }
]

var FSLogixType = contains(ImageSku, 'avd') ? [
  {
    type: 'PowerShell'
    name: 'Download FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Get-FSLogix.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Uninstall FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Remove-FSLogix.ps1'
  }
  {
    type: 'WindowsRestart'
    name: 'Restart after FSLogix uninstall'
    restartTimeout: '5m'
  }
  {
    type: 'PowerShell'
    name: 'Install FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Add-FSLogix.ps1'
  }
  {
    type: 'WindowsRestart'
    name: 'Restart after FSLogix install'
    restartTimeout: '5m'
  }
] : [
  {
    type: 'PowerShell'
    name: 'Download FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Get-FSLogix.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Install FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}fslogix.ps1'
  }
  {
    type: 'WindowsRestart'
    name: 'Restart after FSLogix install'
    restartTimeout: '5m'
  }
]
var FSLogix = InstallFSLogix ? FSLogixType : []
var Functions = [
  {
    type: 'File'
    name: 'Download Functions Script'
    sourceUri: '${ContainerUri}Set-RegistrySetting.ps1'
    destination: 'C:\\temp\\Set-RegistrySetting.ps1'
  }
]
var Office = InstallOffice || InstallVisio || InstallProject ? [
  {
    type: 'PowerShell'
    name: 'Download Microsoft Office 365'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Get-O365.ps1'
  }  
  {
    type: 'File'
    name: 'Download Microsoft Office 365 Configuration File'
    sourceUri: '${ContainerUri}office365x64.xml'
    destination: 'C:\\temp\\office365x64.xml'
  }
  {
    type: 'PowerShell'
    name: 'Install Microsoft Office 365'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Add-O365.ps1'
  }
] : []
var OneDriveType = ImageSku == 'office-365' ? [
  {
    type: 'PowerShell'
    name: 'Download OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Get-OneDrive.ps1'
  }
  {
    type: 'File'
    name: 'Download OneDrive Configuration File'
    sourceUri: '${ContainerUri}tenantId.txt'
    destination: 'C:\\temp\\tenantId.txt'
  }
  {
    type: 'PowerShell'
    name: 'Uninstall OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Remove-OneDrive.ps1'
  }
  {
    type: 'WindowsRestart'
    name: 'Restart after OneDrive uninstall'
    restartTimeout: '5m'
  }
  {
    type: 'PowerShell'
    name: 'Install OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Add-OneDrive.ps1'
  }
] : [
  {
    type: 'PowerShell'
    name: 'Download OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Get-OneDrive.ps1'
  }
  {
    type: 'File'
    name: 'Download OneDrive Configuration File'
    sourceUri: '${ContainerUri}tenantId.txt'
    destination: 'C:\\temp\\tenantId.txt'
  }
  {
    type: 'PowerShell'
    name: 'Install OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Add-OneDrive.ps1'
  }
]
var OneDrive = InstallOneDrive ? OneDriveType : []
var Sysprep =  [
  {
    type: 'File'
    name: 'Download custom Sysprep script'
    sourceUri: '${ContainerUri}DeprovisioningScript.ps1'
    destination: 'C:\\DeprovisioningScript.ps1'
  }
]
var Teams = InstallTeams ? [
  {
    type: 'PowerShell'
    name: 'Download Teams'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Get-Teams.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Install Teams'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Add-Teams.ps1'
  }
] : []
var VDOT = InstallVirtualDesktopOptimizationTool ? [
  {
    type: 'PowerShell'
    name: 'Download the Virtual Desktop Optimization Tool'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Get-VDOT.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Execute the Virtual Desktop Optimization Tool'
    runElevated: true
    runAsSystem: true
    scriptUri: '${ContainerUri}Set-VDOT.ps1'
  }
  {
    type: 'WindowsRestart'
    name: 'Restart after VDOT execution'
    restartTimeout: '5m'
  }
] : []
var RemoveTempDir = [
  {
    type: 'PowerShell'
    name: 'Remove TEMP Directory'
    runElevated: true
    runAsSystem: true
    inline: [
      'Remove-Item -Path "C:\\temp" -Recurse -Force | Out-Null; Write-Host "Removed Temp Directory"'
    ]
  }
]
var WindowsUpdate = [
  {
    type: 'WindowsUpdate'
    searchCriteria: 'IsInstalled=0'
    filters: [
      'exclude:$_.Title -like \'*Preview*\''
      'include:$true'
    ]
  }
  {
    type: 'WindowsRestart'
    name: 'Restart after Windows Updates'
    restartTimeout: '5m'
  }
]
var Customizers = union(CreateTempDir, VDOT, Functions, FSLogix, Office, OneDrive, Teams, RemoveTempDir, WindowsUpdate, Sysprep)


resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: ImageTemplateName
  location: Location
  tags: Tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {
      }
    }
  }
  properties: {
    stagingResourceGroup: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${StagingResourceGroupName}'
    buildTimeoutInMinutes: 300
    vmProfile: {
      userAssignedIdentities: [
        UserAssignedIdentityResourceId
      ]
      vmSize: VirtualMachineSize
      vnetConfig: !empty(SubnetName) ? {
        subnetId: resourceId(VirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, SubnetName)
      } : null
    }
    source: {
      type: 'PlatformImage'
      publisher: ImagePublisher
      offer: ImageOffer
      sku: ImageSku
      version: ImageVersion
    }
    customize: Customizers
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: ImageDefinitionResourceId
        runOutputName: Timestamp
        artifactTags: {}
        replicationRegions: [
          Location
        ]
        storageAccountType: ImageStorageAccountType
      }
    ]
  }
}
