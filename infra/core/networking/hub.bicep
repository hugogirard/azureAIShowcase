param location string
param addressPrefixe string
param subnetFirewalladdressPrefix string
param subnetManagementFirewalladdressPrefix string
param subnetJumpboxaddressPrefix string
param subnetRunneraddressPrefix string
param subnetBastionPrefix string

module nsgJumpbox 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'nsgJumpbox'
  params: {
    name: 'nsgJumpbox'
  }
}

module nsgRunner 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'nsgRunner'
  params: {
    name: 'nsgRunner'
  }
}

module nsgBastion 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'nsgBastion'
  params: {
    name: 'nsg-bastion'
    securityRules: [
      {
        name: 'AllowHttpsInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshRdpOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudCommunicationOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: 'vnet-hub'
  params: {
    name: 'vnet-hub'
    addressPrefixes: [
      addressPrefixe
    ]
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: subnetFirewalladdressPrefix
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: subnetManagementFirewalladdressPrefix
      }
      {
        name: 'snet-jumpbox'
        addressPrefix: subnetJumpboxaddressPrefix
        networkSecurityGroupResourceId: nsgJumpbox.outputs.resourceId
      }
      {
        name: 'snet-runner'
        addressPrefix: subnetRunneraddressPrefix
        networkSecurityGroupResourceId: nsgRunner.outputs.resourceId
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: subnetBastionPrefix
        networkSecurityGroupResourceId: nsgBastion.outputs.resourceId
      }
    ]
  }
}

output vnetName string = vnet.name
output firewallSubnetId string = vnet.outputs.subnetResourceIds[0].id
output managementFirewallSubnetId string = vnet.outputs.subnetResourceIds[1].id
output jumpboxSubnetId string = vnet.outputs.subnetResourceIds[2].id
output runnerSubnetId string = vnet.outputs.subnetResourceIds[3].id
output bastionSubnetId string = vnet.outputs.subnetResourceIds[4].id
output vnetId string = vnet.outputs.resourceId
