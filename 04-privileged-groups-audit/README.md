# 04 — Audyt członkostwa w grupach uprzywilejowanych

## 1. Problem / scenariusz

Przed audytem ISO 27001 / NIS2 / wewnętrznym przeglądem trzeba wiedzieć, **kto** jest w `Domain Admins`, `Enterprise Admins`, `Backup Operators` itd. Członkostwo zmienia się ad-hoc („na chwilę”) i zostaje na lata. Pojawiają się konta osób, które już nie pracują w IT, lub użytkownicy z włączonym hasłem bez wygaśnięcia.

**Cel:** pełny raport CSV + podsumowanie liczebności per grupa — bez modyfikacji członkostwa.

## 2. Diagnoza krok po kroku

1. Lista grup uprzywilejowanych — zgodna z CIS / Microsoft Tiering Model
2. `Get-ADGroupMember -Recursive` — uwzględnij zagnieżdżone grupy (user w grupie A, A w Domain Admins)
3. Dla każdego usera: `Enabled`, `LastLogonDate`, `PasswordNeverExpires`
4. Porównaj z poprzednim audytem — nowi członkowie, konta disabled nadal w grupie
5. Sprawdź konta bez logowania > 90 dni w grupach admin — kandydaci do usunięcia
6. Eskaluj do CISO / IT Manager — decyzja poza skryptem

## 3. Root cause

- Brak procesu PAM / just-in-time admin — stałe członkostwo w Domain Admins
- „Tymczasowe” dodanie do grupy bez terminu ważności i bez wpisu w change log
- Zagnieżdżone grupy — nikt nie widzi efektywnego członkostwa bez `-Recursive`
- Audyt ręczny w MMC — czasochłonny, podatny na przeoczenia

## 4. Fix / rozwiązanie

1. Zdefiniowana lista 8 grup uprzywilejowanych (builtin + krytyczne)
2. Skrypt iteruje po grupach, pobiera członków rekurencyjnie, wzbogaca o atrybuty usera
3. Eksport CSV + `Group-Object` — podsumowanie na konsoli
4. Kwartalny przegląd z właścicielem bezpieczeństwa
5. Dla każdego zbędnego członka: ticket + usunięcie z grupy + wpis w rejestrze zmian

Grupy w skrypcie:
- Domain Admins, Enterprise Admins, Schema Admins
- Group Policy Creator Owners
- Administrators, Account Operators, Backup Operators, Server Operators

## 5. Skrypt / kod

| Plik | Opis |
|------|------|
| [Get-PrivilegedGroupsAudit.ps1](./Get-PrivilegedGroupsAudit.ps1) | Audyt + CSV + podsumowanie |

```powershell
Import-Module ActiveDirectory

.\Get-PrivilegedGroupsAudit.ps1
# opcjonalnie: -LogDir "D:\Reports\AD"
```

**Output:** `C:\Logs\privileged_audit_YYYYMMDD.csv`

| Kolumna | Znaczenie |
|---------|-----------|
| Group | Nazwa grupy uprzywilejowanej |
| SamAccountName | Login |
| DisplayName | Imię i nazwisko |
| Enabled | Czy konto aktywne |
| LastLogonDate | Ostatnie logowanie |
| PasswordNeverExpires | Ryzyko: hasło bez rotacji |
| Email | Kontakt |
| AuditDate | Data audytu |

**Podsumowanie na konsoli:**
```
Name                  Count
----                  -----
Domain Admins             5
Backup Operators          3
...
```

## 6. Lessons learned

- **Recursive jest kluczowe** — bez `-Recursive` przegapisz użytkowników w zagnieżdżonych grupach
- **Enterprise Admins** — w multi-domain forest; w single-domain może być pusta — `try/catch` już w skrypcie
- **Tier 0/1/2** — rozszerz listę o własne grupy (`G-Admin-Tier0`, `G-Server-Admins`)
- **Raport ≠ remediacja** — skrypt nie usuwa członkostwa; decyzja i zmiana to osobny, zatwierdzony proces
- **Następny krok:** PIM (Entra ID PIM / CyberArk), time-bound membership, alert przy `Add-ADGroupMember` do Domain Admins (DSC / SIEM)

---

### Portfolio — skrót

| | |
|---|---|
| **Problem** | Niekontrolowane członkostwo w grupach wysokich uprawnień |
| **Podejście** | Rekurencyjny audit 8 grup builtin, wzbogacenie o stan konta |
| **Output** | CSV + tabela Count per grupa |
| **Bezpieczeństwo** | Read-only, uruchamiaj z jump hosta, raporty z PII tylko wewnętrznie, kwartalna cadence |