targetScope = 'subscription'

@description('Environment Name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string 

@description('Location for the deployment')
param location string

@description('Log Analytics Workspace')
param workspaceId string

@description('Landing Zone Information')
param landingZone object

param formattedDateTime string = utcNow()

var networkSettings = loadJsonContent('../../infra/settings/connectivity/settings.json')

@description('Resource Group')
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.create) {
  name: '${landingZone.name}-${environmentName}-rg'
  location: location
  tags: landingZone.tags
}

var vNetResourceGroupName = landingZone.create ? resourceGroup.name : landingZone.name

module virtualNetwork 'vnet.bicep' = {
  name: 'VirtualNetwork-${formattedDateTime}'
  scope: az.resourceGroup(vNetResourceGroupName)
  params: {
    settings: networkSettings
    workspaceId: workspaceId
  }
}

output connectivityResourceGroupName string = (landingZone.create ? resourceGroup.name : landingZone.name)
output virtualNetworkName string = virtualNetwork.outputs.virtualNetworkName
output virtualNetworkSubnets array = virtualNetwork.outputs.virtualNetworkSubnets
