# AD-Automation

Zestaw scenariuszy i skryptów PowerShell do codziennej administracji **Active Directory** — onboarding, higiena kont, raportowanie i audyt uprzywilejowanych grup.

Każdy folder to osobny case study z pełnym opisem: problem → diagnoza → root cause → fix → kod → lessons learned.

## Scenariusze

| # | Folder | Opis |
|---|--------|------|
| 1 | [01-bulk-onboarding-csv](./01-bulk-onboarding-csv/) | Masowe tworzenie kont użytkowników z pliku CSV |
| 2 | [02-deactivate-inactive-accounts](./02-deactivate-inactive-accounts/) | Deaktywacja kont po X dniach nieaktywności + przeniesienie do OU Disabled |
| 3 | [03-inactive-users-report](./03-inactive-users-report/) | Raport kont bez logowania od 90 dni (tylko odczyt) |
| 4 | [04-privileged-groups-audit](./04-privileged-groups-audit/) | Audyt członkostwa w grupach uprzywilejowanych |

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

## Licencja

Materiał referencyjny — użyj i modyfikuj według potrzeb organizacji.