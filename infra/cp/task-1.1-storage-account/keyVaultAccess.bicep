targetScope = 'resourceGroup'

@description('Key Vault name in this resource group.')
param keyVaultName string

@description('Role definition ID for Key Vault crypto role.')
param keyVaultRoleDefinitionId string

@description('Principal ID to grant access to the Key Vault key.')
param principalId string

@description('Principal type for the role assignment.')
@allowed([
  'ServicePrincipal'
  'Group'
  'User'
])
param principalType string = 'ServicePrincipal'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, principalId, keyVaultRoleDefinitionId)
  scope: keyVault
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', keyVaultRoleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

@description('Key Vault URI.')
output vaultUri string = keyVault.properties.vaultUri

@description('Key Vault resource ID.')
output keyVaultId string = keyVault.id
