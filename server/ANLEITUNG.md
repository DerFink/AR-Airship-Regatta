<!-- 2026-11-14 23:20 – Neu geschrieben für Einsteiger: Strato Schritt für Schritt (SSL, Datenbank, PHP, Domain-Ziel, SFTP, AV-Vertrag), WinSCP von Grund auf, Einrichtung im Browser (einrichtung.php), Prüfliste vor der Ankündigung, automatische Updates, Fehlerhilfe -->
<!-- 2026-11-11 20:30 – Erstversion: RC Airship Regatta auf flinkfink.de/rc-airship/ (Browser-Version, Online-Bestenliste, Verwaltung) -->
# RC Airship Regatta online stellen – Strato und WinSCP Schritt für Schritt

**Ziel:**
- `https://flinkfink.de/rc-airship/` startet den Simulator im Browser.
- `admin.php` ist deine Verwaltung (Bestenliste, Aufrufe).
- Die App trägt ihre Zeiten dort ein.

**Zeitbedarf:** etwa 45 Minuten beim ersten Mal.

**Du brauchst:**
- deine Strato-Kundennummer und dein Kundenpasswort,
- einen Windows-PC,
- ein neues Admin-Passwort mit mindestens 12 Zeichen, das du nirgends sonst benutzt (in einen Passwort-Manager oder auf Papier).

> Die Menünamen bei Strato ändern sich ab und zu. Wenn ein Punkt anders heißt, hilft die Suche in der Strato-Hilfe mit dem fett gedruckten Begriff.

---

## Teil A – Einstellungen im Strato-Kundenlogin

Melde dich unter **strato.de → Login** an und klicke bei deinem Hosting-Paket auf **„Ihr Paket“**. Alle folgenden Punkte findest du im linken Menü dieses Pakets.

### A1. SSL (verschlüsselte Verbindung, „https“)
1. **Sicherheit → STRATO SSL** (oder in der Paketübersicht „SSL verwalten“).
2. **Zuweisen** → Domain `flinkfink.de` wählen → **Domain zuweisen**. Das kann ein paar Minuten dauern.
3. Wenn das Zertifikat als aktiv angezeigt wird: in der Spalte „Aktionen“ **SSL erzwingen** → **permanent** → **Speichern**.

   Damit wird `http://` automatisch zu `https://`.
4. Für `www.flinkfink.de` dasselbe machen, falls sie in der Liste steht.

### A2. PHP-Version
1. **Datenbanken und Webspace → PHP-Version einstellen**.
2. Die **neueste PHP-8-Version** wählen (8.2 oder höher) → speichern.

### A3. Datenbank anlegen
1. **Datenbanken und Webspace → Datenbankverwaltung → Datenbank anlegen**.
2. Typ **MySQL 8**, Kommentar z. B. `rc-airship`, ein **neues Passwort** vergeben → **Datenbank anlegen**.
3. Notiere dir diese vier Angaben; du brauchst sie in Teil C:

| Angabe | Wo steht sie? | Beispiel |
|---|---|---|
| **Host** | bei der Datenbank rechts **⋮ → Details → Server** | `database-5012345678.webspace-host.com` |
| **Datenbankname** | in der Übersicht | `dbs12345678` |
| **Benutzer** | in der Übersicht | `dbu1234567` |
| **Passwort** | hast du eben selbst vergeben | – |

### A4. Wohin zeigt deine Domain? (wichtig!)
1. In der Paketübersicht **[…] → Domains verwalten** → bei `flinkfink.de` auf das **Zahnrad** klicken.
2. Dort steht das **Ziel**:
   - **„/“** (Standard): Der Ordner `rc-airship` kommt in Teil B direkt in die oberste Ebene.
   - **ein Unterordner**, z. B. `/flinkfink`: Der Ordner `rc-airship` kommt **in diesen Unterordner**. Merk dir den Namen, du brauchst ihn in Teil B und in Teil E.
3. Hier nichts ändern, nur nachsehen.

### A5. SFTP-Zugang (für WinSCP)
1. **Datenbanken und Webspace → SFTP & SSH**.
2. Rechts in der Infobox steht der **Servername**, z. B. `5012345603.ssh.w2.strato.hosting`, dazu Port **22**.
3. In der Liste steht dein **Benutzername**, z. B. `su123456`.
4. Kennst du das Passwort nicht: **⋮ → Passwort ändern**.
5. Notiere Servername, Benutzername und Passwort.

### A6. Vertrag zur Auftragsverarbeitung (Datenschutz)
1. Im Kundenlogin links: **Ihre Kundendaten → Auftragsverarbeitung**.
2. Den Vertrag ausfüllen und abschließen, das PDF speichern.

Dieser Vertrag wird in der Datenschutzerklärung erwähnt und muss deshalb abgeschlossen sein.

---

## Teil B – WinSCP: Dateien hochladen

WinSCP ist ein kostenloses Programm, das Dateien von deinem PC auf den Webspace kopiert. Links siehst du deinen PC, rechts den Server, und du ziehst Dateien von links nach rechts.

### B1. WinSCP installieren
1. **winscp.net** öffnen → **Download** → „Installation package“.

   Nur von dieser Seite laden; es gibt viele gefälschte Download-Seiten.
2. Installieren und dabei die Vorgaben übernehmen. Bei der Frage nach der Oberfläche **„Commander“** wählen (zwei Spalten).

### B2. Paket holen
1. github.com/DerFink/AR-Airship-Regatta → rechts **Releases** → oberster Eintrag.
2. **`rc-airship-web.zip`** herunterladen.
3. Die ZIP-Datei mit Rechtsklick → **Alle extrahieren …** entpacken. Du bekommst einen Ordner `rc-airship-web` mit mehreren Dateien, darunter `index.html`, `api.php`, `admin.php`, `einrichtung.php`, `impressum.html` und `datenschutz.html`.

### B3. Verbindung einrichten
1. WinSCP starten. Es öffnet sich das Fenster **„Anmeldung“**.
2. Links **„Neues Verbindungsziel“** markieren und rechts ausfüllen:

| Feld | Eintrag |
|---|---|
| Übertragungsprotokoll | **SFTP** |
| Rechnername | Servername aus A5 |
| Portnummer | **22** |
| Benutzername | Benutzername aus A5 |
| Kennwort | SFTP-Passwort aus A5 |

3. **Speichern** → Name `Strato flinkfink` → OK.
4. **Anmelden**.
5. Beim ersten Mal fragt WinSCP, ob du dem **Server-Schlüssel** vertraust. Wenn der Servername stimmt: **Akzeptieren** bzw. **Ja**.

### B4. Versteckte Dateien sichtbar machen
Die Datei `.htaccess` beginnt mit einem Punkt und ist deshalb versteckt. Sie **muss** mit hoch, denn sie schützt deine Zugangsdaten.
- Menü **Optionen → Einstellungen → Panels** → Haken bei **„Versteckte Dateien anzeigen“** → OK.
- Oder kurz: **Strg + Alt + H**.

### B5. Ordner anlegen und hochladen
1. **Rechte Seite (Server):** Du bist im obersten Ordner „/“.
   - Hat deine Domain in A4 einen Unterordner als Ziel: erst diesen Unterordner mit Doppelklick öffnen.
   - Dann **F7** drücken (oder Rechtsklick → Neu → Verzeichnis), Name **`rc-airship`** → OK.
   - Den neuen Ordner mit Doppelklick öffnen.
2. **Linke Seite (PC):** Zum entpackten Ordner `rc-airship-web` gehen und ihn öffnen. Du siehst jetzt `index.html` usw.
3. Links **Strg + A** (alles markieren) und alles nach **rechts ziehen** → **Hochladen**.
4. Prüfen: Rechts muss **`.htaccess`** dabei sein. Fehlt sie, B4 erledigen und `.htaccess` einzeln hochziehen.

---

## Teil C – Einrichtung im Browser

1. Im Browser **`https://flinkfink.de/rc-airship/einrichtung.php`** öffnen.
2. Ausfüllen:
   - **Datenbank:** Host, Datenbankname, Benutzer und Passwort aus A3.
   - **Admin-Passwort:** dein neues Passwort, zweimal.
3. **Prüfen und einrichten**. Die Seite testet die Datenbank und legt die Datei `config.php` selbst an. Gespeichert wird nur ein Hash deines Passworts, nicht das Passwort selbst.
4. Erscheint **„Fertig!“**, ist die Seite ab jetzt gesperrt.
5. Bei **„Keine Verbindung zur Datenbank“**: die Angaben aus A3 prüfen. Besonders der Host wird gern verwechselt; er steht unter **⋮ → Details**. Ist die Datenbank gerade erst angelegt, ein paar Minuten warten.

---

## Teil D – Prüfliste vor der Ankündigung

Alles im Browser aufrufen und das Ergebnis vergleichen:

| Adresse | richtig ist |
|---|---|
| `https://flinkfink.de/rc-airship/` | Simulator lädt (beim ersten Mal etwas warten) |
| `http://flinkfink.de/rc-airship/` (ohne s) | springt auf `https://` |
| `https://flinkfink.de/rc-airship/api.php?action=list&course=cup` | Text beginnt mit `{"ok":true` |
| `https://flinkfink.de/rc-airship/admin.php` | Anmeldung → mit Admin-Passwort hinein, „Aufrufe“ zählt |
| `https://flinkfink.de/rc-airship/config.php` | **403 Forbidden** (sonst sofort melden!) |
| `https://flinkfink.de/rc-airship/lib.php` | **403 Forbidden** |
| `https://flinkfink.de/rc-airship/models.json` | **403 Forbidden** |
| `https://flinkfink.de/rc-airship/impressum.html` | Impressum |
| `https://flinkfink.de/rc-airship/datenschutz.html` | Datenschutzerklärung |

Danach:
1. **In der App** (neueste APK) ein Rennen fliegen, eintragen, einwilligen. Dein Eintrag erscheint in der Bestenliste und blinkt kurz auf.
2. Unter **Einstellungen → Meine Online-Einträge löschen** zweimal tippen. Die App meldet, wie viele Online-Einträge gelöscht wurden.
3. **Auf dem Handy im Browser** (Safari auf dem iPhone, Chrome auf Android) die Seite öffnen und kurz fliegen.
4. Den **PayPal-Knopf** in der App testen. Er öffnet paypal.me/LuftschiffFink.

---

## Teil E – Updates automatisch hochladen (optional, empfohlen)

Dann musst du nie wieder WinSCP öffnen: Jeder neue Build auf GitHub lädt die Browser-Version und den Server-Teil selbst hoch. `config.php` und die Datenbank bleiben dabei unangetastet.

1. Auf GitHub im Projekt: **Settings → Secrets and variables → Actions**.
2. Reiter **Secrets** → **New repository secret**, dreimal:

| Name | Wert |
|---|---|
| `STRATO_SFTP_HOST` | Servername aus A5 |
| `STRATO_SFTP_USER` | Benutzername aus A5 |
| `STRATO_SFTP_PASS` | SFTP-Passwort aus A5 |

3. Reiter **Variables** → **New repository variable**:
   - `STRATO_UPLOAD` = `ja`
   - nur wenn deine Domain in A4 auf einen Unterordner zeigt: `STRATO_ZIEL` = `<Unterordner>/rc-airship`, z. B. `flinkfink/rc-airship`.

> **Achtung:** Der automatische Upload gleicht den Ordner `rc-airship` mit dem Paket ab. Dateien, die du dort zusätzlich von Hand ablegst, **löscht er** beim nächsten Mal; nur `config.php` bleibt. Eigene Dateien also außerhalb von `rc-airship` ablegen oder mir schicken, dann kommen sie ins Paket.

---

## Hilfe bei Problemen

| Problem | Lösung |
|---|---|
| Seite zeigt „Noch nicht eingerichtet“ | Teil C ausführen |
| Simulator bleibt schwarz | Anderen Browser probieren; sehr alte Handys können WebGL 2 nicht |
| Strato-Standardseite statt Simulator | In A4 nachsehen, ob der Ordner am richtigen Ort liegt |
| `config.php` zeigt nicht „403“ | `.htaccess` fehlt → B4 und B5 wiederholen |
| Admin: „Zu viele Fehlversuche“ | 15 Minuten warten (Schutz gegen Passwort-Raten) |
| Admin-Passwort vergessen | Mit WinSCP `config.php` löschen und Teil C wiederholen; die Bestenliste bleibt erhalten |
| App: Online-Liste bleibt leer | Teil D prüfen; ohne Netz zeigt die App die Liste des Geräts |

## Verwaltung

`admin.php` bietet:
- **Aufrufe:** heute, 30 Tage, insgesamt, nach Plattform.
- **Einträge aller Strecken und Quartale:** einzelne Einträge löschen oder einen Piloten komplett streichen, z. B. wenn jemand per E-Mail um Löschung bittet.

## Datenschutz kurz

Gespeichert werden nur mit Einwilligung in der App:
- der frei gewählte Name,
- Luftschiff, Zeiten, Datum, App-Version,
- ein gekürzter, gesalzener Hash der IP-Adresse und der Geräte-Kennung.

Die Einträge werden nach **2 Jahren** automatisch gelöscht. Der Besucherzähler speichert nur Tag, Plattform und Anzahl. Die Einzelheiten stehen in `datenschutz.html`.
