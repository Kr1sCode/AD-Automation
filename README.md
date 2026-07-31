# AD-Automation

[![GitHub stars](https://img.shields.io/github/stars/Kr1sCode/AD-Automation?style=flat)](https://github.com/Kr1sCode/AD-Automation/stargazers)
[![License](https://img.shields.io/badge/license-see--LICENSE-blue)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/Kr1sCode/AD-Automation)](https://github.com/Kr1sCode/AD-Automation/commits/main)

Zestaw scenariuszy i skryptów PowerShell do codziennej administracji **Active Directory** — onboarding, higiena kont, raportowanie i audyt uprzywilejowanych grup.

Każdy folder to osobny case study z pełnym opisem: problem → diagnoza → root cause → fix → kod → lessons learned.

## Scenariusze

| # | Folder | Opis |
|---|--------|------|
| 1 | [01-bulk-onboarding-csv](./01-bulk-onboarding-csv/) | Masowe tworzenie kont użytkowników z pliku CSV |
| 2 | [02-deactivate-inactive-accounts](./02-deactivate-inactive-accounts/) | Deaktywacja kont po X dniach nieaktywności + przeniesienie do OU Disabled |
| 3 | [03-inactive-users-report](./03-inactive-users-report/) | Raport kont bez logowania od 90 dni (tylko odczyt) |
| 4 | [04-privileged-groups-audit](./04-privileged-groups-audit/) | Audyt członkostwa w grupach uprzywilejowanych |
| 5 | [05-restore-disabled-account](./05-restore-disabled-account/) | Przywracanie konta z OU=Disabled po reklamacji |

## Wymagania

- Windows Server z rolą **AD DS** lub stacja z **RSAT** (Active Directory module)
- Moduł `ActiveDirectory` (część RSAT / AD DS)
- Uprawnienia: odpowiednio `Account Operators` / delegacja OU / Domain Admin (zależnie od scenariusza)
- PowerShell 5.1+

```powershell
Import-Module ActiveDirectory
```

## Struktura każdego scenariusza

```
1. Problem / scenariusz     — co się dzieje w organizacji
2. Diagnoza krok po kroku   — co sprawdzasz przed działaniem
3. Root cause               — dlaczego problem wystąpił
4. Fix / rozwiązanie        — co zrobiłeś operacyjnie
5. Skrypt / kod             — plik .ps1 w folderze
6. Lessons learned          — co zrobić inaczej następnym razem
```

## Bezpieczeństwo — przed uruchomieniem na produkcji

- Zawsze testuj na **OU=test** lub środowisku labowym
- Użyj `-WhatIf` tam, gdzie cmdlet to wspiera (lub `-Confirm`)
- Nie commituj prawdziwych haseł, DN, domen — w przykładach: `firma.pl`, `DC=firma,DC=pl`
- Skrypty modyfikujące AD: loguj do CSV, uruchamiaj z konta serwisowego z minimalnymi uprawnieniami
- Deaktywacja kont: **nigdy delete od razu** — disable → 30 dni na reklamacje → dopiero delete

## Task Scheduler — automatyzacja cykliczna

Raporty i deaktywacje uruchamiaj z dedykowanego konta serwisowego z delegacją AD (nie Domain Admin na co dzień).

```powershell
# Przykład: miesięczny raport nieaktywnych (scenariusz 03)
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Get-InactiveADUsersReport.ps1"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -WeeksInterval 4 -At 06:00

Register-ScheduledTask `
    -TaskName "AD-InactiveUsersReport" `
    -Action $action `
    -Trigger $trigger `
    -User "SVC-AD-Report" `
    -RunLevel Highest
```

| Zadanie | Skrypt | Częstotliwość |
|---------|--------|---------------|
| Raport nieaktywnych | `03-.../Get-InactiveADUsersReport.ps1` | Co 30 dni |
| Deaktywacja | `02-.../Disable-InactiveADUsers.ps1` | Po akceptacji raportu |
| Audyt grup | `04-.../Get-PrivilegedGroupsAudit.ps1` | Co kwartał |

## Licencja

[MIT](./LICENSE) — Copyright (c) 2026 Krzysztof Gawkowski