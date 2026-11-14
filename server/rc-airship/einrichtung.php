<?php
// 2026-11-14 21:50 – Erstversion: Einrichtung im Browser – Datenbank-Zugang und Admin-Passwort eingeben, Verbindung wird geprüft, config.php wird angelegt; danach ist die Seite gesperrt
// =============================================================================
// einrichtung.php  –  https://flinkfink.de/rc-airship/einrichtung.php
// -----------------------------------------------------------------------------
// Nur solange es KEINE config.php gibt:
//   1. Formular: Datenbank (Host, Name, Benutzer, Passwort) und Admin-Passwort
//   2. Verbindung zur Datenbank wird getestet
//   3. config.php wird geschrieben – mit Passwort-Hash (nie das Passwort selbst)
//      und einem zufälligen Salt für die gekürzten IP-/Geräte-Hashes
// Sobald config.php existiert, zeigt die Seite nur noch „bereits eingerichtet“
// und nimmt keine Eingaben mehr an. Zum Neu-Einrichten config.php per WinSCP
// löschen.
// =============================================================================

declare(strict_types=1);
ini_set('display_errors', '0');
header('Content-Type: text/html; charset=utf-8');
header('X-Frame-Options: DENY');
header('Cache-Control: no-store');

$cfg_file = __DIR__ . '/config.php';
$done = is_file($cfg_file);
$err = '';
$ok = false;

function h(string $s): string { return htmlspecialchars($s, ENT_QUOTES, 'UTF-8'); }

// --- Formular auswerten (nur ohne config.php) ---------------------------------
if (!$done && ($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    $host = trim((string)($_POST['host'] ?? ''));
    $name = trim((string)($_POST['dbname'] ?? ''));
    $user = trim((string)($_POST['user'] ?? ''));
    $pass = (string)($_POST['pass'] ?? '');
    $pw1 = (string)($_POST['pw1'] ?? '');
    $pw2 = (string)($_POST['pw2'] ?? '');
    if ($host === '' || $name === '' || $user === '') {
        $err = 'Bitte Host, Datenbankname und Benutzer ausfüllen.';
    } elseif (!preg_match('/^[A-Za-z0-9._-]+(:\d+)?$/', $host) || !preg_match('/^[A-Za-z0-9_-]+$/', $name)) {
        $err = 'Host oder Datenbankname enthält ungültige Zeichen.';
    } elseif (strlen($pw1) < 12) {
        $err = 'Das Admin-Passwort muss mindestens 12 Zeichen lang sein.';
    } elseif ($pw1 !== $pw2) {
        $err = 'Die beiden Admin-Passwörter stimmen nicht überein.';
    } else {
        // Datenbank-Verbindung prüfen, bevor etwas gespeichert wird
        $dsn = "mysql:host=$host;dbname=$name;charset=utf8mb4";
        try {
            new PDO($dsn, $user, $pass, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 8]);
        } catch (Throwable $e) {
            $err = 'Keine Verbindung zur Datenbank. Bitte Host, Datenbankname, Benutzer und Passwort prüfen (Strato-Kundenlogin → Datenbanken).';
        }
        if ($err === '') {
            $cfg = [
                'dsn'        => $dsn,
                'db_user'    => $user,
                'db_pass'    => $pass,
                'admin_hash' => password_hash($pw1, PASSWORD_DEFAULT),   // nur der Hash wird gespeichert
                'salt'       => bin2hex(random_bytes(24)),               // zufällig, nie ändern (sonst passen die Hashes nicht mehr)
            ];
            $php = "<?php\n// Angelegt von einrichtung.php am " . gmdate('Y-m-d H:i') . " UTC – NIE auf GitHub hochladen.\nreturn "
                 . var_export($cfg, true) . ";\n";
            // exklusiv anlegen: schlägt fehl, falls config.php inzwischen existiert
            $fh = @fopen($cfg_file, 'x');
            if ($fh === false) {
                $err = 'config.php konnte nicht angelegt werden (Schreibrechte im Ordner prüfen) – oder sie existiert bereits.';
            } else {
                fwrite($fh, $php);
                fclose($fh);
                @chmod($cfg_file, 0600);                                   // nur für den Webserver lesbar
                $ok = true;
                $done = true;
            }
        }
    }
}
?><!doctype html>
<html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>RC Airship Regatta – Einrichtung</title>
<style>
 body{font-family:system-ui,sans-serif;background:#0b0f14;color:#e9eef3;margin:0;padding:16px}
 main{max-width:560px;margin:0 auto} .box{background:#161c23;border:1px solid #ffffff22;border-radius:12px;padding:16px;margin-bottom:16px}
 label{display:block;margin:10px 0 4px;color:#9aa7b4} input{font:inherit;width:100%;box-sizing:border-box;padding:8px 10px;border-radius:8px;border:1px solid #ffffff33;background:#222a33;color:#e9eef3}
 button{font:inherit;margin-top:16px;padding:10px 16px;border-radius:8px;border:2px solid #3d8bfd;background:#1d3354;color:#fff}
 .err{color:#ff9a9a} .ok{color:#3fb27f} a{color:#3d8bfd} small{color:#9aa7b4}
</style></head><body><main>
<h1>Einrichtung</h1>
<?php if ($ok): ?>
 <div class="box"><p class="ok"><b>Fertig!</b> config.php wurde angelegt, die Datenbank ist erreichbar.</p>
 <p>Diese Seite ist ab jetzt gesperrt. Weiter mit dem Test:</p>
 <p><a href="api.php?action=list&amp;course=cup">Bestenliste testen</a> · <a href="admin.php">Verwaltung (admin.php)</a> · <a href="./">Simulator</a></p></div>
<?php elseif ($done): ?>
 <div class="box"><p>Bereits eingerichtet. Zum Neu-Einrichten zuerst <code>config.php</code> per WinSCP löschen.</p>
 <p><a href="admin.php">Zur Verwaltung</a></p></div>
<?php else: ?>
 <?php if ($err): ?><p class="err"><?= h($err) ?></p><?php endif; ?>
 <form method="post" class="box" autocomplete="off">
  <h2>1. Datenbank</h2>
  <small>Steht im Strato-Kundenlogin unter „Datenbanken“ bei deiner Datenbank.</small>
  <label>Host (Datenbank-Server)</label><input name="host" value="<?= h((string)($_POST['host'] ?? '')) ?>" placeholder="z. B. database-5012345678.webspace-host.com">
  <label>Datenbankname</label><input name="dbname" value="<?= h((string)($_POST['dbname'] ?? '')) ?>" placeholder="z. B. dbs12345678">
  <label>Benutzer</label><input name="user" value="<?= h((string)($_POST['user'] ?? '')) ?>" placeholder="z. B. dbu1234567">
  <label>Datenbank-Passwort</label><input name="pass" type="password">
  <h2>2. Admin-Passwort</h2>
  <small>Für admin.php. Mindestens 12 Zeichen, nirgends sonst verwendet. Gespeichert wird nur ein Hash.</small>
  <label>Admin-Passwort</label><input name="pw1" type="password" autocomplete="new-password">
  <label>Admin-Passwort wiederholen</label><input name="pw2" type="password" autocomplete="new-password">
  <button>Prüfen und einrichten</button>
 </form>
<?php endif; ?>
</main></body></html>
