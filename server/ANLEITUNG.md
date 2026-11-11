<!-- 2026-11-11 20:30 – Erstversion: RC Airship Regatta auf flinkfink.de/rc-airship/ (Browser-Version, Online-Bestenliste, Verwaltung) -->
# RC Airship Regatta auf flinkfink.de

Ziel: `https://flinkfink.de/rc-airship/` startet den Simulator im Browser,
`api.php` ist die Online-Bestenliste, `admin.php` die Verwaltung.

## Einmalig einrichten

1. **SSL**: Strato-Kundenlogin → Sicherheit → SSL-Verwaltung → Zertifikat `flinkfink.de` zuweisen,
   HTTPS-Weiterleitung einschalten.
2. **Datenbank**: Kundenlogin → Datenbanken → „Datenbank anlegen“ (MySQL).
   Notieren: Server (Host), Datenbankname, Benutzer, Passwort.
3. **Paket holen**: Im neuesten GitHub-Release die Datei `rc-airship-web.zip` herunterladen
   und entpacken (Browser-Version + `api.php`, `admin.php`, `lib.php`, `models.json`, `.htaccess`).
4. **Hochladen**: Mit WinSCP (SFTP) den Inhalt in den Ordner `rc-airship` auf dem Webspace legen.
   In WinSCP „Versteckte Dateien anzeigen“ einschalten, damit `.htaccess` mitkommt.
5. **config.php anlegen**: `config.sample.php` auf dem Server kopieren → `config.php`, ausfüllen:
   - `dsn`: `mysql:host=<Host>;dbname=<Datenbankname>;charset=utf8mb4`
   - `db_user`, `db_pass`
   - `admin_hash`: Hash deines Admin-Passworts. Erzeugen z. B. lokal mit
     `php -r 'echo password_hash("DEIN-PASSWORT", PASSWORD_DEFAULT), "\n";'`
     (oder Claude fragen – dann aber ein Passwort nehmen, das du sonst nirgends nutzt).
   - `salt`: beliebiger langer Zufallstext.
   Die Tabelle legt `api.php` beim ersten Aufruf selbst an.
6. **Testen**:
   - `https://flinkfink.de/rc-airship/` → Simulator startet.
   - `https://flinkfink.de/rc-airship/api.php?action=list&course=cup` → `{"ok":true,...}`.
   - `https://flinkfink.de/rc-airship/admin.php` → Anmeldung mit dem Admin-Passwort.

## Neue Versionen

- **Von Hand**: neues `rc-airship-web.zip` aus dem Release hochladen (config.php bleibt).
- **Automatisch** (empfohlen): Auf GitHub unter Settings → Secrets and variables → Actions
  - Secrets: `STRATO_SFTP_HOST` (z. B. `ssh.strato.de`), `STRATO_SFTP_USER`, `STRATO_SFTP_PASS`
  - Variable: `STRATO_UPLOAD` = `ja`
  Dann lädt jeder Build die Browser-Version und die Bestenliste selbst hoch.

## Standardmodelle geändert?

Nur unveränderte Standardmodelle werden online gewertet (Fingerabdruck in `models.json`).
Nach Änderungen an Chewie/Albacore oder der Sammlung:
`godot --headless --path . -s tools/export_server_models.gd` und `models.json` neu hochladen
(beim automatischen Hochladen passiert das mit dem nächsten Build).

## Verwaltung

`admin.php`: Einträge aller Strecken und Quartale ansehen, einzelne Einträge löschen oder
einen Piloten komplett streichen (z. B. wenn jemand nicht mehr in der Liste stehen möchte).

## Datenschutz

Gespeichert werden Name (frei gewählt), Luftschiff, Zeiten, Datum, „gespielt mit“, App-Version
und ein gekürzter, gesalzener Hash der IP-Adresse (nur gegen Fluten, nicht rückrechenbar).
Für die Seite braucht es ein Impressum und eine kurze Datenschutzerklärung.
