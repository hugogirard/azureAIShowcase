param name string

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
}

output name string = dnsZone.name
output id string = dnsZone.id
