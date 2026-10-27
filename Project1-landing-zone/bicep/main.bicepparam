using './main.bicep'

// Replace the placeholder GUIDs before deploying.
// scripts/New-ContosoIdentities.ps1 prints the four group object IDs.
param mgPrefix = 'contoso'
param subscriptionId = '00000000-0000-0000-0000-000000000000'

param auditorsGroupId = '00000000-0000-0000-0000-000000000000'
param platformAdminsGroupId = '00000000-0000-0000-0000-000000000000'
param corpContributorsGroupId = '00000000-0000-0000-0000-000000000000'
param vmOperatorsGroupId = '00000000-0000-0000-0000-000000000000'

param allowedLocations = [
  'eastus'
  'eastus2'
]
param requiredTagName = 'CostCenter'
param customRoleName = 'Contoso VM Operator'
