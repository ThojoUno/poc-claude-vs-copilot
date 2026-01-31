using './main.bicep'

param environment = 'dev'
param location = 'eastus2'
param workloadName = 'ccskill'
param regionCode = 'eus2'
param instance = '001'
param keyName = 'cmk-storage'

// These are passed dynamically from the workflow after discovering prerequisites
param subnetId = ''
param keyVaultId = ''
param logAnalyticsWorkspaceId = ''
param userAssignedIdentityId = ''
param privateDnsZoneId = ''

param tags = {
  environment: 'dev'
  project: 'poc-claude-vs-copilot'
  tool: 'ccskill'
  owner: 'platform-team'
  costCenter: 'engineering'
}
