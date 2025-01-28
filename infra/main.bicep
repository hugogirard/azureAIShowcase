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

// @secure()
// @description('The admin username of the jumpbox and runner')
// param adminUsername string

// @secure()
// @description('The admin password of the jumpbox and runner')
// param adminPassword string

var privateFileDNSZone = 'privatelink.file.${environment().suffixes.storage}'
var privateBlobDNSZone = 'privatelink.blob.${environment().suffixes.storage}'

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

module privateFileDnsZone 'core/DNS/private.dns.zone.bicep' = {
  name: 'privateFileDnsZone'
  scope: rgHub
  params: {
    name: privateFileDNSZone
  }
}

module vnetLinkFileDNS 'core/DNS/vnet.link.bicep' = {
  scope: rgHub
  name: 'vnetLinkFileDNS'
  params: {
    dnsZoneName: privateFileDnsZone.outputs.name
    vnetId: hubvnet.outputs.vnetId
    vnetName: hubvnet.outputs.vnetName
  }
}

module privateBlobDnsZone 'core/DNS/private.dns.zone.bicep' = {
  name: 'privateBlobDnsZone'
  scope: rgHub
  params: {
    name: privateBlobDNSZone
  }
}

module vnetLinkBlobDNS 'core/DNS/vnet.link.bicep' = {
  scope: rgHub
  name: 'vnetLinkBlobDNS'
  params: {
    dnsZoneName: privateBlobDnsZone.outputs.name
    vnetId: hubvnet.outputs.vnetId
    vnetName: hubvnet.outputs.vnetName
  }
}

module bastion 'core/bastion/bastion.bicep' = {
  scope: rgHub
  name: 'bastion'
  params: {
    location: location
    subnetId: hubvnet.outputs.bastionSubnetId
    suffix: suffix
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

module privateEndpointStorageFoundry 'core/networking/private.endpoint.bicep' = {
  scope: rgAISpoke
  name: 'privateEndpointStorageFoundry'
  params: {
    name: 'pe-blob-foundry'
    location: location
    groupsIds: ['blob']
    serviceId: foundryDependencies.outputs.storageId
    subnetId: spokeAIFoundyVnet.outputs.subnetPEId
    dnsZoneId: privateBlobDnsZone.outputs.id
  }
}

module privateEndpointFileFoundry 'core/networking/private.endpoint.bicep' = {
  scope: rgAISpoke
  name: 'privateEndpointFileFoundry'
  params: {
    name: 'pe-file'
    location: location
    groupsIds: ['file']
    serviceId: foundryDependencies.outputs.storageId
    subnetId: spokeAIFoundyVnet.outputs.subnetPEId
    dnsZoneId: privateFileDnsZone.outputs.id
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
