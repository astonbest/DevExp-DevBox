@description('Workload name')
param workloadName string

@description('Connectivity Resource Group Name')
param connectivityResourceGroupName string

@description('Subnets')
param contosoProjectsInfo array

@description('Address Prefixes')
var addressPrefixes = [
  '10.0.0.0/16'
]

@description('Tags')
var tags = {
  workload: workloadName
  landingZone: 'connectivity'
  resourceType: 'virtualNetwork'
  ProductTeam: 'Platform Engineering'
  Environment: 'Production'
  Department: 'IT'
  offering: 'DevBox-as-a-Service'
}

@description('DDoS Protection Plan')
module ddosProtectionPlan 'DDoSPlan/DDoSPlanResource.bicep' = {
  name: 'ddosProtectionPlan'
  scope: resourceGroup(connectivityResourceGroupName)
  params: {
    name: workloadName
  }
}

@description('Virtual Network Resource')
module virtualNetwork 'virtualNetwork/virtualNetworkResource.bicep' = {
  name: 'virtualNetwork'
  scope: resourceGroup(connectivityResourceGroupName)
  params: {
    name: workloadName
    location: resourceGroup().location
    tags: tags
    addressPrefixes: addressPrefixes
    enableDdosProtection: true
    ddosProtectionPlanId: ddosProtectionPlan.outputs.ddosProtectionPlanId
    subnets: contosoProjectsInfo
  }
}

@description('Network Connection Resource')
module networkConnection 'networkConnection/networkConnectionResource.bicep' = [
  for (netConnection, i) in contosoProjectsInfo: {
    name: 'netCon-${netConnection.name}'
    scope: resourceGroup(connectivityResourceGroupName)
    params: {
      virtualNetworkName: virtualNetwork.outputs.virtualNetworkName
      subnetName: virtualNetwork.outputs.virtualNetworkSubnets[i].name
      virtualNetworkResourceGroupName: connectivityResourceGroupName
      domainJoinType: netConnection.networkConnection.domainJoinType
    }
  }
]

@description('Network Connections')
output networkConnections array = [
  for (netConnection, i) in contosoProjectsInfo: {
    name: networkConnection[i].outputs.networkConnectionName
    id: networkConnection[i].outputs.networkConnectionId
  }
]
