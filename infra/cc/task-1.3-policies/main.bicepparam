using './main.bicep'

param prefix = 'cc'

param allowedLocations = [
  'eastus'
  'eastus2'
  'westus2'
  'centralus'
]

param allowedVmSkus = [
  'Standard_B1s'
  'Standard_B1ms'
  'Standard_B2s'
  'Standard_B2ms'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
]

// Optional: Provide group object IDs for RBAC assignments
// These can be left empty if not deploying role assignments
param platformAdminsGroupId = ''
param lzContributorsGroupId = ''
param securityReadersGroupId = ''
