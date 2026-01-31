targetScope = 'tenant'

@description('Prefix for management group naming (e.g., contoso-cp).')
@minLength(3)
param prefix string

resource contoso 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: prefix
  properties: {
    displayName: prefix
  }
}

resource platform 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${prefix}-platform'
  properties: {
    displayName: 'Platform'
    details: {
      parent: {
        id: contoso.id
      }
    }
  }
}

resource management 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${prefix}-platform-management'
  properties: {
    displayName: 'Management'
    details: {
      parent: {
        id: platform.id
      }
    }
  }
}

resource connectivity 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${prefix}-platform-connectivity'
  properties: {
    displayName: 'Connectivity'
    details: {
      parent: {
        id: platform.id
      }
    }
  }
}

resource identity 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${prefix}-platform-identity'
  properties: {
    displayName: 'Identity'
    details: {
      parent: {
        id: platform.id
      }
    }
  }
}

resource landingZones 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${prefix}-landingzones'
  properties: {
    displayName: 'Landing Zones'
    details: {
      parent: {
        id: contoso.id
      }
    }
  }
}

resource corp 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${prefix}-landingzones-corp'
  properties: {
    displayName: 'Corp'
    details: {
      parent: {
        id: landingZones.id
      }
    }
  }
}

resource online 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${prefix}-landingzones-online'
  properties: {
    displayName: 'Online'
    details: {
      parent: {
        id: landingZones.id
      }
    }
  }
}

resource sandbox 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${prefix}-sandbox'
  properties: {
    displayName: 'Sandbox'
    details: {
      parent: {
        id: contoso.id
      }
    }
  }
}

resource decommissioned 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${prefix}-decommissioned'
  properties: {
    displayName: 'Decommissioned'
    details: {
      parent: {
        id: contoso.id
      }
    }
  }
}

@description('Contoso management group ID.')
output contosoId string = contoso.id

@description('Platform management group ID.')
output platformId string = platform.id

@description('Management management group ID.')
output managementId string = management.id

@description('Connectivity management group ID.')
output connectivityId string = connectivity.id

@description('Identity management group ID.')
output identityId string = identity.id

@description('Landing Zones management group ID.')
output landingZonesId string = landingZones.id

@description('Corp management group ID.')
output corpId string = corp.id

@description('Online management group ID.')
output onlineId string = online.id

@description('Sandbox management group ID.')
output sandboxId string = sandbox.id

@description('Decommissioned management group ID.')
output decommissionedId string = decommissioned.id
