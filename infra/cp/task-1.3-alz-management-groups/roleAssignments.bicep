targetScope = 'managementGroup'

@description('Principal object ID for the role assignment.')
param principalId string

@description('Role definition ID to assign.')
param roleDefinitionId string

@description('Scope ID used for deterministic role assignment naming.')
param scopeId string

@description('Principal type for the role assignment.')
@allowed([
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'Group'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(scopeId, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

@description('Role assignment ID.')
output assignmentId string = roleAssignment.id
