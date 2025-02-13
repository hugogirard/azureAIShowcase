param location string
param vnetAddressPrefix string
param subnetPEAddressPrefix string

module nsgPe 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'nsgPe'
  params: {
    name: 'nsg-pe'
  }
}

// resource nsgPe 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
//   name: 'nsg-pe'
//   location: location
//   properties: {
//     securityRules: []
//   }
// }

module vnet 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: 'vnet'
  params: {
    name: 'vnet-ai-shared-srv'
    addressPrefixes: [vnetAddressPrefix]
    subnets: [
      {
        name: 'snet-pe'
        networkSecurityGroupResourceId: nsgPe.outputs.resourceId
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Disabled'
      }
    ]
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.outputs.resourceId
output subnetPEId string = vnet.outputs.subnetResourceIds[0]
