<#
.SYNOPSIS
    Creates the Contoso Maritime test users and security groups in Entra ID.

.DESCRIPTION
    Users and groups live in Entra ID, not Azure Resource Manager, so they are
    created with Microsoft Graph PowerShell instead of Bicep. Safe to re-run:
    existing users, groups and memberships are left as they are.

    Prints the group object IDs to paste into ../bicep/main.bicepparam.

.PARAMETER Domain
    Your tenant's domain, e.g. contosomaritime.onmicrosoft.com

.EXAMPLE
    Install-Module Microsoft.Graph -Scope CurrentUser
    ./New-ContosoIdentities.ps1 -Domain contosomaritime.onmicrosoft.com
#>
param(
    [Parameter(Mandatory)]
    [string]$Domain
)

$ErrorActionPreference = 'Stop'

Connect-MgGraph -Scopes 'User.ReadWrite.All', 'Group.ReadWrite.All' -NoWelcome

$groups = @(
    @{ Name = 'GRP-Platform-Admins';   Description = 'Contributor on the Platform management group' }
    @{ Name = 'GRP-Corp-Contributors'; Description = 'Contributor on the Corp management group' }
    @{ Name = 'GRP-Auditors-Reader';   Description = 'Reader on the Contoso management group' }
    @{ Name = 'GRP-VM-Operators';      Description = 'Contoso VM Operator on sub-corp-prod-001' }
)

$users = @(
    @{ First = 'John'; Last = 'Smith';  JobTitle = 'Platform Engineer'; Department = 'IT';          Group = 'GRP-Platform-Admins' }
    @{ First = 'Maria'; Last = 'Lee';   JobTitle = 'Developer';         Department = 'Engineering'; Group = 'GRP-Corp-Contributors' }
    @{ First = 'Ana'; Last = 'Garcia';  JobTitle = 'Auditor';           Department = 'Compliance';  Group = 'GRP-Auditors-Reader' }
    @{ First = 'Tom'; Last = 'Nguyen';  JobTitle = 'IT Operations';     Department = 'IT';          Group = 'GRP-VM-Operators' }
)

# One temporary password for new users; each must change it at first sign-in.
$secure = Read-Host -AsSecureString 'Temporary password for new users'
$tempPassword = [System.Net.NetworkCredential]::new('', $secure).Password

$groupIds = @{}
foreach ($g in $groups) {
    $existing = Get-MgGroup -Filter "displayName eq '$($g.Name)'"
    if ($existing) {
        Write-Host "Group exists:   $($g.Name)"
        $groupIds[$g.Name] = $existing.Id
    } else {
        $new = New-MgGroup -DisplayName $g.Name -Description $g.Description `
            -MailEnabled:$false -MailNickname $g.Name -SecurityEnabled
        Write-Host "Group created:  $($g.Name)"
        $groupIds[$g.Name] = $new.Id
    }
}

foreach ($u in $users) {
    $nickname = "$($u.First).$($u.Last)".ToLower()
    $upn = "$nickname@$Domain"
    $user = Get-MgUser -Filter "userPrincipalName eq '$upn'"
    if ($user) {
        Write-Host "User exists:    $upn"
    } else {
        $user = New-MgUser -DisplayName "$($u.First) $($u.Last)" `
            -GivenName $u.First -Surname $u.Last `
            -UserPrincipalName $upn -MailNickname $nickname `
            -JobTitle $u.JobTitle -Department $u.Department -UsageLocation 'US' `
            -AccountEnabled `
            -PasswordProfile @{ Password = $tempPassword; ForceChangePasswordNextSignIn = $true }
        Write-Host "User created:   $upn"
    }

    $groupId = $groupIds[$u.Group]
    $isMember = Get-MgGroupMember -GroupId $groupId -All | Where-Object Id -eq $user.Id
    if (-not $isMember) {
        New-MgGroupMember -GroupId $groupId -DirectoryObjectId $user.Id
        Write-Host "  added to      $($u.Group)"
    }
}

Write-Host "`nPaste these into ../bicep/main.bicepparam:"
Write-Host "param auditorsGroupId = '$($groupIds['GRP-Auditors-Reader'])'"
Write-Host "param platformAdminsGroupId = '$($groupIds['GRP-Platform-Admins'])'"
Write-Host "param corpContributorsGroupId = '$($groupIds['GRP-Corp-Contributors'])'"
Write-Host "param vmOperatorsGroupId = '$($groupIds['GRP-VM-Operators'])'"
