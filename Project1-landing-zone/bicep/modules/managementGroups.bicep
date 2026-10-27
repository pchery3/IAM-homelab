// CAF-style management group hierarchy under the tenant root group,
// with the workload subscription placed under Corp.
targetScope = 'tenant'

@description('Management group IDs keyed by role in the hierarchy (see main.bicep).')
param names object

@description('Subscription ID to place under Corp.')
param subscriptionId string

var rootId = tenantResourceId('Microsoft.Management/managementGroups', tenant().tenantId)

resource contoso 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.contoso
  properties: {
    displayName: 'Contoso'
    details: { parent: { id: rootId } }
  }
}

resource platform 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.platform
  properties: {
    displayName: 'Platform'
    details: { parent: { id: contoso.id } }
  }
}

resource identity 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.identity
  properties: {
    displayName: 'Identity'
    details: { parent: { id: platform.id } }
  }
}

resource management 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.management
  properties: {
    displayName: 'Management'
    details: { parent: { id: platform.id } }
  }
}

resource connectivity 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.connectivity
  properties: {
    displayName: 'Connectivity'
    details: { parent: { id: platform.id } }
  }
}

resource landingZones 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.landingZones
  properties: {
    displayName: 'Landing Zones'
    details: { parent: { id: contoso.id } }
  }
}

resource corp 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.corp
  properties: {
    displayName: 'Corp'
    details: { parent: { id: landingZones.id } }
  }
}

resource online 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.online
  properties: {
    displayName: 'Online'
    details: { parent: { id: landingZones.id } }
  }
}

resource sandbox 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.sandbox
  properties: {
    displayName: 'Sandbox'
    details: { parent: { id: contoso.id } }
  }
}

resource decommissioned 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: names.decommissioned
  properties: {
    displayName: 'Decommissioned'
    details: { parent: { id: contoso.id } }
  }
}

// The subscription inherits every role and policy from Corp, Landing Zones and Contoso.
resource corpSubscription 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = {
  parent: corp
  name: subscriptionId
}
