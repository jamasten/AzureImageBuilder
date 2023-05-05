param Environment string
param Location string
param LocationShortName string
param SubnetName string
param Tags object
param Timestamp string
param UserAssignedIdentityResourceId string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ds-aib-${Environment}-${LocationShortName}'
  location: Location
  tags: Tags
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    arguments: '-Subnet ${SubnetName} -VirtualNetwork ${VirtualNetworkName} -ResourceGroup ${VirtualNetworkResourceGroupName}'
    azPowerShellVersion: '9.4'
    cleanupPreference: 'Always'
    forceUpdateTag: Timestamp
    retentionInterval: 'PT2H'
    scriptContent: 'Param([string]$ResourceGroup, [string]$Subnet, [string]$VirtualNetwork); $VNET = Get-AzVirtualNetwork -Name $VirtualNetwork -ResourceGroupName $ResourceGroup; ($VNET | Select-Object -ExpandProperty "Subnets" | Where-Object {$_.Name -eq $Subnet}).privateLinkServiceNetworkPolicies = "Disabled"; $VNET | Set-AzVirtualNetwork'
    timeout: 'PT30M'
  }
}
