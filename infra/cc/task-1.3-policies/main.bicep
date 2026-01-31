targetScope = 'subscription'

@description('Prefix for naming resources.')
@minLength(2)
param prefix string = 'cc'

@description('Allowed Azure locations.')
param allowedLocations array = [
  'eastus'
  'eastus2'
  'westus2'
  'centralus'
]

@description('Allowed VM SKUs for sandbox/dev environments.')
param allowedVmSkus array = [
  'Standard_B1s'
  'Standard_B1ms'
  'Standard_B2s'
  'Standard_B2ms'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
]

@description('Platform Admins group object ID for Owner role.')
param platformAdminsGroupId string = ''

@description('Landing Zone Contributors group object ID for Contributor role.')
param lzContributorsGroupId string = ''

@description('Security Readers group object ID for Security Reader role.')
param securityReadersGroupId string = ''

// Built-in policy definition IDs
var allowedLocationsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'

// Built-in role definition IDs (GUID only)
var ownerRoleId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var securityReaderRoleId = '39bc4728-0917-49c7-9d2c-d95423bc2eb4'

// Deploy custom policy definitions
module policyDefinitions './policyDefinitions.bicep' = {
  name: 'deploy-policy-definitions'
  params: {
    prefix: prefix
  }
}

// Policy Assignment: Require TLS 1.2
module tlsPolicyAssignment './policyAssignments.bicep' = {
  name: 'assign-tls12-policy'
  params: {
    assignmentName: '${prefix}-require-tls12'
    policyDefinitionId: policyDefinitions.outputs.requireTls12PolicyId
    displayName: 'Require TLS 1.2 for Storage Accounts'
    assignmentDescription: 'Denies creation of storage accounts without TLS 1.2'
  }
}

// Policy Assignment: Audit Private Endpoints
module privateEndpointsPolicyAssignment './policyAssignments.bicep' = {
  name: 'assign-private-endpoints-policy'
  params: {
    assignmentName: '${prefix}-audit-private-endpoints'
    policyDefinitionId: policyDefinitions.outputs.requirePrivateEndpointsPolicyId
    displayName: 'Audit private endpoints for PaaS'
    assignmentDescription: 'Audits PaaS services without private endpoints'
  }
}

// Policy Assignment: Allowed VM SKUs
module vmSkusPolicyAssignment './policyAssignments.bicep' = {
  name: 'assign-vm-skus-policy'
  params: {
    assignmentName: '${prefix}-allowed-vm-skus'
    policyDefinitionId: policyDefinitions.outputs.allowedVmSkusPolicyId
    displayName: 'Allowed VM SKUs'
    assignmentDescription: 'Restricts VM deployments to approved SKUs'
    assignmentParameters: {
      allowedSkus: {
        value: allowedVmSkus
      }
    }
  }
}

// Policy Assignment: Allowed Locations (Built-in)
module allowedLocationsPolicyAssignment './policyAssignments.bicep' = {
  name: 'assign-allowed-locations-policy'
  params: {
    assignmentName: '${prefix}-allowed-locations'
    policyDefinitionId: allowedLocationsPolicyId
    displayName: 'Allowed locations'
    assignmentDescription: 'Restricts resource deployment to approved Azure regions'
    assignmentParameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

// Role Assignment: Platform Admins as Owner (conditional)
module platformAdminRoleAssignment './roleAssignments.bicep' = if (!empty(platformAdminsGroupId)) {
  name: 'assign-platform-admin-owner'
  params: {
    principalId: platformAdminsGroupId
    roleDefinitionId: ownerRoleId
    principalType: 'Group'
    roleDescription: 'Platform Admins - Owner role at subscription scope'
  }
}

// Role Assignment: LZ Contributors as Contributor (conditional)
module lzContributorRoleAssignment './roleAssignments.bicep' = if (!empty(lzContributorsGroupId)) {
  name: 'assign-lz-contributor'
  params: {
    principalId: lzContributorsGroupId
    roleDefinitionId: contributorRoleId
    principalType: 'Group'
    roleDescription: 'Landing Zone Contributors - Contributor role at subscription scope'
  }
}

// Role Assignment: Security Readers (conditional)
module securityReaderRoleAssignment './roleAssignments.bicep' = if (!empty(securityReadersGroupId)) {
  name: 'assign-security-reader'
  params: {
    principalId: securityReadersGroupId
    roleDefinitionId: securityReaderRoleId
    principalType: 'Group'
    roleDescription: 'Security Readers - Security Reader role at subscription scope'
  }
}

@description('Require TLS 1.2 policy definition ID.')
output requireTls12PolicyDefinitionId string = policyDefinitions.outputs.requireTls12PolicyId

@description('Audit private endpoints policy definition ID.')
output requirePrivateEndpointsPolicyDefinitionId string = policyDefinitions.outputs.requirePrivateEndpointsPolicyId

@description('Allowed VM SKUs policy definition ID.')
output allowedVmSkusPolicyDefinitionId string = policyDefinitions.outputs.allowedVmSkusPolicyId

@description('TLS 1.2 policy assignment ID.')
output tlsAssignmentId string = tlsPolicyAssignment.outputs.assignmentId

@description('Private endpoints policy assignment ID.')
output privateEndpointsAssignmentId string = privateEndpointsPolicyAssignment.outputs.assignmentId

@description('VM SKUs policy assignment ID.')
output vmSkusAssignmentId string = vmSkusPolicyAssignment.outputs.assignmentId

@description('Allowed locations policy assignment ID.')
output allowedLocationsAssignmentId string = allowedLocationsPolicyAssignment.outputs.assignmentId
