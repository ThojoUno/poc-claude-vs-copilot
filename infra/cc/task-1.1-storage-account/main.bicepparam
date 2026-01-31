using './main.bicep'

param environment = 'dev'
param location = 'eastus2'
param workloadName = 'poc'
param regionCode = 'eus2'
param instance = '001'

// These values will be populated from prerequisites deployment outputs
param subnetId = '/subscriptions/${az.subscription().subscriptionId}/resourceGroups/rg-eastus2-claude/providers/Microsoft.Network/virtualNetworks/vnet-prereq-cc-dev-eus2/subnets/PrivateEndpointSubnet'
param keyVaultId = '/subscriptions/${az.subscription().subscriptionId}/resourceGroups/rg-eastus2-claude/providers/Microsoft.KeyVault/vaults/kv-cc-dev-eus2'
param keyName = 'cmk-storage'
param logAnalyticsWorkspaceId = '/subscriptions/${az.subscription().subscriptionId}/resourceGroups/rg-eastus2-claude/providers/Microsoft.OperationalInsights/workspaces/law-cc-dev-eus2'

param tags = {
  environment: 'dev'
  project: 'poc-claude-vs-copilot'
  tool: 'claude-code'
}
