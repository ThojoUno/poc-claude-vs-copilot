using './main.bicep'

param environment = 'dev'
param location = 'eastus2'
param tags = {
  environment: 'dev'
  project: 'poc-claude-vs-copilot'
  tool: 'claude-code'
}
