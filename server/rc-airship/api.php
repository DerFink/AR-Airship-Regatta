<?php
// 2026-11-11 19:10 – Erstversion: Schnittstelle der Online-Bestenliste für App und Browser
// =============================================================================
// api.php  –  https://flinkfink.de/rc-airship/api.php
// -----------------------------------------------------------------------------
//   GET  ?action=list&course=cup     → laufendes Quartal, beste gewertete Zeit zuerst (max. 100)
//   GET  ?action=forever&course=cup  → vergangene Quartale, je die 10 Besten
//   POST action=submit (JSON)        → Rennen eintragen; Antwort: Platz und id
//        {"course","name","fp","total","laps":[3],"platform","version"}
// Gewertet werden nur unveränderte Standardmodelle (Fingerabdruck fp aus
// models.json); die gewertete Zeit rechnet der Server selbst aus.
// =============================================================================

declare(strict_types=1);
require __DIR__ . '/lib.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
// Browser-Version auf anderen Seiten (z. B. GitHub Pages) darf ebenfalls zugreifen
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') { exit; }

function out(array $a, int $code = 200): void {
    http_response_code($code);
    echo json_encode($a, JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    cleanup();
    $action = $_GET['action'] ?? '';
    $body = [];
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
        $body = json_decode((string)file_get_contents('php://input'), true) ?: [];
        $action = $body['action'] ?? $action;
    }
    $course = (string)($_GET['course'] ?? $body['course'] ?? 'cup');
    if (!valid_course($course)) out(['ok' => false, 'error' => 'course'], 400);
    $pdo = db();
    $now = time();
    $cur = quarter_of($now);

    if ($action === 'list') {
        $q = $pdo->prepare("SELECT * FROM entries WHERE quarter = ? AND course = ? ORDER BY score ASC, id ASC LIMIT " . MAX_ENTRIES);
        $q->execute([$cur, $course]);
        $rows = [];
        foreach ($q->fetchAll() as $i => $r) $rows[] = public_row($r, $i + 1);
        out(['ok' => true, 'quarter' => $cur, 'days_left' => intdiv(quarter_end($now) - $now, 86400) + 1, 'entries' => $rows]);
    }

    if ($action === 'forever') {
        $q = $pdo->prepare("SELECT * FROM entries WHERE quarter <> ? AND course = ? ORDER BY quarter DESC, score ASC, id ASC");
        $q->execute([$cur, $course]);
        $groups = [];
        foreach ($q->fetchAll() as $r) {
            $groups[$r['quarter']] ??= [];
            if (count($groups[$r['quarter']]) < FOREVER_KEEP)
                $groups[$r['quarter']][] = public_row($r, count($groups[$r['quarter']]) + 1);
        }
        $list = [];
        foreach ($groups as $quarter => $rows) $list[] = ['quarter' => $quarter, 'entries' => $rows];
        out(['ok' => true, 'quarters' => $list]);
    }

    if ($action === 'submit') {
        $models = models();
        $fp = (string)($body['fp'] ?? '');
        if (!isset($models[$fp])) out(['ok' => false, 'error' => 'model'], 400);      // verändertes Modell → keine Wertung
        $name = clean_name((string)($body['name'] ?? ''));
        if ($name === '') $name = 'Pilot';
        $laps = array_map('floatval', (array)($body['laps'] ?? []));
        $total = (float)($body['total'] ?? 0);
        // Plausibel? genau 3 Runden, jede ≥ 2 s, Summe = Gesamtzeit, höchstens 10 min
        if (count($laps) !== 3 || min($laps) < 2.0 || abs(array_sum($laps) - $total) > 0.2 || $total > 600.0)
            out(['ok' => false, 'error' => 'times'], 400);
        $ip = ip_hash();
        $c = $pdo->prepare("SELECT COUNT(*) AS n FROM entries WHERE ip_hash = ? AND created > ?");
        $c->execute([$ip, gmdate('Y-m-d H:i:s', $now - 3600)]);
        if ((int)$c->fetch()['n'] >= SUBMITS_PER_HOUR) out(['ok' => false, 'error' => 'rate'], 429);
        $score = round(scored($total, $models[$fp]['box']), 2);
        $ins = $pdo->prepare("INSERT INTO entries (quarter, course, name, model, total, lap1, lap2, lap3, score, platform, version, created, ip_hash)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
        $ins->execute([$cur, $course, $name, $models[$fp]['name'], round($total, 2), round($laps[0], 2), round($laps[1], 2), round($laps[2], 2),
            $score, mb_substr((string)($body['platform'] ?? ''), 0, 40), mb_substr((string)($body['version'] ?? ''), 0, 20),
            gmdate('Y-m-d H:i:s', $now), $ip]);
        $id = (int)$pdo->lastInsertId();
        $r = $pdo->prepare("SELECT COUNT(*) AS n FROM entries WHERE quarter = ? AND course = ? AND (score < ? OR (score = ? AND id < ?))");
        $r->execute([$cur, $course, $score, $score, $id]);
        $rank = (int)$r->fetch()['n'] + 1;
        out(['ok' => true, 'id' => $id, 'rank' => $rank, 'score' => $score, 'listed' => $rank <= MAX_ENTRIES]);
    }
    out(['ok' => false, 'error' => 'action'], 400);
} catch (Throwable $e) {
    out(['ok' => false, 'error' => 'server'], 500);
}
