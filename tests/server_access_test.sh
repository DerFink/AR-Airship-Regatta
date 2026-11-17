#!/usr/bin/env bash
# 2026-11-17 18:10 – Erstversion: Server-Test Zugangscodes – Code anlegen (admin.php), Freischalten (api.php unlock), Gruppe sieht nur eigene Modelle, Admin sieht alle, gesperrter Code → 403, Sperre nach Fehlversuchen, Bestenliste lehnt private Modelle ab
# =============================================================================
# Läuft mit PHP-Kommandozeile und SQLite in einem Temp-Ordner (nichts geht ins Netz).
#   bash tests/server_access_test.sh   → letzte Zeile „server_access_test: OK“
# =============================================================================
set -u
SRC="$(cd "$(dirname "$0")/../server/rc-airship" && pwd)"
TMP="$(mktemp -d)"
trap 'kill $PID 2>/dev/null; rm -rf "$TMP"' EXIT
cp "$SRC"/*.php "$SRC"/models.json "$TMP"/
HASH=$(php -r 'echo password_hash("test-pw", PASSWORD_DEFAULT);')
cat > "$TMP/config.php" <<EOF
<?php return ['dsn' => 'sqlite:$TMP/test.sqlite', 'admin_hash' => '$HASH', 'salt' => 'test'];
EOF
PORT=18765
php -S 127.0.0.1:$PORT -t "$TMP" >/dev/null 2>&1 &
PID=$!
sleep 1
URL="http://127.0.0.1:$PORT"
OK=1
fail() { echo "FEHLER $*"; OK=0; }
api() { curl -s -o "$TMP/out.json" -w "%{http_code}" -X POST -H 'Content-Type: application/json' -d "$1" "$URL/api.php"; }

# --- Admin anmelden (Sitzungs-Cookie), Formular-Schlüssel holen ---
J="$TMP/cookies"
curl -s -c "$J" -b "$J" -d "password=test-pw" "$URL/admin.php" >/dev/null
curl -s -c "$J" -b "$J" "$URL/admin.php" > "$TMP/admin.html"
CSRF=$(grep -o 'name="csrf" value="[0-9a-f]*"' "$TMP/admin.html" | head -1 | sed 's/.*value="//; s/"//')
[ -n "$CSRF" ] || fail "Admin-Anmeldung"

# --- Codes anlegen: Gruppe Troponaut (1 Modell), Gruppe Andere (1 Modell), Admin ---
MT='# Autor: Kollege | Beschreibung: PigLeg
LTA1:Troponaut:AAAA:1234'
MO='LTA1:Geheim2:BBBB:5678'
new_code() {
  curl -s -c "$J" -b "$J" --data-urlencode "csrf=$CSRF" --data-urlencode "code_new=1" --data-urlencode "note=$1" \
       --data-urlencode "role=$2" --data-urlencode "models=$3" "$URL/admin.php" \
  | grep -o '[A-HJ-NP-Z2-9]\{4\}-[A-HJ-NP-Z2-9]\{4\}-[A-HJ-NP-Z2-9]\{4\}' | head -1
}
C_T=$(new_code Troponaut gruppe "$MT")
C_O=$(new_code Andere gruppe "$MO")
C_A=$(new_code Erich admin "")
echo "Codes: $C_T $C_O $C_A"
[ -n "$C_T" ] && [ -n "$C_O" ] && [ -n "$C_A" ] || fail "Codes nicht angelegt"
curl -s -c "$J" -b "$J" "$URL/admin.php" | grep -q "$C_T" || fail "Code nicht dauerhaft sichtbar in der Verwaltung"

# --- Gruppe: nur eigene Modelle, Eingabe klein und ohne Bindestriche geht auch ---
LOW=$(echo "$C_T" | tr 'A-Z' 'a-z' | tr -d '-')
[ "$(api "{\"action\":\"unlock\",\"code\":\"$LOW\"}")" = 200 ] || fail "Gruppe freischalten"
php -r '$j=json_decode(file_get_contents($argv[1]),true); $n=array_column($j["models"],"name");
  exit(($j["role"]==="gruppe" && $n===["Troponaut"] && str_contains($j["models"][0]["meta"],"Kollege")) ? 0 : 1);' "$TMP/out.json" || fail "Gruppe sieht falsche Modelle: $(cat "$TMP/out.json")"

# --- Admin: alle privaten Modelle ---
[ "$(api "{\"action\":\"unlock\",\"code\":\"$C_A\"}")" = 200 ] || fail "Admin freischalten"
php -r '$j=json_decode(file_get_contents($argv[1]),true); $n=array_column($j["models"],"name"); sort($n);
  exit(($j["role"]==="admin" && $n===["Geheim2","Troponaut"]) ? 0 : 1);' "$TMP/out.json" || fail "Admin sieht nicht alle Modelle: $(cat "$TMP/out.json")"

# --- Code sperren → 403 ---
ID_T=$(php -r '$p=new PDO("sqlite:".$argv[1]); echo $p->query("SELECT id FROM access_codes WHERE note=\"Troponaut\"")->fetchColumn();' "$TMP/test.sqlite")
curl -s -c "$J" -b "$J" --data-urlencode "csrf=$CSRF" --data-urlencode "code_toggle=$ID_T" "$URL/admin.php" >/dev/null
[ "$(api "{\"action\":\"unlock\",\"code\":\"$C_T\"}")" = 403 ] || fail "gesperrter Code wird angenommen"

# --- falsche Codes → nach 8 Fehlversuchen 429 (auch für richtige Codes) ---
for i in 1 2 3 4 5 6 7; do api '{"action":"unlock","code":"AAAA-BBBB-CCCC"}' >/dev/null; done
[ "$(api "{\"action\":\"unlock\",\"code\":\"$C_A\"}")" = 429 ] || fail "keine Sperre nach Fehlversuchen"

# --- Bestenliste: unbekannter Fingerabdruck (privates Modell) wird abgelehnt ---
R=$(api '{"action":"submit","course":"cup","name":"X","fp":"privat123","total":36,"laps":[12,12,12],"platform":"pc","version":"t","device":"0123456789abcdef0123","consent":1}')
[ "$R" = 400 ] && grep -q '"model"' "$TMP/out.json" || fail "privates Modell in der Bestenliste angenommen ($R $(cat "$TMP/out.json"))"

[ $OK = 1 ] && echo "server_access_test: OK" || echo "server_access_test: FEHLER"
[ $OK = 1 ]
