using './main.bicep'

param environment = 'dev'
param location = 'eastus2'
param workloadName = 'data'
param regionCode = 'eus2'
param instance = '001'
param subnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-hub-cp-dev-eastus2-001/subnets/SharedServicesSubnet'
param keyVaultId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-cp-dev-eus2-001'
param keyName = 'cmk-storage'
param keyVersion = ''
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.OperationalInsights/workspaces/law-cp-dev-eastus2-001'
param tags = {
  environment: 'dev'
  owner: 'platform-team'
  costCenter: 'IT-001'
  project: 'alz-poc'
}
