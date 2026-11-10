# 2026-11-11 17:30 – Version 0.19.0
# 2026-11-11 15:10 – Version 0.18.1
# 2026-11-11 14:30 – Version 0.18.0
# 2026-11-11 12:30 – Version 0.17.0
# 2026-11-11 03:20 – Version 0.16.0
# 2026-11-10 23:00 – Version 0.15.0
# 2026-11-10 17:10 – Version 0.14.1
# 2026-11-07 21:10 – Erstversion: Versionsnummer und Build-Nummer der App (der GitHub-Build überschreibt diese Datei vor dem Export)
# =============================================================================
# BuildInfo.gd
# -----------------------------------------------------------------------------
# Wird beim Bauen auf GitHub automatisch neu geschrieben:
#   VERSION = version/name aus export_presets.cfg (z. B. "0.9.7")
#   BUILD   = laufende Nummer des GitHub-Builds (= Release „Android-Build N“)
# Im Repository steht BUILD = 0: so erkennt man eine lokal gebaute App
# (die Update-Suche meldet dann jeden veröffentlichten Build als neuer).
# =============================================================================
class_name BuildInfo

const VERSION := "0.19.0"
const BUILD := 0

## GitHub-Repository mit den Releases (für die Update-Suche)
const REPO := "DerFink/AR-Airship-Regatta"


## Anzeige für das Menü, z. B. "Version 0.9.7 (Build 32)"
static func text() -> String:
	if BUILD > 0:
		return "Version %s (Build %d)" % [VERSION, BUILD]
	return "Version %s (lokal gebaut)" % VERSION
