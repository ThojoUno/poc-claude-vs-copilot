targetScope = 'tenant'

@description('Prefix for management group naming (e.g., contoso-cp).')
param prefix string

@description('Allowed locations for the built-in policy assignment.')
param allowedLocations array

@description('Allowed VM SKUs for the Sandbox policy assignment.')
param allowedVmSkus array

@description('Platform Admins group object ID.')
param platformAdminsGroupId string

@description('Landing Zone Contributors group object ID.')
param lzContributorsGroupId string

@description('Security Readers group object ID.')
param securityReadersGroupId string

var contosoMgName = prefix
var platformMgName = '${prefix}-platform'
var landingZonesMgName = '${prefix}-landingzones'
var corpMgName = '${prefix}-landingzones-corp'
var sandboxMgName = '${prefix}-sandbox'

var contosoMgId = tenantResourceId('Microsoft.Management/managementGroups', contosoMgName)
var platformMgId = tenantResourceId('Microsoft.Management/managementGroups', platformMgName)
var landingZonesMgId = tenantResourceId('Microsoft.Management/managementGroups', landingZonesMgName)
var corpMgId = tenantResourceId('Microsoft.Management/managementGroups', corpMgName)
var sandboxMgId = tenantResourceId('Microsoft.Management/managementGroups', sandboxMgName)

var allowedLocationsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
var ownerRoleDefinitionId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var securityReaderRoleDefinitionId = '39bc4728-0917-49c7-9d2c-d95423bc2eb4'

module managementGroups './managementGroups.bicep' = {
  name: 'management-groups'
  params: {
    prefix: prefix
  }
}

module policyDefinitions './policyDefinitions.bicep' = {
  name: 'policy-definitions'
  scope: managementGroup(contosoMgName)
  dependsOn: [
    managementGroups
  ]
  params: {
    prefix: prefix
  }
}

module tlsAssignment './policyAssignments.bicep' = {
  name: 'policy-tls12-landingzones'
  scope: managementGroup(landingZonesMgName)
  dependsOn: [
    managementGroups
  ]
  params: {
    assignmentName: '${prefix}-tls12-landingzones'
    policyDefinitionId: policyDefinitions.outputs.requireTls12Id
    displayName: 'Require TLS 1.2 for Storage Accounts'
  }
}

module privateEndpointsAssignment './policyAssignments.bicep' = {
  name: 'policy-private-endpoints-corp'
  scope: managementGroup(corpMgName)
  dependsOn: [
    managementGroups
  ]
  params: {
    assignmentName: '${prefix}-private-endpoints-corp'
    policyDefinitionId: policyDefinitions.outputs.requirePrivateEndpointsId
    displayName: 'Require private endpoints for PaaS'
  }
}

module allowedVmSkusAssignment './policyAssignments.bicep' = {
  name: 'policy-allowed-vm-skus-sandbox'
  scope: managementGroup(sandboxMgName)
  dependsOn: [
    managementGroups
  ]
  params: {
    assignmentName: '${prefix}-allowed-vm-skus-sandbox'
    policyDefinitionId: policyDefinitions.outputs.allowedVmSkusPolicyId
    displayName: 'Allowed VM SKUs'
    assignmentParameters: {
      allowedVmSkus: {
        value: allowedVmSkus
      }
    }
  }
}

module allowedLocationsAssignment './policyAssignments.bicep' = {
  name: 'policy-allowed-locations-contoso'
  scope: managementGroup(contosoMgName)
  dependsOn: [
    managementGroups
  ]
  params: {
    assignmentName: '${prefix}-allowed-locations-contoso'
    policyDefinitionId: allowedLocationsPolicyId
    displayName: 'Allowed locations'
    assignmentParameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

module platformOwnerAssignment './roleAssignments.bicep' = {
  name: 'role-platform-owner'
  scope: managementGroup(platformMgName)
  dependsOn: [
    managementGroups
  ]
  params: {
    principalId: platformAdminsGroupId
    roleDefinitionId: ownerRoleDefinitionId
    scopeId: platformMgId
  }
}

module landingZonesContributorAssignment './roleAssignments.bicep' = {
  name: 'role-landingzones-contributor'
  scope: managementGroup(landingZonesMgName)
  dependsOn: [
    managementGroups
  ]
  params: {
    principalId: lzContributorsGroupId
    roleDefinitionId: contributorRoleDefinitionId
    scopeId: landingZonesMgId
  }
}

module securityReaderAssignment './roleAssignments.bicep' = {
  name: 'role-contoso-security-reader'
  scope: managementGroup(contosoMgName)
  dependsOn: [
    managementGroups
  ]
  params: {
    principalId: securityReadersGroupId
    roleDefinitionId: securityReaderRoleDefinitionId
    scopeId: contosoMgId
  }
}

@description('Contoso management group ID.')
output contosoId string = contosoMgId

@description('Platform management group ID.')
output platformId string = platformMgId

@description('Landing Zones management group ID.')
output landingZonesId string = landingZonesMgId

@description('Corp management group ID.')
output corpId string = corpMgId

@description('Sandbox management group ID.')
output sandboxId string = sandboxMgId

@description('TLS 1.2 policy definition ID.')
output requireTls12PolicyDefinitionId string = policyDefinitions.outputs.requireTls12Id

@description('Private endpoints policy definition ID.')
output requirePrivateEndpointsPolicyDefinitionId string = policyDefinitions.outputs.requirePrivateEndpointsId

@description('Allowed VM SKUs policy definition ID.')
output allowedVmSkusPolicyDefinitionId string = policyDefinitions.outputs.allowedVmSkusPolicyId

@description('TLS 1.2 policy assignment ID.')
output tlsAssignmentId string = tlsAssignment.outputs.assignmentId

@description('Private endpoints policy assignment ID.')
output privateEndpointsAssignmentId string = privateEndpointsAssignment.outputs.assignmentId

@description('Allowed VM SKUs policy assignment ID.')
output allowedVmSkusAssignmentId string = allowedVmSkusAssignment.outputs.assignmentId

@description('Allowed locations policy assignment ID.')
output allowedLocationsAssignmentId string = allowedLocationsAssignment.outputs.assignmentId

@description('Platform Owner role assignment ID.')
output platformOwnerAssignmentId string = platformOwnerAssignment.outputs.assignmentId

@description('Landing Zones Contributor role assignment ID.')
output landingZonesContributorAssignmentId string = landingZonesContributorAssignment.outputs.assignmentId

@description('Security Reader role assignment ID.')
output securityReaderAssignmentId string = securityReaderAssignment.outputs.assignmentId
