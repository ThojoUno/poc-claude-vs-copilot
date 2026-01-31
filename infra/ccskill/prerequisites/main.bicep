targetScope = 'resourceGroup'

@description('Deployment environment.')
@allowed(['dev', 'prod'])
param environment string = 'dev'

@description('Azure region for resources.')
param location string = resourceGroup().location

@description('Tags to apply to all resources.')
param tags object = {
  environment: environment
  project: 'poc-claude-vs-copilot'
  tool: 'ccskill'
  owner: 'platform-team'
  costCenter: 'engineering'
}

var nameSuffix = 'ccskill-${environment}-eus2'
var uniqueSuffix = uniqueString(resourceGroup().id)
var logAnalyticsName = 'law-${nameSuffix}'
var keyVaultName = 'kv-${nameSuffix}-${take(uniqueSuffix, 6)}'
var vnetName = 'vnet-prereq-${nameSuffix}'
var managedIdentityName = 'uai-storage-cmk-${nameSuffix}'
var privateDnsZoneName = 'privatelink.blob.${az.environment().suffixes.storage}'

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Key Vault with RBAC and purge protection
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// CMK encryption key for storage account
resource cmkKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: keyVault
  name: 'cmk-storage'
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'encrypt'
      'decrypt'
      'wrapKey'
      'unwrapKey'
    ]
    attributes: {
      enabled: true
    }
  }
}

// User-assigned managed identity for storage account CMK access
// Created in prerequisites to avoid RBAC propagation timing issues
resource storageIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

// Key Vault Crypto Service Encryption User role for storage identity
resource kvCryptoRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, storageIdentity.id, 'e147488a-f6f5-4113-8e2d-b22465e65bf6')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')
    principalId: storageIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Virtual Network with private endpoint subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'PrivateEndpointSubnet'
        properties: {
          addressPrefix: '10.100.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Private DNS Zone for blob storage
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

// Link DNS Zone to VNet
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

// Diagnostics for Log Analytics Workspace
resource lawDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${logAnalyticsWorkspace.name}'
  scope: logAnalyticsWorkspace
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Diagnostics for Key Vault
resource kvDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${keyVault.name}'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Diagnostics for VNet
resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${vnet.name}'
  scope: vnet
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('Log Analytics Workspace resource ID.')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics Workspace name.')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name

@description('Key Vault resource ID.')
output keyVaultId string = keyVault.id

@description('Key Vault name.')
output keyVaultName string = keyVault.name

@description('Key Vault URI.')
output keyVaultUri string = keyVault.properties.vaultUri

@description('CMK key name.')
output cmkKeyName string = cmkKey.name

@description('Virtual Network resource ID.')
output vnetId string = vnet.id

@description('Private Endpoint Subnet resource ID.')
output privateEndpointSubnetId string = vnet.properties.subnets[0].id

@description('Storage CMK managed identity resource ID.')
output storageCmkIdentityId string = storageIdentity.id

@description('Storage CMK managed identity principal ID.')
output storageCmkIdentityPrincipalId string = storageIdentity.properties.principalId

@description('Private DNS Zone resource ID.')
output privateDnsZoneId string = privateDnsZone.id
