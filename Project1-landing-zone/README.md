# Project 1: Azure Landing Zone

**Status:** ✅ Complete

**Goal:** Organize Azure the way an enterprise does: a governed management group hierarchy, access delegated through groups with least privilege, and guardrails that block risky actions automatically. Then prove every control works with real test accounts.

**Company:** Contoso Maritime (fictional) · **Tools:** Azure portal, Microsoft Entra ID, Azure RBAC, Azure Policy · **Cost:** $0

---

## Architecture

```mermaid
graph TD
    Root[Tenant Root Group] --> Contoso[Contoso<br/>Reader: GRP-Auditors-Reader<br/>Policy: allowed locations]
    Contoso --> Platform[Platform<br/>Contributor: GRP-Platform-Admins]
    Contoso --> LZ[Landing Zones<br/>Policy: require CostCenter tag]
    Contoso --> Sandbox[Sandbox]
    Contoso --> Decom[Decommissioned]
    Platform --> Identity[Identity]
    Platform --> Management[Management]
    Platform --> Connectivity[Connectivity]
    LZ --> Corp[Corp<br/>Contributor: GRP-Corp-Contributors<br/>Policy: no public IPs]
    LZ --> Online[Online]
    Corp --> Sub[sub-corp-prod-001<br/>Custom role: Contoso VM Operator]
```

Roles and policies assigned at a management group are **inherited** by everything beneath it.

![Management group tree](screenshots/01-mg-tree.jpg)

---

## 1. Management group hierarchy

Built a 10-group hierarchy based on Microsoft's Cloud Adoption Framework (CAF).

| Management group | Purpose |
|---|---|
| Contoso | Company root: org-wide roles and policies |
| Platform → Identity, Management, Connectivity | Shared services run by a central team |
| Landing Zones → Corp, Online | Application workloads (internal vs. public-facing) |
| Sandbox | Experiments, isolated from production |
| Decommissioned | Retired subscriptions, locked down |

## 2. Subscription placement

Moved the subscription into **Corp** and renamed it `sub-corp-prod-001`. It now inherits every role and policy from Corp, Landing Zones and Contoso.

## 3. Test users and security groups

Created 4 cloud-only users with job title and department, and **no admin roles**. Access is granted only through security groups using the naming convention `GRP-<team>-<access>`.

| User | Job title | Group |
|---|---|---|
| John Smith | Platform Engineer | GRP-Platform-Admins |
| Maria Lee | Developer | GRP-Corp-Contributors |
| Ana Garcia | Auditor | GRP-Auditors-Reader |
| Tom Nguyen | IT Operations | GRP-VM-Operators |

![Test users](screenshots/02-test-users.jpg)
![Security groups](screenshots/03-groups.jpg)

## 4. Group-based RBAC

| Scope | Role | Group |
|---|---|---|
| Contoso | Reader | GRP-Auditors-Reader |
| Platform | Contributor | GRP-Platform-Admins |
| Corp | Contributor | GRP-Corp-Contributors |

The auditors' Reader role was assigned once at Contoso and appears as **Inherited** on Platform and Corp.

![RBAC at Contoso](screenshots/04-rbac-contoso.jpg)
![RBAC at Platform](screenshots/05-rbac-platform.jpg)
![RBAC at Corp, showing inheritance](screenshots/06-rbac-corp.jpg)

## 5. Custom least-privilege role

No built-in role lets IT operations restart VMs without also letting them delete them, so I created **Contoso VM Operator** with exactly four actions and assigned it to GRP-VM-Operators on the subscription.

| Action | Allows |
|---|---|
| `Microsoft.Compute/virtualMachines/read` | See VMs |
| `Microsoft.Compute/virtualMachines/start/action` | Start |
| `Microsoft.Compute/virtualMachines/restart/action` | Restart |
| `Microsoft.Compute/virtualMachines/deallocate/action` | Stop and release compute |

![Custom role permissions](screenshots/07-custom-role-permissions.jpg)
![Custom role JSON](screenshots/08-custom-role-json.jpg)

## 6. Permission testing

Signed in as test users and tried the same action: creating a resource group in `sub-corp-prod-001`.

| User | Access | Result |
|---|---|---|
| Ana Garcia | Reader (inherited from Contoso) | ❌ "You do not have permissions to create resource groups" |
| Maria Lee | Contributor at Corp | ✅ Resource group created |

![Auditor denied](screenshots/09-agarcia-denied.jpg)
![Developer allowed](screenshots/10-mlee-success.jpg)

## 7. Azure Policy guardrails

| Policy | Scope | Setting |
|---|---|---|
| Allowed locations for resource groups | Contoso | East US, East US 2 |
| Allowed locations | Contoso | East US, East US 2 |
| Require a tag on resource groups | Landing Zones | `CostCenter` |
| Not allowed resource types | Corp | Public IP addresses |

![Policy assignments](screenshots/11-policy-assignments.jpg)

## 8. Proving the guardrails work

All tests were run as an **Owner**, which shows that policy applies even to the highest RBAC role.

| Test | Result |
|---|---|
| Resource group in West US | ❌ Blocked by *Allowed locations for resource groups* |
| `rg-corp-app01` in East US with `CostCenter = IT` | ✅ Created |
| Public IP in Corp | ❌ `RequestDisallowedByPolicy`: *Not allowed resource types* |
| Compliance dashboard | `rg-test-mlee` (created before the tag policy) flagged **Non-compliant** |

![Location denied](screenshots/12-policy-deny-location.jpg)
![Tagged resource group allowed](screenshots/13-policy-allowed.jpg)
![Public IP denied](screenshots/14-policy-deny-publicip.jpg)
![Compliance view](screenshots/15-policy-compliance.jpg)

## 9. Cleanup

- Deleted the test resource groups.
- Removed standing **elevated access** (User Access Administrator at root) from both accounts once the work was done.

![Elevated access off](screenshots/16-elevated-access-off.jpg)

---

## Zero Trust principles applied

| Principle | How |
|---|---|
| Verify explicitly | MFA with number matching on every account, admin and users |
| Least privilege | Group-based roles at the narrowest scope; custom role with 4 actions; elevated access removed after use |
| Assume breach | Separate admin identity, break-glass account, policies that block risky resources even for Owners |

## Lessons learned

1. **Entra roles ≠ Azure RBAC roles.** Global Administrator manages identities, not Azure resources. Managing management groups required elevated access.
2. **Owner ≠ User Access Administrator.** Elevated access can grant permissions but not manage resources. The subscription didn't appear in the move dialog until I assigned my admin Owner.
3. **"Allowed locations" doesn't cover resource groups.** A separate policy is needed to restrict where resource groups are created.
4. **Two different denials.** `AuthorizationFailed` means the user lacks permission (RBAC). `RequestDisallowedByPolicy` means a policy blocked it. Knowing which is which speeds up troubleshooting.
5. **Policy flags, it doesn't delete.** Existing resources that break a new rule show as non-compliant for review.
6. **Azure is eventually consistent.** Renames, moves and role assignments can take minutes to appear everywhere.
7. **MFA registration can break partway.** A user showed "No usable methods." I cleared her methods, required re-registration, revoked sessions, and she re-enrolled on a second device.

## Resume bullet

> Designed an Azure landing zone using a CAF management group hierarchy, group-based RBAC with a custom least-privilege role, and Azure Policy guardrails enforcing location, tagging and network restrictions; validated controls with test accounts and compliance reporting.
