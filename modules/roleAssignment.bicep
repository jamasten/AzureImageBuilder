param PrincipalId string
param RoleDefinitionId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(PrincipalId, RoleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: RoleDefinitionId
    principalId: PrincipalId
    principalType: 'ServicePrincipal'
  }
}
