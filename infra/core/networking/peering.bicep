param vnetParentName string
param vnetRemoteName string
param vnetRemoteId string

resource vnetParent 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetParentName
}

resource vnet1Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${vnetParentName}-to-${vnetRemoteName}'
  parent: vnetParent
  properties: {
    remoteVirtualNetwork: {
      id: vnetRemoteId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}
