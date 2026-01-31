using './main.bicep'

param environment = 'dev'
param location = 'eastus2'
param addressSpace = '10.0.0.0/16'
param dnsServers = []
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.OperationalInsights/workspaces/law-cp-dev-eastus2-001'
param tags = {
  environment: 'dev'
  owner: 'platform-team'
  costCenter: 'IT-001'
  project: 'alz-poc'
}
