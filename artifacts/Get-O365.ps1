# Download & extract the Office 365 Deployment Toolkit

$ErrorActionPreference = 'Stop'

try 
{
    $URL = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117'
    $Installer = 'C:\temp\office.exe'
    Invoke-WebRequest -Uri $URL -OutFile $Installer
    Write-Host 'Downloaded the Office 365 Deployment Toolkit'

    Start-Process -FilePath $Installer -ArgumentList "/extract:C:\temp /quiet /passive /norestart" -Wait -PassThru | Out-Null
    Write-Host 'Extracted the Office 365 Deployment Toolkit'
}
catch 
{
    Write-Host $_
    throw
}