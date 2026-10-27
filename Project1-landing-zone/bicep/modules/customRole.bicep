// Contoso VM Operator: start, restart and deallocate VMs without the ability
// to create, change or delete them. Assigned to GRP-VM-Operators.
targetScope = 'subscription'

param roleName string

@description('Object ID of GRP-VM-Operators.')
param principalId string

resource vmOperator 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, roleName)
  properties: {
    roleName: roleName
    description: 'Start, restart and deallocate virtual machines. Cannot create, modify or delete them.'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/virtualMachines/read'
          'Microsoft.Compute/virtualMachines/start/action'
          'Microsoft.Compute/virtualMachines/restart/action'
          'Microsoft.Compute/virtualMachines/deallocate/action'
        ]
        notActions: []
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, vmOperator.id)
  properties: {
    roleDefinitionId: vmOperator.id
    principalId: principalId
    principalType: 'Group'
  }
}

output roleDefinitionId string = vmOperator.id
