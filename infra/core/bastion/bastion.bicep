param suffix string
param location string
param subnetId string

resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-bastion-${suffix}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-07-01' = {
  name: 'bastion-${suffix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: 'ipconfig1'
      }
    ]
  }
}
