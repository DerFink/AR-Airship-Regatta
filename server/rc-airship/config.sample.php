<?php
// 2026-11-11 19:20 – Erstversion: Vorlage für die Zugangsdaten. Als config.php speichern und ausfüllen – config.php NIE auf GitHub hochladen.
// =============================================================================
// MySQL-Datenbank bei Strato: Kundenlogin → Datenbanken → „Datenbank anlegen“.
// Dort stehen Server (Host), Datenbankname, Benutzer und Passwort.
// Admin-Passwort-Hash erzeugen (einmalig, z. B. auf https://flinkfink.de/rc-airship/hash.php
// oder lokal):   php -r 'echo password_hash("DEIN-PASSWORT", PASSWORD_DEFAULT), "\n";'
// =============================================================================
return [
    'dsn'        => 'mysql:host=rdbms.strato.de;dbname=DBxxxxxxx;charset=utf8mb4',
    'db_user'    => 'Uxxxxxxx',
    'db_pass'    => 'DATENBANK-PASSWORT',
    'admin_hash' => '$2y$10$...',              // Ergebnis von password_hash(...)
    'salt'       => 'irgendein-langer-zufallstext',  // für den IP-Hash (Schutz gegen Fluten)
];
