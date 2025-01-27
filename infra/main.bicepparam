using 'main.bicep'

param hubResourceGroupName = 'rg-hub-ai'

param hubVnetAddressPrefix = '10.0.0.0/16'

param location = 'canadacentral'

param subnetBastionPrefix = '10.0.5.0/26'

param subnetFirewalladdressPrefix = '10.0.1.0/26'

param subnetManagementFirewalladdressPrefix = '10.0.2.0/24'

param subnetJumpboxaddressPrefix = '10.0.3.0/28'

param subnetRunneraddressPrefix = '10.0.4.0/28'

param spokeAIResourceGroupName = 'rg-ai-shared-srv'

param vnetAddressAISpokePrefix = '10.1.0.0/16'

param subnetPEAISpokeAddressPrefix = '10.1.1.0/24'
