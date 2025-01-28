targetScope = 'subscription'

@minLength(4)
@maxLength(20)
@description('Resource group name for the hub')
param hubResourceGroupName string

@minLength(4)
@maxLength(20)
@description('Resource group name for the AI Spoke (Shared AI Services)')
param spokeAIResourceGroupName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Address prefix for the virtual network that will contain the hub')
param hubVnetAddressPrefix string

@description('Address prefix for the subnet that will contain the firewall')
param subnetFirewalladdressPrefix string

@description('Address prefix for the subnet that will contain the management firewall')
param subnetManagementFirewalladdressPrefix string

@description('Address prefix for the subnet that will contain the jumpbox')
param subnetJumpboxaddressPrefix string

@description('Address prefix for the subnet that will contain the runner')
param subnetRunneraddressPrefix string

@description('Address prefix for the subnet that will contain the Bastion')
param subnetBastionPrefix string

@description('Address prefix for the virtual network that will contain the spoke')
param vnetAddressAISpokePrefix string

@description('Address prefix for the subnet that will contain the private endpoint of AI FOundry')
param subnetPEAISpokeAddressPrefix string

@description('Enable soft delete on the keyvault needed for AI Foundry')
param enableSoftDeleteVault bool

resource rgHub 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: hubResourceGroupName
  location: location
}

resource rgAISpoke 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: spokeAIResourceGroupName
  location: location
}

module hubvnet 'core/networking/hub.bicep' = {
  scope: rgHub
  name: 'hubvnet'
  params: {
    addressPrefixe: hubVnetAddressPrefix
    location: location
    subnetBastionPrefix: subnetBastionPrefix
    subnetFirewalladdressPrefix: subnetFirewalladdressPrefix
    subnetJumpboxaddressPrefix: subnetJumpboxaddressPrefix
    subnetManagementFirewalladdressPrefix: subnetManagementFirewalladdressPrefix
    subnetRunneraddressPrefix: subnetRunneraddressPrefix
  }
}

module spokeAIFoundyVnet 'core/networking/spoke.ai.bicep' = {
  scope: rgAISpoke
  name: 'spokeAIFoundyVnet'
  params: {
    location: location
    subnetPEAddressPrefix: subnetPEAISpokeAddressPrefix
    vnetAddressPrefix: vnetAddressAISpokePrefix
  }
}

var suffix = uniqueString(rgAISpoke.id)

module loganalytics 'core/logging/workspace.bicep' = {
  scope: rgAISpoke
  name: 'loganalytics'
  params: {
    name: 'log-${suffix}'
    location: location
  }
}

module foundryDependencies 'core/foundry/dependencies.bicep' = {
  scope: rgAISpoke
  name: 'foundryDependencies'
  params: {
    location: location
    suffix: suffix
    enableSoftDeleteVault: enableSoftDeleteVault
    workspaceId: loganalytics.outputs.id
  }
}

module aiFoundry 'core/foundry/ai.foundry.bicep' = {
  scope: rgAISpoke
  name: 'aiFoundry'
  params: {
    location: location
    applicationInsightsId: foundryDependencies.outputs.applicationInsightId
    containerRegistryId: foundryDependencies.outputs.containerRegistryId
    keyVaultId: foundryDependencies.outputs.keyvaultId
    storageAccountId: foundryDependencies.outputs.storageId
    suffix: suffix
  }
}
