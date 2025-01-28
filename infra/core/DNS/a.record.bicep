param privateEndpointIP string
param dnsName string
param name string

resource dns 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: dnsName
}

resource aRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: dns
  name: name
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: privateEndpointIP
      }
    ]
  }
}
