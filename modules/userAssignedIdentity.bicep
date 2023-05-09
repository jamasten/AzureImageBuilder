param Location string
param Name string
param Tags object

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: Name
  location: Location
  tags: Tags
}

output PrincipalId string = userAssignedIdentity.properties.principalId
output ResourceId string = userAssignedIdentity.id
