# Project 1 as code (Bicep)

The [portal build](../README.md) of the Contoso Maritime landing zone, rewritten as Infrastructure as Code. One deployment creates the same hierarchy, RBAC, custom role and policies.

| Portal step | File |
|---|---|
| 1–2. Management groups and subscription placement | [`modules/managementGroups.bicep`](modules/managementGroups.bicep) |
| 3. Test users and security groups | [`../scripts/New-ContosoIdentities.ps1`](../scripts/New-ContosoIdentities.ps1) (Entra ID objects, so Graph PowerShell instead of Bicep) |
| 4. Group-based RBAC | [`modules/roleAssignment.bicep`](modules/roleAssignment.bicep) |
| 5. Contoso VM Operator custom role | [`modules/customRole.bicep`](modules/customRole.bicep) |
| 7. Azure Policy guardrails | [`modules/policyAssignment.bicep`](modules/policyAssignment.bicep) |
| Wires it all together | [`main.bicep`](main.bicep) + [`main.bicepparam`](main.bicepparam) |

Every push that touches a `.bicep` file is compiled by the [Validate Bicep](../../.github/workflows/validate-bicep.yml) GitHub Actions workflow.

## Before you deploy

- **It deploys at tenant scope**, because it creates management groups under the Tenant Root Group. Your account needs Owner (or User Access Administrator plus Contributor) at root `/`. Turn on elevated access for the deployment and **turn it off again afterwards**, as in step 9 of the portal build.
- **Name clashes with the portal build.** Custom role names are unique per tenant, and management group IDs must be unique. To deploy next to what you built by hand, use a different `mgPrefix` (e.g. `contoso2`) and `customRoleName` (e.g. `Contoso VM Operator v2`). Otherwise remove the portal versions first.
- **Moving the subscription** under the new Corp group means it stops inheriting from the portal-built hierarchy.

## Deploy

```bash
# 1. Create the users and groups, then copy the printed group IDs into main.bicepparam
pwsh ../scripts/New-ContosoIdentities.ps1 -Domain <yourtenant>.onmicrosoft.com

# 2. Sign in and fill in subscriptionId in main.bicepparam
az login
az account show --query id -o tsv

# 3. Preview the changes; nothing is created yet
az deployment tenant what-if --location eastus --parameters main.bicepparam

# 4. Deploy
az deployment tenant create --name contoso-landing-zone --location eastus --parameters main.bicepparam
```

`--location` is only where Azure stores the deployment record; it does not place any resources.

## Verify

Re-run the tests from the portal build (section 6 and section 8). They should give the same results:

| Test | Expected |
|---|---|
| Ana Garcia creates a resource group | ❌ `AuthorizationFailed` |
| Maria Lee creates a resource group with `CostCenter` tag in East US | ✅ Created |
| Any user creates a resource group in West US | ❌ `RequestDisallowedByPolicy` |
| Any user creates a public IP in Corp | ❌ `RequestDisallowedByPolicy` |

## Clean up

Deleting the deployment record doesn't remove anything. To tear the lab down, remove the policy assignments and role assignments, move the subscription back, delete the management groups bottom-up, then delete the custom role.
