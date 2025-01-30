param location string
param routeTableName string
param routeName string
param addressPrefix string
param nextHopType string
param nextHopIpAddress string

resource route 'Microsoft.Network/routeTables@2021-05-01' = {
  name: routeTableName
  location: location
  properties: {
    routes: [
      {
        name: routeName
        properties: {
          addressPrefix: addressPrefix
          nextHopType: nextHopType
          nextHopIpAddress: nextHopIpAddress
        }
      }
    ]
  }
}

output routeTableId string = route.id
