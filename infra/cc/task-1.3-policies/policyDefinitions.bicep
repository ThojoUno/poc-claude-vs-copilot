targetScope = 'subscription'

@description('Prefix for policy definition names.')
@minLength(2)
param prefix string = 'cc'

// Custom Policy: Require TLS 1.2 for Storage Accounts
resource requireTls12Policy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: '${prefix}-require-tls12-storage'
  properties: {
    displayName: 'Require TLS 1.2 for Storage Accounts'
    description: 'Ensures storage accounts use TLS 1.2 as minimum version'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Storage'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts'
          }
          {
            anyOf: [
              {
                field: 'Microsoft.Storage/storageAccounts/minimumTlsVersion'
                notEquals: 'TLS1_2'
              }
              {
                field: 'Microsoft.Storage/storageAccounts/minimumTlsVersion'
                exists: 'false'
              }
            ]
          }
        ]
      }
      then: {
        effect: 'Deny'
      }
    }
  }
}

// Custom Policy: Audit Private Endpoints for PaaS
resource requirePrivateEndpointsPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: '${prefix}-audit-private-endpoints'
  properties: {
    displayName: 'Audit private endpoints for PaaS services'
    description: 'Audits PaaS services that do not have private endpoints configured'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Network'
      version: '1.0.0'
    }
    policyRule: {
      if: {
        anyOf: [
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.Storage/storageAccounts'
              }
              {
                field: 'Microsoft.Storage/storageAccounts/privateEndpointConnections[*].id'
                exists: 'false'
              }
            ]
          }
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.KeyVault/vaults'
              }
              {
                field: 'Microsoft.KeyVault/vaults/privateEndpointConnections[*].id'
                exists: 'false'
              }
            ]
          }
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.Sql/servers'
              }
              {
                field: 'Microsoft.Sql/servers/privateEndpointConnections[*].id'
                exists: 'false'
              }
            ]
          }
        ]
      }
      then: {
        effect: 'Audit'
      }
    }
  }
}

// Custom Policy: Allowed VM SKUs
resource allowedVmSkusPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: '${prefix}-allowed-vm-skus'
  properties: {
    displayName: 'Allowed VM SKUs'
    description: 'Restricts VM deployments to approved SKUs'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Compute'
      version: '1.0.0'
    }
    parameters: {
      allowedSkus: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed VM SKUs'
          description: 'List of allowed VM SKU names'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Compute/virtualMachines'
          }
          {
            not: {
              field: 'Microsoft.Compute/virtualMachines/sku.name'
              in: '[parameters(\'allowedSkus\')]'
            }
          }
        ]
      }
      then: {
        effect: 'Deny'
      }
    }
  }
}

@description('Require TLS 1.2 policy definition ID.')
output requireTls12PolicyId string = requireTls12Policy.id

@description('Audit private endpoints policy definition ID.')
output requirePrivateEndpointsPolicyId string = requirePrivateEndpointsPolicy.id

@description('Allowed VM SKUs policy definition ID.')
output allowedVmSkusPolicyId string = allowedVmSkusPolicy.id
