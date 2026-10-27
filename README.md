# IAM Home Lab — Azure & Microsoft Entra ID

Hands-on identity and access management (IAM) lab built in Microsoft Azure and Entra ID for a fictional company, **Contoso Maritime**. Each project mirrors work an enterprise IAM / Zero Trust team does, with screenshots as evidence.

> Personal home lab built on my own time with personal accounts and equipment. All company names, users and data are fictional.

## Projects

| # | Project | What it covers | Status |
|---|---------|----------------|--------|
| 1 | [Azure Landing Zone](Project1-landing-zone/) | Management group hierarchy (CAF), group-based RBAC, custom least-privilege role, Azure Policy guardrails. Also built [as code with Bicep](Project1-landing-zone/bicep/) | ✅ Complete |
| 2 | [Enterprise IAM](Project2-enterprise-iam/) | Privileged Identity Management (PIM), Conditional Access, MFA, Access Reviews | ⚪ Planned (lab guide ready) |
| 3 | Automated Onboarding | Joiner / mover / leaver workflows with Power Automate + Entra ID | ⚪ Planned |
| 4 | RBAC Audit Dashboard | Power BI reporting on role assignments and access | ⚪ Planned |

## Zero Trust principles applied

- **Verify explicitly:** MFA with number matching on every privileged account
- **Least privilege:** access granted to groups, scoped to the lowest level needed, with custom roles where built-in roles give too much
- **Assume breach:** separate admin identities, a break-glass account, and guardrails that block risky actions before they happen

## Tools

Microsoft Azure · Microsoft Entra ID · Azure RBAC · Azure Policy · Bicep · Microsoft Graph PowerShell · GitHub Actions · Microsoft Authenticator · diagrams.net

## About me

Building toward IAM / Zero Trust roles. Connect with me on [LinkedIn](https://www.linkedin.com/in/patriquechery-cyber).
