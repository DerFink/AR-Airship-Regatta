<?php
// 2026-11-11 19:10 – Erstversion: gemeinsame Funktionen der Online-Bestenliste (Datenbank, Quartal, Prüfung der Einträge, F7B-Wertung)
// =============================================================================
// lib.php
// -----------------------------------------------------------------------------
// Wird von api.php (App/Browser) und admin.php (Verwaltung) eingebunden.
// Zugangsdaten stehen in config.php (Vorlage: config.sample.php) – diese
// Datei NIE auf GitHub hochladen.
// =============================================================================

declare(strict_types=1);

const MAX_ENTRIES = 100;      // Plätze je Strecke und Quartal
const FOREVER_KEEP = 10;      // so viele bleiben je vergangenem Quartal in „Best Forever“
const MAX_NAME = 20;
const SUBMITS_PER_HOUR = 30;  // Schutz gegen Fluten: Einträge je Gerät (IP) und Stunde

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
        ip_hash VARCHAR(16) NOT NULL)");
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

/** IP nicht im Klartext speichern – nur ein kurzer, gesalzener Hash (Schutz gegen Fluten). */
function ip_hash(): string {
    global $CFG;
    return substr(hash('sha256', ($CFG['salt'] ?? '') . ($_SERVER['REMOTE_ADDR'] ?? '')), 0, 16);
}

/**
 * Aufräumen: vergangene Quartale behalten nur ihre FOREVER_KEEP Besten je
 * Strecke („Best Forever“), alles andere wird gelöscht.
 */
function cleanup(): void {
    $pdo = db();
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
