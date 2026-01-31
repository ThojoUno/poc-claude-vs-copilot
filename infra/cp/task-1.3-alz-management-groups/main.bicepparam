using './main.bicep'

param prefix = 'contoso-cp'
param allowedLocations = [
  'eastus'
  'eastus2'
  'westus2'
]
param allowedVmSkus = [
  'Standard_D2s_v5'
  'Standard_D4s_v5'
]
param platformAdminsGroupId = '00000000-0000-0000-0000-000000000000'
param lzContributorsGroupId = '00000000-0000-0000-0000-000000000000'
param securityReadersGroupId = '00000000-0000-0000-0000-000000000000'
