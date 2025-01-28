param location string
param suffix string
param keyVaultId string
param storageAccountId string
param applicationInsightsId string
param containerRegistryId string

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' = {
  name: 'aihub-dev-${suffix}'
  location: location
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // organization
    friendlyName: 'AI Hub for development'
    description: 'DEV AI Hub'
    publicNetworkAccess: 'Disabled'
    managedNetwork: {
      isolationMode: 'AllowOnlyApprovedOutbound'
    }
    // dependent resources
    keyVault: keyVaultId
    storageAccount: storageAccountId
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
  }
  kind: 'hub'
}

output aiHubID string = aiHub.id
