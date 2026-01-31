targetScope = 'managementGroup'

@description('Prefix for policy definition names.')
@minLength(3)
param prefix string

resource requireTls12 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: '${prefix}-require-tls12'
  properties: {
    displayName: 'Require TLS 1.2 for Storage Accounts'
    policyType: 'Custom'
    mode: 'Indexed'
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

resource requirePrivateEndpoints 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: '${prefix}-require-private-endpoints'
  properties: {
    displayName: 'Require private endpoints for PaaS'
    policyType: 'Custom'
    mode: 'Indexed'
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
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.DocumentDB/databaseAccounts'
              }
              {
                field: 'Microsoft.DocumentDB/databaseAccounts/privateEndpointConnections[*].id'
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

resource allowedVmSkusPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: '${prefix}-allowed-vm-skus'
  properties: {
    displayName: 'Allowed VM SKUs'
    policyType: 'Custom'
    mode: 'Indexed'
    parameters: {
      allowedVmSkus: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed VM SKUs'
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
            field: 'Microsoft.Compute/virtualMachines/sku.name'
            notIn: '[parameters("allowedVmSkus")]'
          }
        ]
      }
      then: {
        effect: 'Deny'
      }
    }
  }
}

@description('TLS 1.2 policy definition ID.')
output requireTls12Id string = requireTls12.id

@description('Private endpoint policy definition ID.')
output requirePrivateEndpointsId string = requirePrivateEndpoints.id

@description('Allowed VM SKUs policy definition ID.')
output allowedVmSkusPolicyId string = allowedVmSkusPolicy.id
