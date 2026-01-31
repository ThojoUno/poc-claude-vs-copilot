targetScope = 'resourceGroup'

@description('Deployment environment.')
@allowed(['dev', 'prod'])
param environment string = 'dev'

@description('Azure region for resources.')
param location string = resourceGroup().location

@description('Address space for the hub VNet.')
param addressSpace string = '10.0.0.0/16'

@description('Custom DNS servers. Leave empty for Azure-provided DNS.')
param dnsServers array = []

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

@description('Tags to apply to resources.')
param tags object = {
  environment: environment
  project: 'poc-claude-vs-copilot'
  tool: 'claude-code'
}

var toolPrefix = 'cc'
var nameSuffix = '${toolPrefix}-${environment}-eus2'

// Resource names
var vnetName = 'vnet-hub-${nameSuffix}'
var firewallName = 'afw-${nameSuffix}'
var firewallPipName = 'pip-afw-${nameSuffix}'
var bastionName = 'bas-${nameSuffix}'
var bastionPipName = 'pip-bas-${nameSuffix}'
var gatewayName = 'vpngw-${nameSuffix}'
var gatewayPipName = 'pip-vpngw-${nameSuffix}'
var routeTableName = 'rt-shared-${nameSuffix}'
var nsgName = 'nsg-shared-${nameSuffix}'

// Subnet address prefixes
var firewallSubnetPrefix = '10.0.0.0/26'
var bastionSubnetPrefix = '10.0.0.64/26'
var gatewaySubnetPrefix = '10.0.0.128/27'
var sharedServicesSubnetPrefix = '10.0.1.0/24'

// Virtual Network
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
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
  }
}

// Azure Firewall Subnet (no NSG allowed)
resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: firewallSubnetPrefix
  }
}

// Bastion Subnet (no NSG allowed on this specific subnet)
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: 'AzureBastionSubnet'
  properties: {
    addressPrefix: bastionSubnetPrefix
  }
  dependsOn: [
    firewallSubnet
  ]
}

// Gateway Subnet (no NSG allowed)
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: 'GatewaySubnet'
  properties: {
    addressPrefix: gatewaySubnetPrefix
  }
  dependsOn: [
    bastionSubnet
  ]
}

// NSG for Shared Services Subnet
resource sharedServicesNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

// Azure Firewall Public IP
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: firewallPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  zones: ['1', '2', '3']
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-11-01' = {
  name: firewallName
  location: location
  tags: tags
  zones: ['1', '2', '3']
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'ipconfig-afw'
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

// Bastion Public IP
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: bastionPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableIpConnect: true
    disableCopyPaste: false
    ipConfigurations: [
      {
        name: 'ipconfig-bas'
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

// VPN Gateway Public IP
resource gatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: gatewayPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  zones: ['1', '2', '3']
}

// VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = {
  name: gatewayName
  location: location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    enableBgp: true
    bgpSettings: {
      asn: 65515
    }
    activeActive: false
    sku: {
      name: environment == 'prod' ? 'VpnGw2AZ' : 'VpnGw1AZ'
      tier: environment == 'prod' ? 'VpnGw2AZ' : 'VpnGw1AZ'
    }
    ipConfigurations: [
      {
        name: 'ipconfig-vpngw'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnet.id
          }
          publicIPAddress: {
            id: gatewayPublicIp.id
          }
        }
      }
    ]
  }
}

// Route Table with default route to Firewall
resource routeTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: routeTableName
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
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

// Shared Services Subnet (with NSG and Route Table)
// Must wait for VPN Gateway to finish provisioning to avoid VNet conflicts
resource sharedServicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: 'SharedServicesSubnet'
  properties: {
    addressPrefix: sharedServicesSubnetPrefix
    networkSecurityGroup: {
      id: sharedServicesNsg.id
    }
    routeTable: {
      id: routeTable.id
    }
  }
  dependsOn: [
    gatewaySubnet
    vpnGateway
    firewall
    bastion
  ]
}

// Diagnostics - VNet
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

// Diagnostics - Firewall
resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${firewall.name}'
  scope: firewall
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

// Diagnostics - Firewall Public IP
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

// Diagnostics - Bastion
resource bastionDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${bastion.name}'
  scope: bastion
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

// Diagnostics - Bastion Public IP
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

// Diagnostics - VPN Gateway
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

// Diagnostics - VPN Gateway Public IP
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

// Diagnostics - NSG
resource nsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
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
  }
}

@description('Virtual Network resource ID.')
output vnetId string = vnet.id

@description('Azure Firewall private IP address.')
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress

@description('Azure Firewall public IP address.')
output firewallPublicIp string = firewallPublicIp.properties.ipAddress

@description('Azure Bastion resource ID.')
output bastionId string = bastion.id

@description('VPN Gateway resource ID.')
output gatewayId string = vpnGateway.id

@description('VPN Gateway public IP address.')
output gatewayPublicIp string = gatewayPublicIp.properties.ipAddress

@description('Shared Services Subnet resource ID.')
output sharedServicesSubnetId string = sharedServicesSubnet.id

@description('Route Table resource ID.')
output routeTableId string = routeTable.id
