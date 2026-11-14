<?php
// 2026-11-14 21:40 – Einwilligung (CONSENT_VERSION), Geräte-Kennung zum Selbstlöschen, Speicherdauer 2 Jahre, Besucherzähler (Tag/Plattform), Sperre nach 5 falschen Admin-Passwörtern, keine Fehlerausgabe, Hinweis ohne config.php
// 2026-11-11 19:10 – Erstversion: gemeinsame Funktionen der Online-Bestenliste (Datenbank, Quartal, Prüfung der Einträge, F7B-Wertung)
// =============================================================================
// lib.php
// -----------------------------------------------------------------------------
// Wird von api.php (App/Browser) und admin.php (Verwaltung) eingebunden.
// Zugangsdaten stehen in config.php (Vorlage: config.sample.php) – diese
// Datei NIE auf GitHub hochladen.
// =============================================================================

declare(strict_types=1);

// Fehlermeldungen nie an Besucher ausgeben (könnten Pfade oder Datenbankdetails zeigen)
ini_set('display_errors', '0');

const MAX_ENTRIES = 100;      // Plätze je Strecke und Quartal
const FOREVER_KEEP = 10;      // so viele bleiben je vergangenem Quartal in „Best Forever“
const MAX_NAME = 20;
const SUBMITS_PER_HOUR = 30;  // Schutz gegen Fluten: Einträge je Gerät (IP) und Stunde
const CONSENT_VERSION = 1;    // Fassung des Einwilligungstextes in der App (bei neuer Fassung erhöhen – App und Server gemeinsam)
const KEEP_DAYS = 730;        // Speicherdauer der Einträge: 2 Jahre, danach automatisch gelöscht (steht so in der Datenschutzerklärung)
const LOGIN_TRIES = 5;        // Admin-Anmeldung: so viele Fehlversuche …
const LOGIN_LOCK_MIN = 15;    // … sperren die Anmeldung für so viele Minuten (je IP-Hash)
const PLATFORMS = ['android', 'ios', 'web', 'pc', 'sonstige'];   // erlaubte Werte im Besucherzähler

if (!is_file(__DIR__ . '/config.php')) {
    // Noch nicht eingerichtet → zur Einrichtungsseite (nur solange config.php fehlt)
    http_response_code(503);
    exit('Noch nicht eingerichtet – bitte einrichtung.php aufrufen.');
}

$CFG = require __DIR__ . '/config.php';

/** Datenbankverbindung (MySQL bei Strato, SQLite für Tests). Tabellen werden bei Bedarf angelegt. */
function db(): PDO {
    static $pdo = null;
    global $CFG;
    if ($pdo) return $pdo;
    $pdo = new PDO($CFG['dsn'], $CFG['db_user'] ?? null, $CFG['db_pass'] ?? null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    $auto = str_starts_with($CFG['dsn'], 'sqlite') ? 'INTEGER PRIMARY KEY AUTOINCREMENT' : 'INT AUTO_INCREMENT PRIMARY KEY';
    $pdo->exec("CREATE TABLE IF NOT EXISTS entries (
        id $auto,
        quarter VARCHAR(6) NOT NULL,
        course VARCHAR(40) NOT NULL,
        name VARCHAR(40) NOT NULL,
        model VARCHAR(40) NOT NULL,
        total DOUBLE NOT NULL,
        lap1 DOUBLE NOT NULL, lap2 DOUBLE NOT NULL, lap3 DOUBLE NOT NULL,
        score DOUBLE NOT NULL,
        platform VARCHAR(40) NOT NULL,
        version VARCHAR(20) NOT NULL,
        created VARCHAR(19) NOT NULL,
        ip_hash VARCHAR(16) NOT NULL,
        device_hash VARCHAR(16) NOT NULL DEFAULT '',
        consent INT NOT NULL DEFAULT 0)");
    // ältere Tabelle (vor 0.34) um Geräte-Kennung und Einwilligung ergänzen
    try { $pdo->query("SELECT device_hash, consent FROM entries LIMIT 1"); }
    catch (Throwable $e) {
        $pdo->exec("ALTER TABLE entries ADD COLUMN device_hash VARCHAR(16) NOT NULL DEFAULT ''");
        $pdo->exec("ALTER TABLE entries ADD COLUMN consent INT NOT NULL DEFAULT 0");
    }
    // Besucherzähler: nur Tag, Plattform und Anzahl – keine IP, keine Kennung
    $pdo->exec("CREATE TABLE IF NOT EXISTS hits (
        day VARCHAR(10) NOT NULL,
        platform VARCHAR(20) NOT NULL,
        n INT NOT NULL DEFAULT 0,
        PRIMARY KEY (day, platform))");
    // Fehlversuche bei der Admin-Anmeldung (gesalzener IP-Hash, Zeitpunkt)
    $pdo->exec("CREATE TABLE IF NOT EXISTS login_fail (
        ip_hash VARCHAR(16) NOT NULL,
        ts INT NOT NULL)");
    return $pdo;
}

/** Quartal eines Zeitpunkts, z. B. "2026Q4". */
function quarter_of(int $ts): string {
    return gmdate('Y', $ts) . 'Q' . (intdiv((int)gmdate('n', $ts) - 1, 3) + 1);
}

/** Letzter Tag des laufenden Quartals (für „noch … Tage“). */
function quarter_end(int $ts): int {
    $y = (int)gmdate('Y', $ts);
    $q = intdiv((int)gmdate('n', $ts) - 1, 3) + 1;
    return gmmktime(0, 0, 0, $q * 3 + 1, 1, $y) - 1;
}

/** Erlaubte Strecken: Cup, freie Strecke und Wiese mit Abstand. */
function valid_course(string $c): bool {
    return (bool)preg_match('/^(cup|frei_\d{1,3}\.\d|wiese_\d{1,3}\.\d)$/', $c);
}

/** Standardmodelle (nur diese werden gewertet): Fingerabdruck → Name, Boxmaß. */
function models(): array {
    static $m = null;
    if ($m === null) $m = json_decode((string)file_get_contents(__DIR__ . '/models.json'), true) ?: [];
    return $m;
}

/** F7B-Wertung: Gesamtzeit × (L·B·H·π/6)^(1/3). */
function scored(float $total, array $box): float {
    $v = $box[0] * $box[1] * $box[2] * M_PI / 6.0;
    return $total * pow(max($v, 1e-6), 1.0 / 3.0);
}

/** Name säubern: keine Steuerzeichen, Leerraum zusammenfassen, höchstens MAX_NAME Zeichen. */
function clean_name(string $n): string {
    $n = preg_replace('/[\p{C}<>]/u', '', $n) ?? '';
    $n = trim(preg_replace('/\s+/u', ' ', $n) ?? '');
    return mb_substr($n, 0, MAX_NAME);
}

/** Geräte-Kennung der App (Zufallswert) nur gesalzen und gekürzt speichern; leer, wenn ungültig. */
function device_hash(string $device): string {
    global $CFG;
    if (!preg_match('/^[0-9a-f]{16,64}$/', $device)) return '';
    return substr(hash('sha256', 'dev' . ($CFG['salt'] ?? '') . $device), 0, 16);
}

/** Besucherzähler: Aufruf der App/Seite an diesem Tag für die Plattform +1. */
function count_hit(string $platform): void {
    $p = in_array($platform, PLATFORMS, true) ? $platform : 'sonstige';
    $pdo = db();
    $day = gmdate('Y-m-d');
    if ($pdo->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite')
        $st = $pdo->prepare("INSERT INTO hits (day, platform, n) VALUES (?, ?, 1) ON CONFLICT(day, platform) DO UPDATE SET n = n + 1");
    else
        $st = $pdo->prepare("INSERT INTO hits (day, platform, n) VALUES (?, ?, 1) ON DUPLICATE KEY UPDATE n = n + 1");
    $st->execute([$day, $p]);
}

/** Admin-Anmeldung gesperrt? (zu viele Fehlversuche von dieser IP in LOGIN_LOCK_MIN Minuten) */
function login_locked(): bool {
    $pdo = db();
    $pdo->prepare("DELETE FROM login_fail WHERE ts < ?")->execute([time() - LOGIN_LOCK_MIN * 60]);
    $c = $pdo->prepare("SELECT COUNT(*) AS n FROM login_fail WHERE ip_hash = ?");
    $c->execute([ip_hash()]);
    return (int)$c->fetch()['n'] >= LOGIN_TRIES;
}

/** Fehlversuch merken. */
function login_failed(): void {
    db()->prepare("INSERT INTO login_fail (ip_hash, ts) VALUES (?, ?)")->execute([ip_hash(), time()]);
}

/** IP nicht im Klartext speichern – nur ein kurzer, gesalzener Hash (Schutz gegen Fluten). */
function ip_hash(): string {
    global $CFG;
    return substr(hash('sha256', ($CFG['salt'] ?? '') . ($_SERVER['REMOTE_ADDR'] ?? '')), 0, 16);
}

/**
 * Aufräumen: Einträge älter als 2 Jahre löschen; vergangene Quartale behalten
 * nur ihre FOREVER_KEEP Besten je Strecke („Best Forever“), alles andere wird
 * gelöscht.
 */
function cleanup(): void {
    $pdo = db();
    // Speicherdauer: Einträge älter als KEEP_DAYS werden gelöscht (auch „Best Forever“)
    $pdo->prepare("DELETE FROM entries WHERE created < ?")->execute([gmdate('Y-m-d H:i:s', time() - KEEP_DAYS * 86400)]);
    $cur = quarter_of(time());
    $rows = $pdo->query("SELECT DISTINCT quarter, course FROM entries WHERE quarter <> " . $pdo->quote($cur))->fetchAll();
    foreach ($rows as $r) {
        $keep = $pdo->prepare("SELECT id FROM entries WHERE quarter = ? AND course = ? ORDER BY score ASC, id ASC LIMIT " . FOREVER_KEEP);
        $keep->execute([$r['quarter'], $r['course']]);
        $ids = array_map('intval', array_column($keep->fetchAll(), 'id'));
        if (!$ids) continue;
        $del = $pdo->prepare("DELETE FROM entries WHERE quarter = ? AND course = ? AND id NOT IN (" . implode(',', $ids) . ")");
        $del->execute([$r['quarter'], $r['course']]);
    }
}

/** Eintrag für die Ausgabe (ohne IP-Hash). */
function public_row(array $r, int $rank): array {
    return [
        'rank' => $rank, 'id' => (int)$r['id'], 'name' => $r['name'], 'model' => $r['model'],
        'total' => (float)$r['total'], 'laps' => [(float)$r['lap1'], (float)$r['lap2'], (float)$r['lap3']],
        'score' => (float)$r['score'], 'platform' => $r['platform'], 'date' => substr($r['created'], 0, 10),
    ];
}
