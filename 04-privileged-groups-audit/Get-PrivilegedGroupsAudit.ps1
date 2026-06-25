#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Audyt czlonkostwa w grupach uprzywilejowanych AD.
.EXAMPLE
    .\Get-PrivilegedGroupsAudit.ps1
#>
[CmdletBinding()]
param(
    [string]$LogDir = "C:\Logs"
)

$privilegedGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Group Policy Creator Owners",
    "Administrators",
    "Account Operators",
    "Backup Operators",
    "Server Operators"
)

$reportPath = Join-Path $LogDir "privileged_audit_$(Get-Date -Format 'yyyyMMdd').csv"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$report = foreach ($group in $privilegedGroups) {
    try {
        $members = Get-ADGroupMember -Identity $group -Recursive |
            Where-Object { $_.objectClass -eq "user" }

        foreach ($member in $members) {
            $user = Get-ADUser -Identity $member.SamAccountName `
                -Properties DisplayName, LastLogonDate, Enabled,
                PasswordNeverExpires, EmailAddress

            [PSCustomObject]@{
                Group                = $group
                SamAccountName       = $user.SamAccountName
                DisplayName          = $user.DisplayName
                Enabled              = $user.Enabled
                LastLogonDate        = $user.LastLogonDate
                PasswordNeverExpires = $user.PasswordNeverExpires
                Email                = $user.EmailAddress
                AuditDate            = Get-Date -Format 'yyyy-MM-dd'
            }
        }
    }
    catch {
        Write-Warning "Nie mozna pobrac grupy: $group - $_"
    }
}

$report | Export-Csv $reportPath -NoTypeInformation -Encoding UTF8

$report | Group-Object Group |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Format-Table -AutoSize

Write-Host "Pelny raport: $reportPath"