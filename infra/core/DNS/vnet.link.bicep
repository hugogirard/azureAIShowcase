param dnsZoneName string
param vnetName string
param vnetId string

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnsZoneName
}

var name = '${vnetName}-link'

resource vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZone
  name: name
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}
