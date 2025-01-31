## Parameters

The following parameters are required to deploy the Bicep template. Each parameter has a specific purpose and constraints.

### `hubResourceGroupName`
- **Description**: Resource group name for the hub.
- **Type**: `string`
- **Constraints**: Minimum length of 4 characters, maximum length of 20 characters.

### `spokeAIResourceGroupName`
- **Description**: Resource group name for the AI Spoke (Shared AI Services).
- **Type**: `string`
- **Constraints**: Minimum length of 4 characters, maximum length of 20 characters.

### `location`
- **Description**: Primary location for all resources.
- **Type**: `string`
- **Constraints**: Minimum length of 1 character.

### `hubVnetAddressPrefix`
- **Description**: Address prefix for the virtual network that will contain the hub.
- **Type**: `string`

### `subnetFirewalladdressPrefix`
- **Description**: Address prefix for the subnet that will contain the firewall.
- **Type**: `string`

### `subnetManagementFirewalladdressPrefix`
- **Description**: Address prefix for the subnet that will contain the management firewall.
- **Type**: `string`

### `subnetJumpboxaddressPrefix`
- **Description**: Address prefix for the subnet that will contain the jumpbox.
- **Type**: `string`

### `subnetRunneraddressPrefix`
- **Description**: Address prefix for the subnet that will contain the runner.
- **Type**: `string`

### `subnetBastionPrefix`
- **Description**: Address prefix for the subnet that will contain the Bastion.
- **Type**: `string`

### `vnetAddressAISpokePrefix`
- **Description**: Address prefix for the virtual network that will contain the spoke.
- **Type**: `string`

### `subnetPEAISpokeAddressPrefix`
- **Description**: Address prefix for the subnet that will contain the private endpoint of AI Foundry.
- **Type**: `string`

### `enableSoftDeleteVault`
- **Description**: Enable soft delete on the keyvault needed for AI Foundry.
- **Type**: `bool`

### `deployAzureFirewall`
- **Description**: Deploy Azure Firewall - Basic.
- **Type**: `bool`

### `deployHub`
- **Description**: Deploy hub network.
- **Type**: `bool`

### `privateHubFoundry`
- **Description**: Deploy AI Foundry in private mode.
- **Type**: `bool`

### `adminUsername`
- **Description**: The admin username of the jumpbox and runner.
- **Type**: `secureString`

### `adminPassword`
- **Description**: The admin password of the jumpbox and runner.
- **Type**: `secureString`