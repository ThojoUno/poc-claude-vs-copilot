using './main.bicep'

param environment = 'dev'
param location = 'eastus2'
param addressSpace = '10.0.0.0/16'
param dnsServers = []

// Passed dynamically from the workflow after discovering prerequisites
param logAnalyticsWorkspaceId = ''

param tags = {
  environment: 'dev'
  project: 'poc-claude-vs-copilot'
  tool: 'claude-code'
}
