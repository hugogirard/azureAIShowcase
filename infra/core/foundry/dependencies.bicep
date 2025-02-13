@minLength(5)
param suffix string
param location string
param enableSoftDeleteVault bool
param publicNetworkAccess bool
param workspaceId string

var tags = {
  Purpose: 'AIFoundryDependencies'
}

module appInsight '../logging/appinsight.bicep' = {
  name: 'appinsight-foundry'
  params: {
    name: 'api-foundry-${suffix}'
    location: location
    tags: tags
    workspaceId: workspaceId
  }
}

module acr 'br/public:avm/res/container-registry/registry:0.8.5' = {
  name: 'registryAIFoundry'
  params: {
    name: 'acrfoundry${suffix}'
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
    location: location
    tags: tags
  }
}

var storageNameCleaned = replace('strai${suffix}', '-', '')

module storageAI 'br/public:avm/res/storage/storage-account:0.17.3' = {
  name: 'storageAIFoundry'
  params: {
    name: storageNameCleaned
    location: location
    tags: tags
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
  }
}

var keyVaultName = 'vault-aif-${suffix}'

module keyvault 'br/public:avm/res/key-vault/vault:0.11.3' = {
  name: 'keyVaultAIFoundry'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    enableSoftDelete: enableSoftDeleteVault
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
  }
}

output storageId string = storageAI.outputs.resourceId
output storageName string = storageAI.outputs.name

output containerRegistryId string = acr.outputs.resourceId
output keyvaultId string = keyvault.outputs.resourceId
output applicationInsightId string = appInsight.outputs.id
