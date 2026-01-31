targetScope = 'subscription'

@description('Principal ID (object ID) of the user, group, or service principal.')
param principalId string

@description('Role definition ID (GUID only, not full resource ID).')
param roleDefinitionId string

@description('Type of principal.')
@allowed(['User', 'Group', 'ServicePrincipal'])
param principalType string = 'Group'

@description('Description for the role assignment.')
param roleDescription string = ''

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
    description: roleDescription
  }
}

@description('Role assignment ID.')
output assignmentId string = roleAssignment.id

@description('Role assignment name.')
output assignmentNameOut string = roleAssignment.name
