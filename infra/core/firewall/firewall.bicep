param suffix string
param location string
param subnetId string
param managementSubnetId string

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-fw-${suffix}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource pipmgt 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-fw-mgt-${suffix}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource fwPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: 'fw-policy-${suffix}'
  location: location
  properties: {
    sku: {
      tier: 'Basic'
    }
  }
}

resource fw 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: 'fw-${suffix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'fw-ipconfig-${suffix}'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    managementIpConfiguration: {
      name: 'fw-mgmt-ipconfig-${suffix}'
      properties: {
        subnet: {
          id: managementSubnetId
        }
        publicIPAddress: {
          id: pipmgt.id
        }
      }
    }
    sku: {
      tier: 'Basic'
    }
    firewallPolicy: {
      id: fwPolicy.id
    }
  }
}

output privateIP string = fw.properties.ipConfigurations[0].properties.privateIPAddress
