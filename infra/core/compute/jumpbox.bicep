@secure()
param adminUsername string
@secure()
param adminPassword string

param subnetId string

param location string

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: 'jumpnic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource jumpbox 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: 'jumpbox'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B4ms'
    }
    osProfile: {
      computerName: 'jumpbox'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'jumpbox_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output jumpboxName string = jumpbox.name
output privateJumpboxIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
