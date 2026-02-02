targetScope = 'resourceGroup'

@description('Deployment environment (dev or prod).')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Azure region for resources.')
param location string

@description('Address space for the hub virtual network.')
param addressSpace string = '10.0.0.0/16'

@description('Custom DNS servers for the VNet. Leave empty for Azure-provided.')
param dnsServers array = []

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources.')
param tags TagSet

type TagSet = {
  environment: string
  owner: string
  costCenter: string
  project: string
}

var toolPrefix = 'cp'
var instance = '001'
var vnetName = 'vnet-hub-${toolPrefix}-${environment}-${location}-${instance}'
var firewallPipName = 'pip-fw-${toolPrefix}-${environment}-${location}-${instance}'
var bastionPipName = 'pip-bas-${toolPrefix}-${environment}-${location}-${instance}'
var gatewayPipName = 'pip-vgw-${toolPrefix}-${environment}-${location}-${instance}'
var firewallName = 'fw-hub-${toolPrefix}-${environment}-${location}-${instance}'
var bastionName = 'bas-hub-${toolPrefix}-${environment}-${location}-${instance}'
var gatewayName = 'vgw-hub-${toolPrefix}-${environment}-${location}-${instance}'
var sharedServicesNsgName = 'nsg-shared-${toolPrefix}-${environment}-${location}-${instance}'
var sharedServicesRouteTableName = 'rt-shared-${toolPrefix}-${environment}-${location}-${instance}'

var firewallSubnetPrefix = '10.0.0.0/26'
var bastionSubnetPrefix = '10.0.0.64/26'
var gatewaySubnetPrefix = '10.0.0.128/27'
var sharedServicesSubnetPrefix = '10.0.1.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    dhcpOptions: length(dnsServers) > 0
      ? {
          dnsServers: dnsServers
        }
      : null
  }
}

resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: 'AzureFirewallSubnet'
  parent: vnet
  properties: {
    addressPrefix: firewallSubnetPrefix
  }
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: 'AzureBastionSubnet'
  parent: vnet
  properties: {
    addressPrefix: bastionSubnetPrefix
  }
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: 'GatewaySubnet'
  parent: vnet
  properties: {
    addressPrefix: gatewaySubnetPrefix
  }
}

resource sharedServicesNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: sharedServicesNsgName
  location: location
  tags: tags
}

resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: firewallPipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-11-01' = {
  name: firewallName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'azureFirewallIpConfig'
        properties: {
          subnet: {
            id: firewallSubnet.id
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
  }
}

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: bastionPipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource bastionHost 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableIpConnect: true
    enableShareableLink: true
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

resource gatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: gatewayPipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = {
  name: gatewayName
  location: location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
    bgpSettings: {
      asn: 65515
    }
    activeActive: false
    sku: {
      name: environment == 'prod' ? 'VpnGw2' : 'VpnGw1'
      tier: environment == 'prod' ? 'VpnGw2' : 'VpnGw1'
    }
    ipConfigurations: [
      {
        name: 'gatewayIpConfig'
        properties: {
          subnet: {
            id: gatewaySubnet.id
          }
          publicIPAddress: {
            id: gatewayPublicIp.id
          }
        }
      }
    ]
    vpnGatewayGeneration: 'Generation2'
  }
}

var firewallPrivateIp = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress

resource sharedServicesRouteTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: sharedServicesRouteTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource sharedServicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: 'SharedServicesSubnet'
  parent: vnet
  properties: {
    addressPrefix: sharedServicesSubnetPrefix
    routeTable: {
      id: sharedServicesRouteTable.id
    }
    networkSecurityGroup: {
      id: sharedServicesNsg.id
    }
  }
}

resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${vnet.name}'
  scope: vnet
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

resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${azureFirewall.name}'
  scope: azureFirewall
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

resource firewallPipDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${firewallPublicIp.name}'
  scope: firewallPublicIp
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

resource bastionDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${bastionHost.name}'
  scope: bastionHost
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

resource bastionPipDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${bastionPublicIp.name}'
  scope: bastionPublicIp
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

resource gatewayDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${vpnGateway.name}'
  scope: vpnGateway
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

resource gatewayPipDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${gatewayPublicIp.name}'
  scope: gatewayPublicIp
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

resource routeTableDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${sharedServicesRouteTable.name}'
  scope: sharedServicesRouteTable
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

resource sharedServicesNsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${sharedServicesNsg.name}'
  scope: sharedServicesNsg
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

@description('Virtual network resource ID.')
output vnetId string = vnet.id

@description('Azure Firewall private IP address.')
output firewallPrivateIp string = firewallPrivateIp

@description('Azure Firewall public IP address.')
output firewallPublicIp string = firewallPublicIp.properties.ipAddress

@description('Azure Bastion resource ID.')
output bastionId string = bastionHost.id

@description('VPN gateway resource ID.')
output gatewayId string = vpnGateway.id

@description('VPN gateway public IP address.')
output gatewayPublicIp string = gatewayPublicIp.properties.ipAddress
