// Assigns a built-in Azure Policy definition at management group scope.
targetScope = 'managementGroup'

@description('Assignment name. Management group scope allows at most 24 characters.')
@maxLength(24)
param name string

param displayName string

@description('GUID of the built-in policy definition.')
param policyDefinitionId string

@description('Policy parameters in { name: { value: ... } } form.')
param parameters object = {}

resource assignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: name
  properties: {
    displayName: displayName
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', policyDefinitionId)
    parameters: parameters
    enforcementMode: 'Default'
  }
}
