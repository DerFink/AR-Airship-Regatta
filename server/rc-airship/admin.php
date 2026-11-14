<?php
// 2026-11-14 21:40 – Anmeldung: Sperre nach 5 Fehlversuchen (15 min) mit Meldung; neu: Besucherzähler (heute, 30 Tage, insgesamt, je Plattform, je Tag)
// 2026-11-11 19:20 – Erstversion: Verwaltung der Online-Bestenliste (Anmeldung mit Passwort, Einträge ansehen und einzelne Piloten streichen)
// =============================================================================
// admin.php  –  https://flinkfink.de/rc-airship/admin.php
// -----------------------------------------------------------------------------
// Anmeldung mit dem Admin-Passwort (als Hash in config.php, siehe
// config.sample.php). Zeigt laufendes Quartal und Best Forever; ein Eintrag
// oder alle Einträge eines Namens lassen sich löschen (z. B. wenn jemand
// nicht mehr in der Liste stehen möchte).
// =============================================================================

declare(strict_types=1);
require __DIR__ . '/lib.php';

session_set_cookie_params(['httponly' => true, 'samesite' => 'Strict', 'secure' => !empty($_SERVER['HTTPS'])]);
session_start();
header('Content-Type: text/html; charset=utf-8');
header('X-Frame-Options: DENY');

function h(string $s): string { return htmlspecialchars($s, ENT_QUOTES, 'UTF-8'); }

// --- Anmelden / Abmelden ---------------------------------------------------
if (isset($_POST['password'])) {
    usleep(400000);                                   // bremst Passwort-Raten
    if (login_locked()) {                             // 5 Fehlversuche → 15 Minuten Sperre
        $_SESSION['login_msg'] = 'Zu viele Fehlversuche – bitte in ' . LOGIN_LOCK_MIN . ' Minuten erneut versuchen.';
    } elseif (password_verify((string)$_POST['password'], (string)$CFG['admin_hash'])) {
        session_regenerate_id(true);
        $_SESSION['admin'] = true;
        $_SESSION['csrf'] = bin2hex(random_bytes(16));
    } else {
        login_failed();
        $_SESSION['login_msg'] = 'Passwort falsch.';
    }
    header('Location: admin.php'); exit;
}
if (isset($_GET['logout'])) { session_destroy(); header('Location: admin.php'); exit; }

$admin = !empty($_SESSION['admin']);
$msg = '';

// --- Löschen (nur angemeldet, mit Formular-Schlüssel gegen fremde Seiten) ----
if ($admin && ($_POST['csrf'] ?? '') === ($_SESSION['csrf'] ?? 'x')) {
    $pdo = db();
    if (isset($_POST['del_id'])) {
        $pdo->prepare("DELETE FROM entries WHERE id = ?")->execute([(int)$_POST['del_id']]);
        $msg = 'Eintrag gelöscht.';
    } elseif (isset($_POST['del_name'])) {
        $st = $pdo->prepare("DELETE FROM entries WHERE name = ?");
        $st->execute([(string)$_POST['del_name']]);
        $msg = $st->rowCount() . ' Einträge von „' . h((string)$_POST['del_name']) . '“ gelöscht.';
    }
}
?><!doctype html>
<html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bestenliste – Verwaltung</title>
<style>
 body{font-family:system-ui,sans-serif;background:#0b0f14;color:#e9eef3;margin:0;padding:16px}
 table{border-collapse:collapse;width:100%;font-size:14px} td,th{padding:6px 8px;border-bottom:1px solid #ffffff1a;text-align:left;white-space:nowrap}
 th{color:#9aa7b4;font-weight:normal} .box{background:#161c23;border:1px solid #ffffff22;border-radius:12px;padding:16px;margin-bottom:16px;overflow-x:auto}
 button,input{font:inherit;padding:6px 10px;border-radius:8px;border:1px solid #ffffff33;background:#222a33;color:#e9eef3}
 button.del{border-color:#e5484d;color:#ff9a9a} .msg{color:#3fb27f} .err{color:#ff9a9a} a{color:#3d8bfd}
 .num{font-size:28px;font-weight:bold} .stats{display:flex;gap:24px;flex-wrap:wrap}
</style></head><body>
<h1>Bestenliste – Verwaltung</h1>
<?php if (!$admin): ?>
 <?php if (!empty($_SESSION['login_msg'])): ?><p class="err"><?= h($_SESSION['login_msg']) ?></p><?php unset($_SESSION['login_msg']); endif; ?>
 <div class="box"><form method="post"><label>Passwort <input type="password" name="password" autofocus></label> <button>Anmelden</button></form></div>
<?php else:
 $pdo = db(); cleanup();
 $cur = quarter_of(time());
 $courses = $pdo->query("SELECT DISTINCT course FROM entries ORDER BY course")->fetchAll(PDO::FETCH_COLUMN);
 $csrf = h($_SESSION['csrf']);
?>
 <p><a href="?logout=1">Abmelden</a> · laufendes Quartal: <b><?= h($cur) ?></b></p>
 <?php if ($msg): ?><p class="msg"><?= $msg ?></p><?php endif; ?>
 <?php
 // --- Besucherzähler: Aufrufe der App/Seite je Tag und Plattform (ohne IP) ---
 $today = gmdate('Y-m-d');
 $sum = fn(string $where, array $p = []) => (function () use ($pdo, $where, $p) {
     $st = $pdo->prepare("SELECT COALESCE(SUM(n), 0) AS n FROM hits $where"); $st->execute($p); return (int)$st->fetch()['n']; })();
 $h_today = $sum("WHERE day = ?", [$today]);
 $h_30 = $sum("WHERE day >= ?", [gmdate('Y-m-d', time() - 29 * 86400)]);
 $h_all = $sum("");
 $per_pf = $pdo->query("SELECT platform, SUM(n) AS n FROM hits GROUP BY platform ORDER BY n DESC")->fetchAll();
 $days = $pdo->prepare("SELECT day, SUM(n) AS n FROM hits WHERE day >= ? GROUP BY day ORDER BY day DESC");
 $days->execute([gmdate('Y-m-d', time() - 29 * 86400)]);
 ?>
 <div class="box"><h2>Aufrufe</h2>
  <div class="stats">
   <div>heute<br><span class="num"><?= $h_today ?></span></div>
   <div>letzte 30 Tage<br><span class="num"><?= $h_30 ?></span></div>
   <div>insgesamt<br><span class="num"><?= $h_all ?></span></div>
   <div>nach Plattform<br><?php foreach ($per_pf as $r): ?><?= h($r['platform']) ?>: <b><?= (int)$r['n'] ?></b><br><?php endforeach; ?></div>
  </div>
  <p style="color:#9aa7b4">Gezählt wird jeder Start der App bzw. der Browser-Version – ohne IP-Adresse oder Kennung (Datum UTC).</p>
  <table><tr><th>Tag</th><th>Aufrufe</th></tr>
  <?php foreach ($days->fetchAll() as $r): ?><tr><td><?= h($r['day']) ?></td><td><?= (int)$r['n'] ?></td></tr><?php endforeach; ?></table>
 </div>
 <div class="box"><form method="post" onsubmit="return confirm('Alle Einträge dieses Namens löschen?')">
  <input type="hidden" name="csrf" value="<?= $csrf ?>">
  Pilot komplett streichen (alle Quartale): <input name="del_name" placeholder="Name genau wie in der Liste"> <button class="del">Streichen</button>
 </form></div>
 <?php foreach ($courses as $course):
   $q = $pdo->prepare("SELECT * FROM entries WHERE course = ? ORDER BY quarter DESC, score ASC, id ASC");
   $q->execute([$course]); $rows = $q->fetchAll(); ?>
 <div class="box"><h2><?= h($course) ?></h2>
  <table><tr><th>Quartal</th><th>Name</th><th>Luffi</th><th>gemessen</th><th>Runden</th><th>gewertet</th><th>Datum</th><th>gespielt mit</th><th>Version</th><th></th></tr>
  <?php foreach ($rows as $r): ?>
   <tr><td><?= h($r['quarter']) ?><?= $r['quarter'] === $cur ? '' : ' (Forever)' ?></td><td><?= h($r['name']) ?></td><td><?= h($r['model']) ?></td>
    <td><?= number_format((float)$r['total'], 2, ',', '') ?></td>
    <td><?= number_format((float)$r['lap1'], 1, ',', '') ?> · <?= number_format((float)$r['lap2'], 1, ',', '') ?> · <?= number_format((float)$r['lap3'], 1, ',', '') ?></td>
    <td><b><?= number_format((float)$r['score'], 2, ',', '') ?></b></td><td><?= h(substr($r['created'], 0, 10)) ?></td>
    <td><?= h($r['platform']) ?></td><td><?= h($r['version']) ?></td>
    <td><form method="post" onsubmit="return confirm('Eintrag löschen?')"><input type="hidden" name="csrf" value="<?= $csrf ?>"><input type="hidden" name="del_id" value="<?= (int)$r['id'] ?>"><button class="del">Löschen</button></form></td></tr>
  <?php endforeach; ?></table></div>
 <?php endforeach; if (!$courses): ?><p>Noch keine Einträge.</p><?php endif; ?>
<?php endif; ?>
</body></html>
