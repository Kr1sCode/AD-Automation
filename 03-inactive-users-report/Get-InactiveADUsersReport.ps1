#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Generuje raport CSV kont bez logowania od X dni (tylko odczyt).
.EXAMPLE
    .\Get-InactiveADUsersReport.ps1 -InactiveDays 90
#>
[CmdletBinding()]
param(
    [int]$InactiveDays = 90,
    [string]$LogDir = "C:\Logs"
)

$cutoffDate = (Get-Date).AddDays(-$InactiveDays)
$reportPath = Join-Path $LogDir "inactive_users_$(Get-Date -Format 'yyyyMMdd').csv"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

Get-ADUser -Filter {
    Enabled -eq $true -and
    LastLogonDate -lt $cutoffDate
} -Properties DisplayName, LastLogonDate, Department, Manager,
              PasswordLastSet, PasswordNeverExpires, EmailAddress |
    Where-Object { $_.LastLogonDate -ne $null } |
    Select-Object `
        SamAccountName,
        DisplayName,
        Department,
        @{ N = "Manager"; E = {
                if ($_.Manager) {
                    (Get-ADUser $_.Manager -Properties DisplayName).DisplayName
                }
            }
        },
        LastLogonDate,
        PasswordLastSet,
        PasswordNeverExpires,
        EmailAddress |
    Sort-Object LastLogonDate |
    Export-Csv $reportPath -NoTypeInformation -Encoding UTF8

Write-Host "Raport zapisany: $reportPath"