# 01 — Bulk onboarding użytkowników z CSV

## 1. Problem / scenariusz

Firma zatrudnia 20–50 osób naraz (nowy oddział, przejęcie spółki, sezonowe zatrudnienie). HR dostarcza listę w Excelu/CSV. Ręczne tworzenie kont w AD MMC trwa godziny, pojawiają się literówki w UPN, złe OU i brak managera.

**Cel:** jednorazowe, powtarzalne tworzenie kont z wymuszeniem zmiany hasła przy pierwszym logowaniu.

## 2. Diagnoza krok po kroku

1. Sprawdź format CSV — nagłówki, kodowanie UTF-8, poprawne DN w kolumnie `OU`
2. Zweryfikuj, czy OU docelowe istnieją: `Get-ADOrganizationalUnit -Filter *`
3. Sprawdź unikalność `sAMAccountName` — `Get-ADUser -Filter "SamAccountName -eq 'jan.kowalski'"`
4. Upewnij się, że wartości w `Manager` to poprawne `sAMAccountName` (nie DN)
5. Przetestuj na 1–2 rekordach w OU=test przed pełnym importem
6. Sprawdź politykę haseł domeny — czy hasło tymczasowe spełnia complexity

## 3. Root cause

- Brak zautomatyzowanego pipeline'u onboardingowego HR → IT
- Każdy admin robił konta „po swojemu” — niespójne nazewnictwo i brak wymuszenia zmiany hasła
- Przy większej skali ręczna praca nie skaluje się i generuje błędy ludzkie

## 4. Fix / rozwiązanie

1. Uzgodniony szablon CSV z HR (kolumny: FirstName, LastName, Department, City, Manager, OU)
2. Skrypt PowerShell z pętlą `Import-Csv` + `New-ADUser`
3. Konwencja UPN: `imie.nazwisko@firma.pl`
4. Hasło tymczasowe + `-ChangePasswordAtLogon $true`
5. Logowanie sukcesu/błędu na konsoli — błędne wiersze nie przerywają całego importu (`try/catch`)

## 5. Skrypt / kod

| Plik | Opis |
|------|------|
| [New-ADUsersFromCsv.ps1](./New-ADUsersFromCsv.ps1) | Główny skrypt importu |
| [users.csv.example](./users.csv.example) | Przykładowy plik wejściowy |

```powershell
# Przygotowanie
Import-Module ActiveDirectory

# Test na sucho — najpierw 1 rekord w OU=test
.\New-ADUsersFromCsv.ps1 -CsvPath "C:\users_test.csv"

# Produkcja
.\New-ADUsersFromCsv.ps1 -CsvPath "C:\users.csv" -UpnSuffix "firma.pl"
```

**Format CSV:**

```csv
FirstName,LastName,Department,City,Manager,OU
Jan,Kowalski,IT,Warszawa,adam.nowak,"OU=IT,OU=Warszawa,DC=firma,DC=pl"
```

## 6. Lessons learned

- **Duplikaty nazw:** `jan.kowalski` + `Jan Kowalski Jr.` — dodaj logikę sufiksu (`jan.kowalski2`) lub numer kadrowy w sAMAccountName
- **Manager jako DN:** lepiej przyjmować DN w CSV albo rozwiązywać `Get-ADUser -Filter` — unikasz błędów przy homonimach
- **Hasło w skrypcie:** na produkcji generuj losowe hasło per user i wysyłaj przez bezpieczny kanał (nie ten sam `Temp@2026!` dla wszystkich)
- **Idempotencja:** przed `New-ADUser` sprawdź `Get-ADUser` — przy ponownym uruchomieniu nie dostaniesz lawiny błędów
- **Następny krok:** powiąż z tworzeniem skrzynki M365 / grup AD — jeden pipeline zamiast trzech ręcznych kroków

---

### Portfolio — skrót

| | |
|---|---|
| **Problem** | Masowy onboarding bez spójności i z błędami ręcznej pracy |
| **Podejście** | CSV jako źródło prawdy, konwencja nazw, try/catch per rekord |
| **Output** | Konta AD w poprawnych OU, log na konsoli |
| **Bezpieczeństwo** | Test OU, wymuszenie zmiany hasła, brak haseł w repo, delegacja na OU docelowe |