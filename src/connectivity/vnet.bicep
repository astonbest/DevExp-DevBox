@description('Log Analytics Workspace')
param workspaceId string

@description('Network Settings')
param settings NetworkSettings

type NetworkSettings = {
  name: string
  create: bool
  tags: object
  addressPrefixes: array
  subnets: array
}

@description('Virtual Network')
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = if (settings.create) {
  name: settings.name
  location: resourceGroup().location
  tags: settings.tags
  properties: {
    addressSpace: {
      addressPrefixes: settings.addressPrefixes
    }
    subnets: [
      for subnet in settings.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.properties.addressPrefix
        }
      }
    ]
  }
}

resource existingVNet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = if (!settings.create) {
  name: settings.name
  scope: resourceGroup()
}

@description('Network Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (settings.create) {
  name: virtualNetwork.name
  scope: virtualNetwork
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: workspaceId
  }
}
output virtualNetworkId string = (settings.create) ? virtualNetwork.id : existingVNet.id

output virtualNetworkSubnets array = [
  for (subnet, i) in settings.subnets: {
    id: (settings.create) ? virtualNetwork.properties.subnets[i].id : existingVNet.properties.subnets[i].id
    name: (settings.create) ? subnet.name : existingVNet.properties.subnets[i].name
  }
]

output virtualNetworkName string = (settings.create) ? virtualNetwork.name : existingVNet.name
