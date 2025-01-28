@minLength(5)
param suffix string
param location string
param enableSoftDeleteVault bool
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

module acr '../registry/registry.bicep' = {
  name: 'registryAIFoundry'
  params: {
    name: 'acrfoundry${suffix}'
    location: location
    tags: tags
  }
}

var storageNameCleaned = replace('strai${suffix}', '-', '')

module storageAI '../storage/storage.bicep' = {
  name: 'storageAIFoundry'
  params: {
    name: storageNameCleaned
    location: location
    tags: tags
  }
}

var keyVaultName = 'vault-foundry-${suffix}'

module keyvault '../vault/vault.bicep' = {
  name: 'keyVaultAIFoundry'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    enableSoftDeleteVault: enableSoftDeleteVault
  }
}

output storageId string = storageAI.outputs.id
output containerRegistryId string = acr.outputs.containerRegistryId
output keyvaultId string = keyvault.outputs.id
output applicationInsightId string = appInsight.outputs.id
