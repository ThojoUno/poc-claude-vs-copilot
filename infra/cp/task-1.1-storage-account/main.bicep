targetScope = 'resourceGroup'

@description('Deployment environment (dev or prod).')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Azure region for resources.')
param location string

@description('Workload name used in the storage account name.')
@minLength(2)
@maxLength(10)
param workloadName string

@description('Region code for naming (e.g., eus2, wus2).')
@minLength(3)
@maxLength(5)
param regionCode string

@description('Instance identifier for naming (e.g., 001).')
@minLength(1)
@maxLength(3)
param instance string

@description('Subnet resource ID for the private endpoint.')
param subnetId string

@description('Key Vault resource ID containing the CMK.')
param keyVaultId string

@description('Key name in Key Vault for CMK encryption.')
param keyName string

@description('Optional Key Vault key version for CMK. Leave empty for latest.')
param keyVersion string = ''

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources.')
param tags TagSet

@description('Role definition ID for Key Vault crypto role.')
param keyVaultRoleDefinitionId string = '14b46e9e-c2b7-41b4-b07b-48a6ebf60603'

type TagSet = {
  environment: string
  owner: string
  costCenter: string
  project: string
}

var toolPrefix = 'cp'
var storageAccountName = toLower(take('st${workloadName}${toolPrefix}${environment}${regionCode}${instance}', 24))
var privateEndpointName = 'pe-${storageAccountName}-blob'
var privateDnsZoneName = 'privatelink.blob.${az.environment().suffixes.storage}'
var vnetId = substring(subnetId, 0, indexOf(subnetId, '/subnets/'))
var keyVaultIdParts = split(keyVaultId, '/')
var keyVaultSubId = keyVaultIdParts[2]
var keyVaultRgName = keyVaultIdParts[4]
var keyVaultName = keyVaultIdParts[length(keyVaultIdParts) - 1]
var keyVaultScope = resourceGroup(keyVaultSubId, keyVaultRgName)

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uai-${storageAccountName}'
  location: location
  tags: tags
}

module keyVaultAccess './keyVaultAccess.bicep' = {
  name: 'keyvault-access'
  scope: keyVaultScope
  params: {
    keyVaultName: keyVaultName
    keyVaultRoleDefinitionId: keyVaultRoleDefinitionId
    principalId: userAssignedIdentity.properties.principalId
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: environment == 'prod' ? 'Disabled' : 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    encryption: {
      keySource: 'Microsoft.Keyvault'
      identity: {
        userAssignedIdentity: userAssignedIdentity.id
      }
      keyvaultproperties: {
        keyname: keyName
        keyvaulturi: keyVaultAccess.outputs.vaultUri
        keyversion: empty(keyVersion) ? null : keyVersion
      }
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2023-07-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2023-07-01' = {
  name: uniqueString(vnetId)
  parent: privateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneName
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${storageAccount.name}'
  scope: storageAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
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

@description('Storage account resource ID.')
output storageAccountId string = storageAccount.id

@description('Storage account name.')
output storageAccountName string = storageAccount.name

@description('Primary blob endpoint.')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('User-assigned managed identity principal ID.')
output managedIdentityPrincipalId string = userAssignedIdentity.properties.principalId
