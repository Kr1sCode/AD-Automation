#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Masowe tworzenie kont AD z pliku CSV.
.EXAMPLE
    .\New-ADUsersFromCsv.ps1 -CsvPath "C:\users.csv"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [string]$DefaultPassword = "Temp@2026!",
    [string]$UpnSuffix = "firma.pl"
)

Import-Csv $CsvPath | ForEach-Object {
    $samAccount  = "$($_.FirstName.ToLower()).$($_.LastName.ToLower())"
    $upn         = "$samAccount@$UpnSuffix"
    $displayName = "$($_.FirstName) $($_.LastName)"
    $password    = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

    try {
        New-ADUser `
            -SamAccountName         $samAccount `
            -UserPrincipalName      $upn `
            -Name                   $displayName `
            -GivenName              $_.FirstName `
            -Surname                $_.LastName `
            -DisplayName            $displayName `
            -Department             $_.Department `
            -City                   $_.City `
            -Manager                $_.Manager `
            -Path                   $_.OU `
            -AccountPassword        $password `
            -ChangePasswordAtLogon  $true `
            -Enabled                $true

        Write-Host "Utworzono: $samAccount" -ForegroundColor Green
    }
    catch {
        Write-Warning "Blad dla $samAccount : $_"
    }
}