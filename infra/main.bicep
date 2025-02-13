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

@description('Deploy Azure Firewall - Basic')
param deployAzureFirewall bool

@description('Deploy hub network')
param deployHub bool

@description('Deploy AI Foundry in private mode')
param privateHubFoundry bool

@secure()
@description('The admin username of the jumpbox and runner')
param adminUsername string

@secure()
@description('The admin password of the jumpbox and runner')
param adminPassword string

var privateFileDNSZone = 'privatelink.file.${environment().suffixes.storage}'
var privateBlobDNSZone = 'privatelink.blob.${environment().suffixes.storage}'
var privateVaultDNSZone = 'privatelink.vaultcore.azure.net'
var privateRegistryDNSZone = 'privatelink.azurecr.io'
var privateMLWorkspaceDNSZone = 'privatelink.api.azureml.ms'
var privateNotebookDNSZone = 'privatelink.notebooks.azure.net'

module rgHub 'br:mcr.microsoft.com/bicep/avm/res/resources/resource-group:0.4.1' = {
  name: 'rgHub'
  params: {
    name: hubResourceGroupName
    location: location
  }
}

module rgAISpoke 'br:mcr.microsoft.com/bicep/avm/res/resources/resource-group:0.4.1' = {
  name: 'rgAISpoke'
  params: {
    name: spokeAIResourceGroupName
    location: location
  }
}

module hubvnet 'core/networking/hub.bicep' = if (deployHub) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
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

module firewall 'core/firewall/firewall.bicep' = if (deployAzureFirewall && deployHub) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'firewall'
  params: {
    location: location
    vnetId: hubvnet.outputs.vnetId
    // managementSubnetId: hubvnet.outputs.managementFirewallSubnetId
    // subnetId: hubvnet.outputs.firewallSubnetId
    suffix: suffix
  }
}

module routeTableFirewallSpokeAI 'br/public:avm/res/network/route-table:0.4.0' = if (deployAzureFirewall && deployHub) {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'routeTableFirewallSpokeAI'
  params: {
    name: 'rt-firewall'
    location: location
    routes: [
      {
        name: 'outbound-to-firewall'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: firewall.outputs.privateIP
        }
      }
    ]
  }
}

// module routeTableFirewallSpokeAI 'core/networking/route.table.bicep' = if (deployAzureFirewall && deployHub) {
//   scope: resourceGroup(spokeAIResourceGroupName)
//   dependsOn: [rgAISpoke]
//   name: 'routeTableFirewall'
//   params: {
//     location: location
//     addressPrefix: '0.0.0.0/0'
//     nextHopIpAddress: 'VirtualAppliance'
//     nextHopType: firewall.outputs.privateIP
//     routeName: 'outbound-to-firewall'
//     routeTableName: 'rt-firewall'
//   }
// }

module privateFileDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = if (deployHub && privateHubFoundry) {
  name: 'privateFileDnsZone'
  params: {
    name: privateFileDNSZone
  }
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
}

// module privateFileDnsZone 'core/DNS/private.dns.zone.bicep' = if (deployHub && privateHubFoundry) {
//   name: 'privateFileDnsZone'
//   scope: resourceGroup(hubResourceGroupName)
//   dependsOn: [rgHub]
//   params: {
//     name: privateFileDNSZone
//   }
// }

module vnetLinkFileDNSHub 'core/DNS/vnet.link.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'vnetLinkFileDNSHub'
  params: {
    dnsZoneName: privateFileDnsZone.outputs.name
    vnetId: hubvnet.outputs.vnetId
    vnetName: hubvnet.outputs.vnetName
  }
}

module vnetLinkFileDNSSpoke 'core/DNS/vnet.link.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'vnetLinkFileDNSSpoke'
  params: {
    dnsZoneName: privateFileDnsZone.outputs.name
    vnetId: spokeAIFoundyVnet.outputs.vnetId
    vnetName: spokeAIFoundyVnet.outputs.vnetName
  }
}

module privateRegistryDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = if (deployHub && privateHubFoundry) {
  name: 'privateRegistryDnsZone'
  params: {
    name: privateRegistryDNSZone
  }
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
}

// module privateRegistryDnsZone 'core/DNS/private.dns.zone.bicep' = if (deployHub && privateHubFoundry) {
//   scope: resourceGroup(hubResourceGroupName)
//   dependsOn: [rgHub]
//   name: 'privateRegistryDnsZone'
//   params: {
//     name: privateRegistryDNSZone
//   }
// }

module vnetLinkACRDNSHub 'core/DNS/vnet.link.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'vnetLinkACRDNSHub'
  params: {
    dnsZoneName: privateRegistryDnsZone.outputs.name
    vnetId: hubvnet.outputs.vnetId
    vnetName: hubvnet.outputs.vnetName
  }
}

module vnetLinkACRDNSSpoke 'core/DNS/vnet.link.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'vnetLinkACRDNSSpoke'
  params: {
    dnsZoneName: privateRegistryDnsZone.outputs.name
    vnetId: spokeAIFoundyVnet.outputs.vnetId
    vnetName: spokeAIFoundyVnet.outputs.vnetName
  }
}

module privateBlobDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = if (deployHub && privateHubFoundry) {
  name: 'privateBlobDnsZone'
  params: {
    name: privateBlobDNSZone
  }
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
}

// module privateBlobDnsZone 'core/DNS/private.dns.zone.bicep' = if (deployHub && privateHubFoundry) {
//   name: 'privateBlobDnsZone'
//   scope: resourceGroup(hubResourceGroupName)
//   dependsOn: [rgHub]
//   params: {
//     name: privateBlobDNSZone
//   }
// }

module vnetLinkBlobDNSHub 'core/DNS/vnet.link.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'vnetLinkBlobDNSHub'
  params: {
    dnsZoneName: privateBlobDnsZone.outputs.name
    vnetId: hubvnet.outputs.vnetId
    vnetName: hubvnet.outputs.vnetName
  }
}

module vnetLinkBlobDNSSpoke 'core/DNS/vnet.link.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'vnetLinkBlobDNSSpoke'
  params: {
    dnsZoneName: privateBlobDnsZone.outputs.name
    vnetId: spokeAIFoundyVnet.outputs.vnetId
    vnetName: spokeAIFoundyVnet.outputs.vnetName
  }
}

module privateZoneVault 'br/public:avm/res/network/private-dns-zone:0.7.0' = if (deployHub && privateHubFoundry) {
  name: 'privateZoneVault'
  params: {
    name: privateVaultDNSZone
  }
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
}

// module privateZoneVault 'core/DNS/private.dns.zone.bicep' = if (deployHub && privateHubFoundry) {
//   scope: resourceGroup(hubResourceGroupName)
//   dependsOn: [rgHub]
//   name: 'privateZoneVault'
//   params: {
//     name: privateVaultDNSZone
//   }
// }

module vnetLinkVaultDNSHub 'core/DNS/vnet.link.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'vnetLinkVaultDNSHub'
  params: {
    dnsZoneName: privateZoneVault.outputs.name
    vnetId: hubvnet.outputs.vnetId
    vnetName: hubvnet.outputs.vnetName
  }
}

module vnetLinkVaultDNSSpoke 'core/DNS/vnet.link.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'vnetLinkVaultDNSSpoke'
  params: {
    dnsZoneName: privateZoneVault.outputs.name
    vnetId: spokeAIFoundyVnet.outputs.vnetId
    vnetName: spokeAIFoundyVnet.outputs.vnetName
  }
}

module bastion 'br/public:avm/res/network/bastion-host:0.6.0' = if (deployHub) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'bastion'
  params: {
    name: 'bastion-${suffix}'
    virtualNetworkResourceId: hubvnet.outputs.vnetId
  }
}

// module bastion 'core/bastion/bastion.bicep' = if (deployHub) {
//   scope: resourceGroup(hubResourceGroupName)
//   dependsOn: [rgHub]
//   name: 'bastion'
//   params: {
//     location: location
//     subnetId: hubvnet.outputs.bastionSubnetId
//     suffix: suffix
//   }
// }

module spokeAIFoundyVnet 'core/networking/spoke.ai.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'spokeAIFoundyVnet'
  params: {
    location: location
    subnetPEAddressPrefix: subnetPEAISpokeAddressPrefix
    vnetAddressPrefix: vnetAddressAISpokePrefix
  }
}

// Peering VNETS

module hubToAISpoke 'core/networking/peering.bicep' = if (deployHub) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'hubToAISpoke'
  params: {
    vnetParentName: hubvnet.outputs.vnetName
    vnetRemoteId: spokeAIFoundyVnet.outputs.vnetId
    vnetRemoteName: spokeAIFoundyVnet.outputs.vnetName
  }
}

module AISpokeToHub 'core/networking/peering.bicep' = if (deployHub) {
  scope: resourceGroup(spokeAIResourceGroupName)
  dependsOn: [rgAISpoke]
  name: 'AISpokeToHub'
  params: {
    vnetParentName: spokeAIFoundyVnet.outputs.vnetName
    vnetRemoteId: hubvnet.outputs.vnetId
    vnetRemoteName: hubvnet.outputs.vnetName
  }
}

var suffix = uniqueString(rgAISpoke.outputs.resourceId)

module loganalytics 'core/logging/workspace.bicep' = {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'loganalytics'
  params: {
    name: 'log-${suffix}'
    location: location
  }
}

module foundryDependencies 'core/foundry/dependencies.bicep' = {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'foundryDependencies'
  params: {
    location: location
    suffix: suffix
    enableSoftDeleteVault: enableSoftDeleteVault
    workspaceId: loganalytics.outputs.id
    publicNetworkAccess: !privateHubFoundry
  }
}

// module privateEndpointStorageFoundry 'br/public:avm/res/network/private-endpoint:0.10.1' = {
//   scope: resourceGroup(spokeAIResourceGroupName)
//   name: 'privateEndpointStorageFoundry'
//   params: {
//     name: 'pe-blob-foundry'
//     subnetResourceId: spokeAIFoundyVnet.outputs.subnetPEId

//     privateDnsZoneGroup: {      
//       privateDnsZoneGroupConfigs: [
//         {
//           privateDnsZoneResourceId: foundryDependencies.outputs.storageId
//         }
//       ]
//     }
//   }
// }

module privateEndpointStorageFoundry 'core/networking/private.endpoint.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'privateEndpointStorageFoundry'
  params: {
    name: 'pe-blob-foundry'
    location: location
    groupsIds: ['blob']
    serviceId: foundryDependencies.outputs.storageId
    subnetId: spokeAIFoundyVnet.outputs.subnetPEId
    dnsZoneId: privateBlobDnsZone.outputs.resourceId
  }
}

module privateEndpointFileFoundry 'core/networking/private.endpoint.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'privateEndpointFileFoundry'
  params: {
    name: 'pe-file-foundry'
    location: location
    groupsIds: ['file']
    serviceId: foundryDependencies.outputs.storageId
    subnetId: spokeAIFoundyVnet.outputs.subnetPEId
    dnsZoneId: privateFileDnsZone.outputs.resourceId
  }
}

module privateEndpointVaultFoundry 'core/networking/private.endpoint.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'privateEndpointVaultFoundry'
  params: {
    name: 'pe-vault-foundry'
    location: location
    groupsIds: ['vault']
    serviceId: foundryDependencies.outputs.keyvaultId
    subnetId: spokeAIFoundyVnet.outputs.subnetPEId
    dnsZoneId: privateZoneVault.outputs.resourceId
  }
}

module privateEndpointRegistryFoundry 'core/networking/private.endpoint.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'privateEndpointRegistryFoundry'
  params: {
    name: 'pe-acr-foundry'
    location: location
    dnsZoneId: privateRegistryDnsZone.outputs.resourceId
    groupsIds: ['registry']
    serviceId: foundryDependencies.outputs.containerRegistryId
    subnetId: spokeAIFoundyVnet.outputs.subnetPEId
  }
}

module aiFoundry 'core/foundry/ai.foundry.bicep' = {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'aiFoundry'
  params: {
    location: location
    applicationInsightsId: foundryDependencies.outputs.applicationInsightId
    containerRegistryId: foundryDependencies.outputs.containerRegistryId
    keyVaultId: foundryDependencies.outputs.keyvaultId
    storageAccountId: foundryDependencies.outputs.storageId
    publicNetworkAccess: !privateHubFoundry
    suffix: suffix
  }
}

module mlworkspaceDNS 'core/DNS/private.dns.zone.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'mlworkspaceDNS'
  params: {
    name: privateMLWorkspaceDNSZone
  }
}

module mlnotebookDNS 'core/DNS/private.dns.zone.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'mlnotebookDNS'
  params: {
    name: privateNotebookDNSZone
  }
}

module peworkspacevnet 'core/networking/private.endpoint.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'peworkspacevnet'
  params: {
    name: 'pe-workspace-foundry'
    location: location
    dnsZoneId: mlworkspaceDNS.outputs.id
    groupsIds: ['amlworkspace']
    serviceId: aiFoundry.outputs.aiHubID
    subnetId: spokeAIFoundyVnet.outputs.subnetPEId
  }
}

module penotebookvnet 'core/networking/private.endpoint.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(spokeAIResourceGroupName)
  name: 'penotebookvnet'
  params: {
    name: 'pe-notebook-foundry'
    location: location
    dnsZoneId: mlnotebookDNS.outputs.id
    groupsIds: ['amlworkspace']
    serviceId: aiFoundry.outputs.aiHubID
    subnetId: spokeAIFoundyVnet.outputs.subnetPEId
  }
}

module workspacelinkHub 'core/DNS/vnet.link.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'workspacelinkHub'
  params: {
    dnsZoneName: mlworkspaceDNS.outputs.name
    vnetId: hubvnet.outputs.vnetId
    vnetName: hubvnet.outputs.vnetName
  }
}

module workspacelinkSpoke 'core/DNS/vnet.link.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'workspacelinkSpoke'
  params: {
    dnsZoneName: mlworkspaceDNS.outputs.name
    vnetId: spokeAIFoundyVnet.outputs.vnetId
    vnetName: spokeAIFoundyVnet.outputs.vnetName
  }
}

module notebooklinkHub 'core/DNS/vnet.link.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'notebooklinkHub'
  params: {
    dnsZoneName: mlnotebookDNS.outputs.name
    vnetId: hubvnet.outputs.vnetId
    vnetName: hubvnet.outputs.vnetName
  }
}

module notebooklinkSpoke 'core/DNS/vnet.link.bicep' = if (privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'notebooklinkSpoke'
  params: {
    dnsZoneName: mlnotebookDNS.outputs.name
    vnetId: spokeAIFoundyVnet.outputs.vnetId
    vnetName: spokeAIFoundyVnet.outputs.vnetName
  }
}

module jumpbox 'core/compute/jumpbox.bicep' = if (deployHub) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'jumpbox'
  params: {
    location: location
    adminPassword: adminPassword
    adminUsername: adminUsername
    subnetId: hubvnet.outputs.jumpboxSubnetId
  }
}

module aRecordBlobFoundry 'core/DNS/a.record.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'aRecordBlobFoundry'
  params: {
    name: jumpbox.outputs.jumpboxName
    dnsName: privateBlobDnsZone.outputs.name
    privateEndpointIP: jumpbox.outputs.privateJumpboxIp
  }
}

module aRecordFileFoundry 'core/DNS/a.record.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'aRecordFileFoundry'
  params: {
    name: jumpbox.outputs.jumpboxName
    dnsName: privateFileDnsZone.outputs.name
    privateEndpointIP: jumpbox.outputs.privateJumpboxIp
  }
}

module aRecordVaultFoundry 'core/DNS/a.record.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'aRecordVaultFoundry'
  params: {
    name: jumpbox.outputs.jumpboxName
    dnsName: privateZoneVault.outputs.name
    privateEndpointIP: jumpbox.outputs.privateJumpboxIp
  }
}

module aRecordWorkspace 'core/DNS/a.record.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'aRecordWorkspace'
  params: {
    name: jumpbox.outputs.jumpboxName
    dnsName: mlworkspaceDNS.outputs.name
    privateEndpointIP: jumpbox.outputs.privateJumpboxIp
  }
}

module aRecordNotebook 'core/DNS/a.record.bicep' = if (deployHub && privateHubFoundry) {
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [rgHub]
  name: 'aRecordNotebook'
  params: {
    name: jumpbox.outputs.jumpboxName
    dnsName: mlnotebookDNS.outputs.name
    privateEndpointIP: jumpbox.outputs.privateJumpboxIp
  }
}
