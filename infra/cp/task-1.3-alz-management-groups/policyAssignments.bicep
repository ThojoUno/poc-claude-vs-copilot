targetScope = 'managementGroup'

@description('Policy assignment name.')
param assignmentName string

@description('Policy definition ID to assign.')
param policyDefinitionId string

@description('Display name for the policy assignment.')
param displayName string

@description('Optional parameters object for the policy assignment.')
param assignmentParameters object = {}

@description('Policy enforcement mode.')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: assignmentName
  properties: {
    displayName: displayName
    policyDefinitionId: policyDefinitionId
    enforcementMode: enforcementMode
    parameters: empty(assignmentParameters) ? null : assignmentParameters
  }
}

@description('Policy assignment ID.')
output assignmentId string = policyAssignment.id
