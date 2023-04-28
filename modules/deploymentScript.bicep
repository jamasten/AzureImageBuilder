param ContainerName string
param Content string
param DeploymentScriptName string
param FileName string
param Location string
param StorageAccountName string
param Tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' existing = {
  name: StorageAccountName
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: DeploymentScriptName
  location: Location
  tags: Tags
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: Content
      }
    ]
    scriptContent: 'echo "$CONTENT" > ${FileName} && az storage blob upload -f ${FileName} -c ${ContainerName} -n ${FileName}'
  }
}
