# 2026-10-27 10:55 – Erstversion: FPS-Überwachung mit gleitendem Mittel, Umschalten in vereinfachten Modus unter 30 FPS, Hysterese für Rückkehr, Hinweis-Signal
# =============================================================================
# PerformanceWatchdog.gd  (als Autoload oder Kind der Hauptszene)
# -----------------------------------------------------------------------------
# Beobachtet die Bildrate. Liegt sie länger als `trigger_time_s` unter
# `min_fps`, wird das Luftschiff vereinfacht:
#   – Pseudo-Flex-Gelenke der Leitwerke aus
#   – weniger Rumpfscheiben für die Querstrom-Rechnung
# und der Hinweis "Zu geringe Rechenleistung, Modell wird vereinfacht."
# wird per Signal an das UI geschickt.
# Erholt sich die Bildrate deutlich und dauerhaft, wird (optional) wieder
# auf das volle Modell zurückgeschaltet.
# =============================================================================
class_name PerformanceWatchdog
extends Node

## UI zeigt diesen Text kurz als Hinweis an.
signal notice(text: String)
signal simplified_changed(on: bool)

const MSG_SIMPLIFIED := "Zu geringe Rechenleistung, Modell wird vereinfacht."
const MSG_RESTORED := "Rechenleistung ausreichend, volles Modell aktiv."

@export var airship: AirshipPhysics
@export var min_fps: float = 30.0          ## darunter wird vereinfacht
@export var trigger_time_s: float = 2.0    ## so lange muss es zu langsam sein
@export var auto_restore: bool = true
@export var restore_fps: float = 50.0      ## Rückkehr erst deutlich darüber …
@export var restore_time_s: float = 15.0   ## … und so lange stabil

var is_simplified := false
var avg_fps := 60.0
var _below_t := 0.0
var _above_t := 0.0


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	# Gleitendes Mittel (~1 s Zeitkonstante) glättet einzelne Ruckler weg
	var fps_now := 1.0 / delta
	avg_fps = lerpf(avg_fps, fps_now, clampf(delta, 0.0, 1.0))

	if not is_simplified:
		_below_t = _below_t + delta if avg_fps < min_fps else 0.0
		if _below_t >= trigger_time_s:
			_set_simplified(true)
	elif auto_restore:
		_above_t = _above_t + delta if avg_fps > restore_fps else 0.0
		if _above_t >= restore_time_s:
			_set_simplified(false)


func _set_simplified(on: bool) -> void:
	is_simplified = on
	_below_t = 0.0
	_above_t = 0.0
	if airship:
		airship.set_simplified(on)
	simplified_changed.emit(on)
	notice.emit(MSG_SIMPLIFIED if on else MSG_RESTORED)
