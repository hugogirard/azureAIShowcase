param suffix string
param location string
param vnetId string
// param subnetId string
// param managementSubnetId string

module pip 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  name: 'pip'
  params: {
    name: 'pip-fw-${suffix}'
    location: location
    publicIPAllocationMethod: 'Static'
  }
}

module pipmgt 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  name: 'pipmgt'
  params: {
    name: 'pip-fw-mgt-${suffix}'
    location: location
    publicIPAllocationMethod: 'Static'
  }
}

module fwPolicy 'br/public:avm/res/network/firewall-policy:0.2.0' = {
  name: 'fwPolicy'
  params: {
    name: 'fw-policy-${suffix}'
    location: location
    tier: 'Basic'
  }
}

module fw 'br/public:avm/res/network/azure-firewall:0.5.2' = {
  name: 'fw'
  params: {
    name: 'fw-${suffix}'
    location: location
    publicIPResourceID: pip.outputs.resourceId
    virtualNetworkResourceId: vnetId
    azureSkuTier: 'Basic'
    managementIPResourceID: pipmgt.outputs.resourceId
    firewallPolicyId: fwPolicy.outputs.resourceId
  }
}

// resource fw 'Microsoft.Network/azureFirewalls@2024-05-01' = {
//   name: 'fw-${suffix}'
//   location: location
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'fw-ipconfig-${suffix}'
//         properties: {
//           publicIPAddress: {
//             id: pip.id
//           }
//           subnet: {
//             id: subnetId
//           }
//         }
//       }
//     ]
//     managementIpConfiguration: {
//       name: 'fw-mgmt-ipconfig-${suffix}'
//       properties: {
//         subnet: {
//           id: managementSubnetId
//         }
//         publicIPAddress: {
//           id: pipmgt.id
//         }
//       }
//     }
//     sku: {
//       tier: 'Basic'
//     }
//     firewallPolicy: {
//       id: fwPolicy.id
//     }
//   }
// }

output privateIP string = fw.outputs.privateIp
