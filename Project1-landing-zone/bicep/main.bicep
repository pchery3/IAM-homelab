// Project 1: Azure Landing Zone as code
// Rebuilds the Contoso Maritime landing zone from the portal walkthrough:
// management group hierarchy, subscription placement, group-based RBAC,
// the Contoso VM Operator custom role and the Azure Policy guardrails.
targetScope = 'tenant'

@description('ID prefix for every management group. "contoso" creates contoso, contoso-platform, contoso-corp, ...')
param mgPrefix string = 'contoso'

@description('Subscription ID to place under Corp (sub-corp-prod-001).')
param subscriptionId string

@description('Object ID of GRP-Auditors-Reader.')
param auditorsGroupId string

@description('Object ID of GRP-Platform-Admins.')
param platformAdminsGroupId string

@description('Object ID of GRP-Corp-Contributors.')
param corpContributorsGroupId string

@description('Object ID of GRP-VM-Operators.')
param vmOperatorsGroupId string

@description('Regions where resources and resource groups may be created.')
param allowedLocations array = [
  'eastus'
  'eastus2'
]

@description('Tag every resource group in Landing Zones must carry.')
param requiredTagName string = 'CostCenter'

@description('Custom role names are unique per tenant. Change this if the portal-built role still exists.')
param customRoleName string = 'Contoso VM Operator'

var mg = {
  contoso: mgPrefix
  platform: '${mgPrefix}-platform'
  identity: '${mgPrefix}-identity'
  management: '${mgPrefix}-management'
  connectivity: '${mgPrefix}-connectivity'
  landingZones: '${mgPrefix}-landingzones'
  corp: '${mgPrefix}-corp'
  online: '${mgPrefix}-online'
  sandbox: '${mgPrefix}-sandbox'
  decommissioned: '${mgPrefix}-decommissioned'
}

// Built-in role and policy definition IDs are the same in every tenant.
var roles = {
  reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

var policies = {
  allowedLocations: 'e56962a6-4747-49cd-b67b-bf8b01975c4c'
  allowedLocationsRg: 'e765b5de-1225-4ba3-bd56-1ac6695af988'
  requireTagOnRg: '96670d01-0a4d-4649-9c89-2d3abc0a5025'
  notAllowedResourceTypes: '6c112d4e-5bc7-47ae-a041-ea2d9dccd749'
}

// 1-2. Management group hierarchy and subscription placement
module managementGroups 'modules/managementGroups.bicep' = {
  name: 'managementGroups'
  params: {
    names: mg
    subscriptionId: subscriptionId
  }
}

// 4. Group-based RBAC
module rbacAuditors 'modules/roleAssignment.bicep' = {
  name: 'rbac-auditors-reader'
  scope: managementGroup(mg.contoso)
  dependsOn: [managementGroups]
  params: {
    principalId: auditorsGroupId
    roleDefinitionId: roles.reader
  }
}

module rbacPlatform 'modules/roleAssignment.bicep' = {
  name: 'rbac-platform-contributor'
  scope: managementGroup(mg.platform)
  dependsOn: [managementGroups]
  params: {
    principalId: platformAdminsGroupId
    roleDefinitionId: roles.contributor
  }
}

module rbacCorp 'modules/roleAssignment.bicep' = {
  name: 'rbac-corp-contributor'
  scope: managementGroup(mg.corp)
  dependsOn: [managementGroups]
  params: {
    principalId: corpContributorsGroupId
    roleDefinitionId: roles.contributor
  }
}

// 5. Custom least-privilege role
module vmOperatorRole 'modules/customRole.bicep' = {
  name: 'custom-role-vm-operator'
  scope: subscription(subscriptionId)
  dependsOn: [managementGroups]
  params: {
    roleName: customRoleName
    principalId: vmOperatorsGroupId
  }
}

// 7. Azure Policy guardrails
module policyAllowedLocationsRg 'modules/policyAssignment.bicep' = {
  name: 'policy-allowed-locations-rg'
  scope: managementGroup(mg.contoso)
  dependsOn: [managementGroups]
  params: {
    name: 'allowed-locations-rg'
    displayName: 'Allowed locations for resource groups'
    policyDefinitionId: policies.allowedLocationsRg
    parameters: {
      listOfAllowedLocations: { value: allowedLocations }
    }
  }
}

module policyAllowedLocations 'modules/policyAssignment.bicep' = {
  name: 'policy-allowed-locations'
  scope: managementGroup(mg.contoso)
  dependsOn: [managementGroups]
  params: {
    name: 'allowed-locations'
    displayName: 'Allowed locations'
    policyDefinitionId: policies.allowedLocations
    parameters: {
      listOfAllowedLocations: { value: allowedLocations }
    }
  }
}

module policyRequireTag 'modules/policyAssignment.bicep' = {
  name: 'policy-require-tag'
  scope: managementGroup(mg.landingZones)
  dependsOn: [managementGroups]
  params: {
    name: 'require-rg-tag'
    displayName: 'Require a ${requiredTagName} tag on resource groups'
    policyDefinitionId: policies.requireTagOnRg
    parameters: {
      tagName: { value: requiredTagName }
    }
  }
}

module policyDenyPublicIp 'modules/policyAssignment.bicep' = {
  name: 'policy-deny-public-ip'
  scope: managementGroup(mg.corp)
  dependsOn: [managementGroups]
  params: {
    name: 'deny-public-ip'
    displayName: 'Not allowed resource types: Public IP addresses'
    policyDefinitionId: policies.notAllowedResourceTypes
    parameters: {
      listOfResourceTypesNotAllowed: { value: ['Microsoft.Network/publicIPAddresses'] }
    }
  }
}

output managementGroupIds object = mg
output customRoleId string = vmOperatorRole.outputs.roleDefinitionId
