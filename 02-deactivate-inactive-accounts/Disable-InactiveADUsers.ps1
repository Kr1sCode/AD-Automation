#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Wylacza konta nieaktywne od X dni i przenosi je do OU=Disabled.
.EXAMPLE
    .\Disable-InactiveADUsers.ps1 -InactiveDays 90 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$InactiveDays = 90,
    [string]$DisabledOU = "OU=Disabled,DC=firma,DC=pl",
    [string]$LogDir = "C:\Logs"
)

$cutoffDate = (Get-Date).AddDays(-$InactiveDays)
$logPath    = Join-Path $LogDir "disabled_accounts_$(Get-Date -Format 'yyyyMMdd').csv"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$inactiveUsers = Get-ADUser -Filter {
    Enabled -eq $true -and
    LastLogonDate -lt $cutoffDate -and
    PasswordNeverExpires -eq $false
} -Properties LastLogonDate, Department, Manager, DistinguishedName, DisplayName |
    Where-Object { $_.LastLogonDate -ne $null }

$report = foreach ($user in $inactiveUsers) {
    if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Disable and move to $DisabledOU")) {
        Disable-ADAccount -Identity $user.SamAccountName
        Move-ADObject -Identity $user.DistinguishedName -TargetPath $DisabledOU
        Set-ADUser -Identity $user.SamAccountName `
            -Description "Disabled $(Get-Date -Format 'yyyy-MM-dd') - inactivity > $InactiveDays days"

        [PSCustomObject]@{
            SamAccountName = $user.SamAccountName
            DisplayName    = $user.DisplayName
            Department     = $user.Department
            LastLogonDate  = $user.LastLogonDate
            DisabledOn     = Get-Date -Format 'yyyy-MM-dd'
        }
    }
}

if ($report) {
    $report | Export-Csv $logPath -NoTypeInformation -Encoding UTF8
    Write-Host "Wylaczono $($report.Count) kont. Raport: $logPath"
}
else {
    Write-Host "Brak kont do wylaczenia (lub tryb WhatIf)."
}