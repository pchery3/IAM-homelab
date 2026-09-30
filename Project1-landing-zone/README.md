# Project 1: Azure Landing Zone

**Status:** 🟡 In progress (Steps 1–2 of 9 complete)

**Goal:** Organize Azure the way an enterprise does: a governed hierarchy, access delegated through groups with least privilege, and guardrails that block risky actions automatically.

---

## 1. Management group hierarchy ✅

Built a 10-group hierarchy based on Microsoft's Cloud Adoption Framework (CAF). Roles and policies assigned at a management group are **inherited** by everything beneath it.

```
Tenant Root Group
└── Contoso
    ├── Platform
    │   ├── Identity        sign-in and directory services
    │   ├── Management      logging and monitoring
    │   └── Connectivity    hub networking, firewalls, VPN
    ├── Landing Zones
    │   ├── Corp            internal apps, not internet-facing
    │   │   └── sub-corp-prod-001  (subscription)
    │   └── Online          public-facing apps
    ├── Sandbox             experiments, isolated from production
    └── Decommissioned      retired subscriptions, locked down
```

## 2. Subscription placement ✅

Moved the subscription into **Corp** and renamed it `sub-corp-prod-001` using a standard naming convention. It now inherits every role and policy assigned at Corp, Landing Zones and Contoso.

## 3–8. Coming next

- [ ] Test users and security groups
- [ ] Group-based RBAC assignments
- [ ] Custom least-privilege role (Contoso VM Operator)
- [ ] Permission testing as test users
- [ ] Azure Policy guardrails (allowed locations, required tags, no public IPs)
- [ ] Proving the guardrails work

---

## Lessons learned so far

1. **Entra roles ≠ Azure RBAC roles.** Global Administrator controls identities, not Azure resources. I had to enable *Access management for Azure resources* (elevated access) to manage management groups.
2. **Owner ≠ User Access Administrator.** Elevated access gave me User Access Administrator, which can grant access but not manage resources. The subscription didn't appear in the move dialog until I assigned my admin **Owner** on it.
3. **Azure is eventually consistent.** After the move and rename, the top-level view showed stale data for several minutes. Always check the object's own page before assuming a change failed.
4. **Finish MFA registration.** An incomplete Authenticator registration caused a sign-in loop. Completing enrollment with number matching fixed it.
