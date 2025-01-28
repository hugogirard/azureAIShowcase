param name string
param location string
param subnetId string
param groupsIds array
param serviceId string
param dnsZoneId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = {
  name: name
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          groupIds: groupsIds
          privateLinkServiceId: serviceId
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'pe-config'
        properties: {
          privateDnsZoneId: dnsZoneId
        }
      }
    ]
  }
}

output privateEndpointIP string = dnsZoneGroup.properties.privateDnsZoneConfigs[0].properties.recordSets[0].ipAddresses[0]
