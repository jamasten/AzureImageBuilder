# Azure Image Builder

This solution will deploy all the Azure resources needed to build an image with Azure Image Builder (AIB). It includes all of Microsoft's security best practices. Each time a new build is run, the AIB service will use a pre-configured virtual network with private link to connect to the virtual machine. This avoids the use of public IP addresses. The role assignments given to the AIB service and Automation Account are the minimum required, adhering to least privilege.

The Image Template is currently configured to run the [Virtual Desktop Optimization Tool](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool), install Microsoft Project & Visio, and update the operating system. The customization steps in the Image Template can be modified to fulfill your solution requirements. Refer to the [Microsoft Learn page](https://learn.microsoft.com/azure/virtual-machines/linux/image-builder-json?tabs=json%2Cazure-powershell#properties-customize) for details on the allowed customizations.

## Build Automation

A feature of this solution is build automation. This feature uses an Automation Runbook and a Logic App to check if a new Azure Marketplace image version has been released since you're last Image Template build. If the Marketplace image version is newer, a new build will be initiated on the Image Template.

If a resource ID for a Log Analytics Workspace is specified during deployment, the Automation Runbook's job logs and streams will be captured in the workspace. This will allow you to create alerts around the Image Template builds so you will know when a new Image Version has been added to your Compute Gallery or when a build fails.

## Resources

The following resources are deployed with this solution:

- Compute Gallery
  - Image Definition
- Deployment Script (temporary)
  - Container Instance (temporary)
  - Storage Account (temporary)
- Image Template
- Role Definitions
- Role Assignments
- User Assigned Identity

## Prerequisites

- Virtual Network (Optional): ensure a virtual network has been deployed and the target subnet has an assigned Network Security Group with the required rule configured: [PowerShell for NSG Rule](https://learn.microsoft.com/azure/virtual-machines/windows/image-builder-vnet#add-an-nsg-rule)

## Considerations

If you plan to store your AIB customizer assets on an Azure storage account with either service or private endpoints, and not allow anonymous access to the Azure Blobs container, there are extra steps you must perform for a successful build. First, the user assigned identity must be added as an identity on the build VM. That is already configured in this solution. Second, the user assigned identity must be assigned the Storage Blob Data Reader role on the container. Lastly, the following code snippet should be used with a PowerShell inline command customizer to properly access and authorize the downloads of your assets from the container.

```powershell
$UserAssignedIdentityObjectId = '<object / principal ID for user assigned identity>'
$StorageAccountName = '<storage account name>'
$ContainerName = '<container name>'
$BlobName = '<blob name>'
$StorageAccountUrl = 'https://' + $StorageAccountName + '.blob.core.windows.net'
$TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl/&object_id=$UserAssignedIdentityObjectId"
$AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl/$ContainerName/$BlobName" -OutFile "C:\temp\$BlobName"
```

## Deployment Options

To deploy this solution, the principal must have Owner privileges on the Azure subscription.

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureImageBuilder%2Fmain%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureImageBuilder%2Fmain%2Fsolution.json)

### PowerShell

````powershell
New-AzDeployment `
    -Location '<Azure location>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/AzureImageBuilder/main/solution.json' `
    -Verbose
````

### Azure CLI

````cli
az deployment sub create \
    --location '<Azure location>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/AzureImageBuilder/main/solution.json'
````
