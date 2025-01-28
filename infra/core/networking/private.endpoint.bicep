param name string
param location string
param subnetId string
param groupsIds array
param serviceId string

resource appDeployStoragePrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = {
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
