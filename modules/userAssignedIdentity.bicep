param Environment string
param Location string
param LocationShortName string
param Tags object


resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'uai-aib-${Environment}-${LocationShortName}'
  location: Location
  tags: Tags
}


output PrincipalId string = userAssignedIdentity.properties.principalId
output ResourceId string = userAssignedIdentity.id
