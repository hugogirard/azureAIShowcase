param location string
param vnetAddressPrefix string
param subnetPEAddressPrefix string

resource nsgPe 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-pe'
  location: location
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-ase'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-pe'
        properties: {
          addressPrefix: subnetPEAddressPrefix
          networkSecurityGroup: {
            id: nsgPe.id
          }
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output subnetPEId string = vnet.properties.subnets[0].id
