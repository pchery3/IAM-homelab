// Assigns a built-in Azure role to a security group at management group scope.
targetScope = 'managementGroup'

@description('Object ID of the Entra ID security group.')
param principalId string

@description('GUID of the built-in role definition.')
param roleDefinitionId string

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'Group'
  }
}
