targetScope = 'subscription'

@description('Name of the policy assignment.')
param assignmentName string

@description('Policy definition ID to assign.')
param policyDefinitionId string

@description('Display name for the assignment.')
param displayName string

@description('Description for the assignment.')
param assignmentDescription string = ''

@description('Parameters for the policy assignment.')
param assignmentParameters object = {}

@description('Enforcement mode for the policy.')
@allowed(['Default', 'DoNotEnforce'])
param enforcementMode string = 'Default'

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: assignmentName
  properties: {
    displayName: displayName
    description: assignmentDescription
    policyDefinitionId: policyDefinitionId
    parameters: assignmentParameters
    enforcementMode: enforcementMode
  }
}

@description('Policy assignment ID.')
output assignmentId string = policyAssignment.id

@description('Policy assignment name.')
output assignmentNameOut string = policyAssignment.name
