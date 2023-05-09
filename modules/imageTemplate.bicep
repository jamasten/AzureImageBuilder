param ImageDefinitionResourceId string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageStorageAccountType string
param ImageTemplateName string
param ImageVersion string
param InstallAccess bool
param InstallExcel bool
param InstallFSLogix bool
param InstallOneDriveForBusiness bool
param InstallOneNote bool
param InstallOutlook bool
param InstallPowerPoint bool
param InstallProject bool
param InstallPublisher bool
param InstallSkypeForBusiness bool
param InstallTeams bool
param InstallVirtualDesktopOptimizationTool bool
param InstallVisio bool
param InstallWord bool
param Location string
param StagingResourceGroupName string
param SubnetName string
param Tags object
param TeamsUrl string
param Timestamp string
param UserAssignedIdentityResourceId string
param VirtualMachineSize string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string

var CreateTempDir = [
  {
    type: 'PowerShell'
    name: 'Create the TEMP Directory'
    runElevated: true
    runAsSystem: true
    inline: [
      'New-Item -Path "C:\\" -Name "temp" -ItemType "Directory" -Force | Out-Null'
      'Write-Host "Created Temp Directory"'
    ]
  }
]
var Environment = environment().name
var FSLogix = InstallFSLogix ? [
  {
    type: 'PowerShell'
    name: 'Download FSLogix'
    runElevated: true
    runAsSystem: true
    inline: [
      '$ErrorActionPreference = "Stop"'
      '$ZIP = "C:\\temp\\fslogix.zip"'
      'Invoke-WebRequest -Uri "https://aka.ms/fslogix_download" -OutFile $ZIP'
      'Unblock-File -Path $ZIP'
      'Expand-Archive -LiteralPath $ZIP -DestinationPath "C:\\temp\\fslogix" -Force'
      'Write-Host "Downloaded the latest version of FSLogix"'
    ]
  }
  {
    type: 'PowerShell'
    name: 'Install FSLogix'
    runElevated: true
    runAsSystem: true
    inline: [
      '$ErrorActionPreference = "Stop"'
      'Start-Process -FilePath "C:\\temp\\fslogix\\x64\\Release\\FSLogixAppsSetup.exe" -ArgumentList "/install /quiet /norestart" -Wait -PassThru | Out-Null'
      'Write-Host "Installed the latest version of FSLogix"'
    ]
  }
  {
    type: 'WindowsRestart'
    name: 'Restart after the installation of FSLogix '
  }
] : []
var MultiSessionOs = contains(ImageSku, 'avd') || contains(ImageSku, 'evd')
var O365ConfigHeader = '<Configuration><Add OfficeClientEdition="64" Channel="Current">'
var O365AddOfficeHeader = InstallAccess || InstallExcel || InstallOneDriveForBusiness || InstallOneNote || InstallOutlook || InstallPowerPoint || InstallPublisher || InstallSkypeForBusiness || (InstallTeams && Environment == 'AzureCloud') || InstallWord ? '<Product ID="O365ProPlusRetail"><Language ID="en-us" />' : ''
var O365AddAccess = InstallAccess ? '' : '<ExcludeApp ID="Access" />'
var O365AddExcel = InstallExcel ? '' : '<ExcludeApp ID="Excel" />'
var O365AddOneDriveForBusiness = InstallOneDriveForBusiness ? '' : '<ExcludeApp ID="Groove" />'
var O365AddOneNote = InstallOneNote ? '' : '<ExcludeApp ID="OneNote" />'
var O365AddOutlook = InstallOutlook ? '' : '<ExcludeApp ID="Outlook" />'
var O365AddPowerPoint = InstallPowerPoint ? '' : '<ExcludeApp ID="PowerPoint" />'
var O365AddPublisher = InstallPublisher ? '' : '<ExcludeApp ID="Publisher" />'
var O365AddSkypeForBusiness = InstallSkypeForBusiness ? '' : '<ExcludeApp ID="Lync" />'
var O365AddTeams = InstallTeams && Environment == 'AzureCloud' ? '' : '<ExcludeApp ID="Teams" />'
var O365AddWord = InstallWord ? '' : '<ExcludeApp ID="Word" />'
var O365AddOfficeFooter = InstallAccess || InstallExcel || InstallOneDriveForBusiness || InstallOneNote || InstallOutlook || InstallPowerPoint || InstallPublisher || InstallSkypeForBusiness || (InstallTeams && Environment == 'AzureCloud') || InstallWord ? '</Product>' : ''
var O365AddProject = InstallProject ? '<Product ID="ProjectProRetail"><Language ID="en-us" /></Product>' : ''
var O365AddVisio = InstallVisio ? '<Product ID="VisioProRetail"><Language ID="en-us" /></Product>' : ''
var O365Settings = '</Add><Updates Enabled="FALSE" /><Display Level="None" AcceptEULA="TRUE" /><Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>'
var O365SharedActivation = MultiSessionOs ? '<Property Name="SharedComputerLicensing" Value="1"/>' : ''
var O365ConfigFooter = '</Configuration>'
var O365Content = '${O365ConfigHeader}${O365AddOfficeHeader}${O365AddAccess}${O365AddExcel}${O365AddOneDriveForBusiness}${O365AddOneNote}${O365AddOutlook}${O365AddPowerPoint}${O365AddPublisher}${O365AddSkypeForBusiness}${O365AddTeams}${O365AddWord}${O365AddOfficeFooter}${O365AddProject}${O365AddVisio}${O365Settings}${O365SharedActivation}${O365ConfigFooter}'
var Office = InstallAccess || InstallExcel || InstallOneDriveForBusiness || InstallOneNote || InstallOutlook || InstallPowerPoint || InstallPublisher || InstallSkypeForBusiness || (InstallTeams && Environment == 'AzureCloud') || InstallWord || InstallVisio || InstallProject ? [
  {
    type: 'PowerShell'
    name: 'Upload the Microsoft Office 365 Configuration File'
    runElevated: true
    runAsSystem: true
    inline: [
      '$Configuration = "${O365Content}"'
      '$Configuration | Out-File -FilePath "C:\\temp\\office365x64.xml" -ErrorAction "Stop"'
      'Write-Host "Uploaded the Office365 configuration file"'
    ]
  }
  {
    type: 'PowerShell'
    name: 'Download & extract the Microsoft Office 365 Deployment Toolkit'
    runElevated: true
    runAsSystem: true
    inline: [
      '$ErrorActionPreference = "Stop"'
      '$Installer = "C:\\temp\\office.exe"'
      'Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117" -OutFile $Installer'
      'Start-Process -FilePath $Installer -ArgumentList "/extract:C:\\temp /quiet /passive /norestart" -Wait -PassThru | Out-Null'
      'Write-Host "Downloaded & extracted the Office 365 Deployment Toolkit"'
    ]
  }
  {
    type: 'PowerShell'
    name: 'Install the selected Microsoft Office 365 applications'
    runElevated: true
    runAsSystem: true
    inline: [
      '$ErrorActionPreference = "Stop"'
      'Start-Process -FilePath "C:\\temp\\setup.exe" -ArgumentList "/configure C:\\temp\\office365x64.xml" -Wait -PassThru | Out-Null'
      'Write-Host "Installed the selected Office365 applications"'
    ]
  }
] : []
var Sysprep = [
  {
    type: 'PowerShell'
    name: 'Update the sysprep mode on the Deprovisioning Script'
    runElevated: true
    runAsSystem: true
    inline: [
      '$ErrorActionPreference = "Stop"'
      '$Path = "C:\\DeprovisioningScript.ps1"'
      '((Get-Content -Path $Path -Raw).Replace("/quit";"/quit /mode:vm") | Set-Content -Path $Path'
      'Write-Host "Updated the deprovisioning script"'
    ]
  }
]
var Teams = InstallTeams && Environment == 'AzureUSGovernment' ? [
  {
    type: 'PowerShell'
    name: 'Enable media optimizations for Teams'
    runElevated: true
    runAsSystem: true
    inline: [
      'if(${MultiSessionOs} -eq "true"){Start-Process "reg" -ArgumentList "add HKLM\\SOFTWARE\\Microsoft\\Teams /v IsWVDEnvironment /t REG_DWORD /d 1 /f" -Wait -PassThru -ErrorAction "Stop"; Write-Host "Enabled media optimizations for Teams"}'
    ]
  }
  {
    type: 'PowerShell'
    name: 'Download & install the latest version of Microsoft Visual C++ Redistributable'
    runElevated: true
    runAsSystem: true
    inline: [
      '$ErrorActionPreference = "Stop"'
      '$File = "C:\\temp\\vc_redist.x64.exe"'
      'Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vc_redist.x64.exe" -OutFile $File'
      'Start-Process -FilePath $File -Args "/install /quiet /norestart /log vcdist.log" -Wait -PassThru | Out-Null'
      'Write-Host "Installed the latest version of Microsoft Visual C++ Redistributable"'
    ]
  }
  {
    type: 'PowerShell'
    name: 'Download & install the Remote Desktop WebRTC Redirector Service'
    runElevated: true
    runAsSystem: true
    inline: [
      '$ErrorActionPreference = "Stop"'
      '$File = "C:\\temp\\webSocketSvc.msi"'
      'Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt" -OutFile $File'
      'Start-Process -FilePath msiexec.exe -Args "/i $File /quiet /qn /norestart /passive /log webSocket.log" -Wait -PassThru | Out-Null'
      'Write-Host "Installed the Remote Desktop WebRTC Redirector Service"'
    ]
  }
  {
    type: 'PowerShell'
    name: 'Download & install Teams'
    runElevated: true
    runAsSystem: true
    inline: [
      '$ErrorActionPreference = "Stop"'
      '$File = "C:\\temp\\teams.msi"'
      'Invoke-WebRequest -Uri "${TeamsUrl}" -OutFile $File'
      'Start-Process -FilePath msiexec.exe -Args "/i $File /quiet /qn /norestart /passive /log teams.log ALLUSER=1 ALLUSERS=1" -Wait -PassThru | Out-Null'
      'Write-Host "Installed Teams"'
    ]
  }
] : []
var VDOT = InstallVirtualDesktopOptimizationTool ? [
  {
    type: 'PowerShell'
    name: 'Download & execute the Virtual Desktop Optimization Tool'
    runElevated: true
    runAsSystem: true
    inline: [
      '$ErrorActionPreference = "Stop"'
      '$ZIP = "C:\\temp\\VDOT.zip"'
      'Invoke-WebRequest -Uri "https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip" -OutFile $ZIP'
      'Unblock-File -Path $ZIP'
      'Expand-Archive -LiteralPath $ZIP -DestinationPath "C:\\temp" -Force'
      '$Path = (Get-ChildItem -Path "C:\\temp" -Recurse | Where-Object {$_.Name -eq "Windows_VDOT.ps1"}).FullName'
      '$Script = Get-Content -Path $Path'
      '$ScriptUpdate = $Script.Replace("Set-NetAdapterAdvancedProperty";"#Set-NetAdapterAdvancedProperty")'
      '$ScriptUpdate | Set-Content -Path $Path'
      '& $Path -Optimizations @("AppxPackages";"Autologgers";"DefaultUserSettings";"LGPO";"NetworkOptimizations";"ScheduledTasks";"Services";"WindowsMediaPlayer") -AdvancedOptimizations @("Edge";"RemoveLegacyIE") -AcceptEULA'
      'Write-Host "Optimized the operating system using the Virtual Desktop Optimization Tool"'
    ]
  }
  {
    type: 'WindowsRestart'
    name: 'Restart after the execution of the Virtual Desktop Optimization Tool'
  }
] : []
var RemoveTempDir = [
  {
    type: 'PowerShell'
    name: 'Remove the TEMP Directory'
    runElevated: true
    runAsSystem: true
    inline: [
      'Remove-Item -Path "C:\\temp" -Recurse -Force -ErrorAction "Stop" | Out-Null'
      'Write-Host "Removed Temp Directory"'
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
    name: 'Restart after the Windows Updates'

  }
]

resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: ImageTemplateName
  location: Location
  tags: Tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {}
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
    customize: union(CreateTempDir, VDOT, FSLogix, Office, Teams, RemoveTempDir, WindowsUpdate, Sysprep)
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
