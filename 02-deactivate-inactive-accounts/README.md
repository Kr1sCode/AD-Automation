# 02 — Deaktywacja kont po X dniach nieaktywności

## 1. Problem / scenariusz

W domenie są setki włączonych kont, których właściciele nie logowali się od miesięcy. To naruszenie zasad least privilege i wymóg audytowy (NIS2, ISO 27001, wewnętrzne polityki IAM). Security wymaga cyklicznego „sprzątania” — ale bez ryzyka usunięcia konta pracownika na urlopie macierzyńskim lub koncie serwisowego.

**Cel:** automatyczne wyłączenie kont nieaktywnych > 90 dni, przeniesienie do `OU=Disabled`, ślad w opisie konta i raporcie CSV.

## 2. Diagnoza krok po kroku

1. `Get-ADUser -Filter * -Properties LastLogonDate` — ile kont ma puste `LastLogonDate`?
2. Sprawdź replikację — `LastLogonDate` aktualizuje się tylko przy logowaniu do domeny (nie zawsze = logowanie do aplikacji)
3. Wyklucz konta serwisowe: `PasswordNeverExpires -eq $true`, prefiks `svc-`, `OU=ServiceAccounts`
4. Zweryfikuj, czy `OU=Disabled` istnieje i ma poprawne ACL
5. Uruchom najpierw raport z [03-inactive-users-report](../03-inactive-users-report/) — zatwierdzenie przez managerów
6. Test: `-WhatIf` lub 1 konto testowe

## 3. Root cause

- Brak procesu offboardingu przy odejściach z firmy (konta zostają enabled)
- Konta tymczasowe po projektach nigdy nie są zamykane
- `LastLogonDate` nie był monitorowany — problem ujawniał się dopiero przy audycie
- Polityka „nikt nie usuwa kont” bez procedury disable → grace period → delete

## 4. Fix / rozwiązanie

1. **Faza 1 (raport):** co 30 dni lista nieaktywnych → weryfikacja z managerami
2. **Faza 2 (disable):** skrypt wyłącza konto, przenosi do `OU=Disabled`, wpisuje datę w `Description`
3. **Faza 3 (grace 30 dni):** reklamacje — przywrócenie z OU Disabled
4. **Faza 4 (delete):** dopiero po okresie karencji, osobny proces z zatwierdzeniem

Proces w skrypcie:
```
Get-ADUser (Enabled, LastLogonDate < cutoff)
  → Disable-ADAccount
  → Move-ADObject → OU=Disabled
  → Set-ADUser -Description "Disabled YYYY-MM-DD ..."
  → Export-Csv raport
```

## 5. Skrypt / kod

| Plik | Opis |
|------|------|
| [Disable-InactiveADUsers.ps1](./Disable-InactiveADUsers.ps1) | Deaktywacja + przeniesienie + raport |

```powershell
Import-Module ActiveDirectory

# Podgląd bez zmian
.\Disable-InactiveADUsers.ps1 -InactiveDays 90 -WhatIf

# Wykonanie
.\Disable-InactiveADUsers.ps1 -InactiveDays 90 -DisabledOU "OU=Disabled,DC=firma,DC=pl"
```

**Output:** `C:\Logs\disabled_accounts_YYYYMMDD.csv`

| Kolumna | Znaczenie |
|---------|-----------|
| SamAccountName | Login |
| DisplayName | Imię i nazwisko |
| Department | Dział |
| LastLogonDate | Ostatnie logowanie do domeny |
| DisabledOn | Data deaktywacji |

## 6. Lessons learned

- **LastLogonDate = $null** — konto nigdy się nie logowało; nie wyłączaj automatycznie bez wykluczeń (np. świeże onboardingi < 30 dni)
- **Konta serwisowe** — wykluczaj po OU, opisie lub `PasswordNeverExpires`; inaczej wyłączysz backup agenta
- **Nigdy delete od razu** — disable + move + 30 dni na reklamacje to minimum
- **Scheduled Task** — uruchamiaj miesięcznie z konta serwisowego z delegacją tylko na OU=Disabled
- **Powiadomienia** — kolejny krok: mail do managera 14 dni przed disable (Graph API / Send-MailMessage)

---

### Portfolio — skrót

| | |
|---|---|
| **Problem** | Zombie accounts — włączone konta bez logowania, ryzyko audytowe |
| **Podejście** | Raport → zatwierdzenie → disable + move + log CSV |
| **Output** | CSV z listą wyłączonych kont, opis na obiekcie AD |
| **Bezpieczeństwo** | WhatIf, wykluczenia svc, grace period przed delete, OU=Disabled z ograniczonym ACL |