# 2026-11-09 10:30 – Version 0.11.3
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

const VERSION := "0.11.3"
const BUILD := 0

## GitHub-Repository mit den Releases (für die Update-Suche)
const REPO := "DerFink/AR-Airship-Regatta"


## Anzeige für das Menü, z. B. "Version 0.9.7 (Build 32)"
static func text() -> String:
	if BUILD > 0:
		return "Version %s (Build %d)" % [VERSION, BUILD]
	return "Version %s (lokal gebaut)" % VERSION
