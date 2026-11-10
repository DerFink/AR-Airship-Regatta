# 2026-11-11 10:35 – Erstversion: Klang-Sicherung – schaltet den Propellerklang stufenweise herunter (Fein → Mittel → Einfach), wenn die Bildrate unter 30 fällt, die Klangerzeugung mehr als 2 ms je Bild braucht oder der Tonpuffer leerläuft; Hinweis „Zu geringe Rechenleistung, Klang vereinfacht“
# =============================================================================
# SoundGuard.gd  (ein Knoten in der Hauptszene)
# -----------------------------------------------------------------------------
#   Stufe 2 „Fein“    je Motor ein eigener Klang (PropSynth)        – Standard
#   Stufe 1 „Mittel“  ein gemeinsamer Klang für alle Motoren         – ab 3 Motoren automatisch
#   Stufe 0 „Einfach“ fertige Schleife je Motor, nur Tonhöhe verstellt (PropSound)
#
# Auslöser fürs Herunterschalten (je eine Stufe, höchstens alle 3 s):
#   – Bildrate unter 30 (PerformanceWatchdog meldet „vereinfacht“)
#   – Klangerzeugung im Mittel über 2 ms je Bild (gemessen in PropSynth)
#   – Tonpuffer läuft leer (Aussetzer, PropSynth.underrun)
# Hochgeschaltet wird nicht von selbst (Klang soll nicht hin- und herspringen).
# =============================================================================
class_name SoundGuard
extends Node

signal level_changed(level: int)          ## Klangerzeuger neu aufbauen
signal notice(text: String)

const MAX_MS_PER_FRAME := 2.0
const NAMES := ["Einfach", "Mittel", "Fein"]

var _frames := 0
var _cool := 0.0                          ## Sperrzeit nach einem Wechsel (s)


## Stufe für eine bestimmte Motorzahl (ab 3 Motoren höchstens „Mittel“).
static func level_for(motor_count: int) -> int:
	return mini(PropSynth.level, 1) if motor_count >= 3 else PropSynth.level


## Von außen (Watchdog: Bildrate zu niedrig) eine Stufe herunter.
func on_low_fps(simplified: bool) -> void:
	if simplified:
		_step_down()


func _process(dt: float) -> void:
	_cool = maxf(_cool - dt, 0.0)
	_frames += 1
	if PropSynth.underrun:
		PropSynth.underrun = false
		_step_down()
	if _frames >= 60:                     # ≈ 1 s: mittlere Rechenzeit je Bild prüfen
		var ms := PropSynth.usec_acc / 1000.0 / float(_frames)
		PropSynth.usec_acc = 0
		_frames = 0
		if ms > MAX_MS_PER_FRAME:
			_step_down()


func _step_down() -> void:
	if _cool > 0.0 or PropSynth.level <= 0:
		return
	PropSynth.level -= 1
	_cool = 3.0
	notice.emit("Zu geringe Rechenleistung, Klang vereinfacht")
	level_changed.emit(PropSynth.level)
