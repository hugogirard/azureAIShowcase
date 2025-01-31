param name string
param location string
param publicNetworkAccess bool
param tags object

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: name
  location: location
  sku: {
    name: 'Premium'
  }
  tags: tags
  properties: {
    adminUserEnabled: true
    dataEndpointEnabled: false
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSet: {
      defaultAction: publicNetworkAccess ? 'Allow' : 'Deny'
    }
    policies: {
      quarantinePolicy: {
        status: 'enabled'
      }
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
      trustPolicy: {
        status: 'disabled'
        type: 'Notary'
      }
    }
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
    zoneRedundancy: 'Disabled'
  }
}

output containerRegistryId string = containerRegistry.id
