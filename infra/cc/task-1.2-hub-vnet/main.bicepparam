using './main.bicep'

param environment = 'dev'
param location = 'eastus2'
param addressSpace = '10.0.0.0/16'
param dnsServers = []

// Populated from prerequisites deployment outputs
param logAnalyticsWorkspaceId = '/subscriptions/${az.subscription().subscriptionId}/resourceGroups/rg-eastus2-claude/providers/Microsoft.OperationalInsights/workspaces/law-cc-dev-eus2'

param tags = {
  environment: 'dev'
  project: 'poc-claude-vs-copilot'
  tool: 'claude-code'
}
