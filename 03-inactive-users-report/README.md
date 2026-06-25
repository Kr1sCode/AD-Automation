# 03 — Raport kont bez logowania od 90 dni

## 1. Problem / scenariusz

Zarząd / Security prosi o listę kont aktywnych, które nie były używane od 90+ dni — przed podjęciem decyzji o deaktywacji. Potrzebny jest **raport tylko do odczytu**, z managerem, działem i datą ostatniego logowania, do wysłania HR i liderom zespołów.

**Cel:** cykliczny CSV bez modyfikacji AD — input do procesu z [02-deactivate-inactive-accounts](../02-deactivate-inactive-accounts/).

## 2. Diagnoza krok po kroku

1. Ustal próg nieaktywności (90 dni to standard; czasem 60 lub 120)
2. `Get-ADUser -Filter { Enabled -eq $true }` — ile kont aktywnych w domenie?
3. Sprawdź pokrycie `LastLogonDate` — na ilu kontach jest `$null`?
4. Zweryfikuj pole `Manager` — czy wszystkie konta mają przypisanego przełożonego?
5. Porównaj z poprzednim raportem — nowe konta na liście vs. znikające (ktoś się zalogował)
6. Wyślij raport managerom z prośbą o potwierdzenie w 14 dni

## 3. Root cause

- Deaktywacja bez wcześniejszego raportowania budzi opór biznesu („wyłączyliście mi konto projektowe”)
- Brak widoczności dla managerów — IT działało w próżni
- Audyt wymagał dowodu, że lista była konsultowana przed działaniem

## 4. Fix / rozwiązanie

1. Miesięczny raport CSV z `Get-ADUser` + filtr `LastLogonDate`
2. Rozwiązanie `Manager` → `DisplayName` dla czytelności w Excelu
3. Sortowanie po `LastLogonDate` — najstarsze na górze
4. Raport jako załącznik do ticketu / maila do security@firma.pl
5. Po zatwierdzeniu → uruchomienie skryptu deaktywacji (scenariusz 02)

## 5. Skrypt / kod

| Plik | Opis |
|------|------|
| [Get-InactiveADUsersReport.ps1](./Get-InactiveADUsersReport.ps1) | Raport CSV (read-only) |

```powershell
Import-Module ActiveDirectory

.\Get-InactiveADUsersReport.ps1 -InactiveDays 90
# opcjonalnie: -LogDir "D:\Reports\AD"
```

**Output:** `C:\Logs\inactive_users_YYYYMMDD.csv`

| Kolumna | Znaczenie |
|---------|-----------|
| SamAccountName | Login |
| DisplayName | Imię i nazwisko |
| Department | Dział |
| Manager | DisplayName przełożonego |
| LastLogonDate | Ostatnie logowanie do domeny |
| PasswordLastSet | Kiedy ustawiono hasło |
| PasswordNeverExpires | Czy hasło nie wygasa |
| EmailAddress | Mail (do powiadomień) |

## 6. Lessons learned

- **LastLogonDate nie jest precyzyjny** — nie odzwierciedla logowania do Azure AD / aplikacji SaaS; przy hybrid identity rozważ też Entra sign-in logs
- **Manager lookup w pętli** — przy dużych domenach wolne; cacheuj `Get-ADUser` managera w hashtable
- **Konta bez LastLogonDate** — osobna sekcja raportu „nigdy nie logowane” zamiast mieszania z 90-day inactive
- **Automatyzacja** — zaplanuj Task Scheduler + mail z załącznikiem; raport bez wysyłki szybko się dezaktualizuje
- **Łańcuch procesu:** raport (03) → akceptacja → disable (02) → archiwum CSV jako dowód audytowy

---

### Portfolio — skrót

| | |
|---|---|
| **Problem** | Brak widoczności nieaktywnych kont przed działaniem operacyjnym |
| **Podejście** | Read-only LDAP query, CSV dla biznesu, sort po LastLogonDate |
| **Output** | CSV z managerem i metadanymi konta |
| **Bezpieczeństwo** | Tylko odczyt, brak zmian w AD, dane wewnętrzne — nie publikuj raportów z PII na GitHub |