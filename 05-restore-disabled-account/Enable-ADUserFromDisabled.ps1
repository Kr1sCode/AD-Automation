#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Przywraca konto z OU=Disabled — enable + przeniesienie do OU docelowego.
.EXAMPLE
    .\Enable-ADUserFromDisabled.ps1 -SamAccountName jan.kowalski -TargetOU "OU=IT,DC=firma,DC=pl"
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$SamAccountName,

    [Parameter(Mandatory = $true)]
    [string]$TargetOU,

    [string]$LogDir = "C:\Logs"
)

$user = Get-ADUser -Identity $SamAccountName -Properties DistinguishedName, DisplayName

if ($PSCmdlet.ShouldProcess($SamAccountName, "Enable and move to $TargetOU")) {
    Enable-ADAccount -Identity $SamAccountName
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $TargetOU
    Set-ADUser -Identity $SamAccountName `
        -Description "Re-enabled $(Get-Date -Format 'yyyy-MM-dd') — restored from OU=Disabled"

    $logPath = Join-Path $LogDir "restored_accounts_$(Get-Date -Format 'yyyyMMdd').csv"
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    [PSCustomObject]@{
        SamAccountName = $SamAccountName
        DisplayName    = $user.DisplayName
        TargetOU       = $TargetOU
        RestoredOn     = Get-Date -Format 'yyyy-MM-dd HH:mm'
    } | Export-Csv $logPath -NoTypeInformation -Encoding UTF8 -Append

    Write-Host "Przywrocono: $SamAccountName -> $TargetOU (log: $logPath)" -ForegroundColor Green
}