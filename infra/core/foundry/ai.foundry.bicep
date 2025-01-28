param location string
param suffix string
param keyVaultId string
param storageAccountId string
param applicationInsightsId string
param containerRegistryId string

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: 'aihub-dev-${suffix}'
  location: location
  kind: 'hub'
  sku: {
    // Firewall tier
    name: 'Basic'
    tier: 'Basic'
  }
  identity: {
    type: 'SystemAssigned' // This resource's identity is automatically assigned priviledge access to ACR, Storage, Key Vault, and Application Insights.
    // Since the priveleges are granted at the project/hub level have elevated access to the resources, it is recommended to isolate these resources
    // to a resource group that only contains the project/hub and relevant resources.
  }
  properties: {
    // organization
    friendlyName: 'AI Hub for development'
    description: 'DEV AI Hub'
    publicNetworkAccess: 'Disabled'
    allowPublicAccessWhenBehindVnet: false
    serverlessComputeSettings: null // This reference implementation uses a managed virtual network instead of a BYO subnet
    managedNetwork: {
      isolationMode: 'AllowOnlyApprovedOutbound'
      status: {
        sparkReady: false
        status: 'Active'
      }
    }
    v1LegacyMode: false
    workspaceHubConfig: {
      defaultWorkspaceResourceGroup: resourceGroup().id // Setting this to the same resource group as the workspace
    }
    // dependent resources
    keyVault: keyVaultId
    storageAccount: storageAccountId
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    enableDataIsolation: true
    hbiWorkspace: false
    imageBuildCompute: null
  }
}

output aiHubID string = aiHub.id
