# 05 — Przywracanie konta z OU=Disabled

## 1. Problem / scenariusz

Po cyklu deaktywacji ([02-deactivate-inactive-accounts](../02-deactivate-inactive-accounts/)) manager zgłasza, że konto było nadal potrzebne (urlop, projekt, konto współdzielone). Trzeba szybko przywrócić dostęp bez ręcznego grzebania w ADUC.

## 2. Diagnoza krok po kroku

1. Potwierdź tożsamość użytkownika i zatwierdzenie managera (ticket)
2. `Get-ADUser -Identity <sam> -Properties *` — czy konto jest w `OU=Disabled`?
3. Sprawdź, czy docelowe OU istnieje i ma poprawne ACL
4. Zweryfikuj grupy — czy członkostwo w grupach pozostało po disable (zwykle tak)
5. Ustal, czy wymagana zmiana hasła przy pierwszym logowaniu

## 3. Root cause

- Brak formalnego procesu reaktywacji po automatycznej deaktywacji
- Manager nie widział raportu przed disable (brak fazy 03 → akceptacja)
- Konta współdzielone / serwisowe bez wykluczeń w filtrze nieaktywności

## 4. Fix / rozwiązanie

1. `Enable-ADAccount`
2. `Move-ADObject` z OU=Disabled do OU docelowego (np. dział użytkownika)
3. Aktualizacja `Description` z datą przywrócenia
4. Wpis do CSV logu — ślad audytowy
5. Opcjonalnie: `Set-ADUser -ChangePasswordAtLogon $true` jeśli polityka tego wymaga

## 5. Skrypt / kod

| Plik | Opis |
|------|------|
| [Enable-ADUserFromDisabled.ps1](./Enable-ADUserFromDisabled.ps1) | Enable + move + log |

```powershell
.\Enable-ADUserFromDisabled.ps1 `
    -SamAccountName jan.kowalski `
    -TargetOU "OU=IT,OU=Warszawa,DC=firma,DC=pl" `
    -WhatIf
```

## 6. Lessons learned

- Każda deaktywacja powinna mieć odpowiadający **proces reaktywacji** z ticketem
- Log CSV z przywróceń + raport disable = pełny łańcuch audytowy
- Nie przywracaj bez weryfikacji managera — ryzyko przywrócenia kont skompromitowanych
- Rozważ time-bound disable: najpierw lock, potem move po 14 dniach