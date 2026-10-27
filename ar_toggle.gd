# 2026-10-27 10:58 – Erstversion: AR standardmäßig aus, Umschalten über XRServer-Schnittstelle, sauberer Rückfall auf virtuelle Umgebung
# =============================================================================
# ARToggle.gd  (Kind der Hauptszene)
# -----------------------------------------------------------------------------
# Schaltet zwischen virtueller Testumgebung (Standard, stromsparend) und AR.
# Godot kapselt AR über XRServer-Schnittstellen. Welche verfügbar ist, hängt
# vom Export ab:
#   – "WebXR"   : Web-Export (Browser mit WebXR-AR-Unterstützung)
#   – "OpenXR"  : Android-Geräte/Brillen mit OpenXR-Laufzeit
# Lizenz-Hinweis: Mobile AR auf Android (ARCore) und iOS (ARKit) braucht
# Hersteller-SDKs, die nicht vollständig Open Source sind. Für die strikte
# Open-Source-Linie ist WebXR der sauberste Weg – deshalb ist der Name der
# Schnittstelle konfigurierbar und AR bleibt optional.
# =============================================================================
class_name ARToggle
extends Node

signal ar_state_changed(active: bool, message: String)

@export var interface_name: String = "WebXR"
## Virtuelle Umgebung (Himmel, Halle, Boden), die im AR-Modus ausgeblendet wird.
@export var virtual_environment: Node3D
@export var world_environment: WorldEnvironment

var ar_active := false
var _xr: XRInterface


func toggle() -> void:
	if ar_active:
		disable_ar()
	else:
		enable_ar()


func enable_ar() -> void:
	_xr = XRServer.find_interface(interface_name)
	if _xr == null:
		ar_state_changed.emit(false, "AR ist auf diesem Gerät nicht verfügbar.")
		return
	# WebXR: AR-Sitzung anfordern (per set(), damit das Skript auch auf
	# Nicht-Web-Plattformen ohne WebXRInterface-Klasse parst).
	# Hinweis: Im Browser startet die Sitzung asynchron (Signal session_started)
	# und nur nach einer Nutzergeste – der AR-Knopf erfüllt das.
	if _xr.get_class() == "WebXRInterface":
		_xr.set("session_mode", "immersive-ar")
		_xr.set("requested_reference_space_types", "local-floor, local")
	if not _xr.is_initialized() and not _xr.initialize():
		ar_state_changed.emit(false, "AR konnte nicht gestartet werden.")
		return
	get_viewport().use_xr = true
	get_viewport().transparent_bg = true        # Kamerabild scheint durch
	if virtual_environment: virtual_environment.visible = false
	if world_environment: world_environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	ar_active = true
	ar_state_changed.emit(true, "AR aktiv")


func disable_ar() -> void:
	get_viewport().use_xr = false
	get_viewport().transparent_bg = false
	if _xr and _xr.is_initialized():
		_xr.uninitialize()
	if virtual_environment: virtual_environment.visible = true
	if world_environment: world_environment.environment.background_mode = Environment.BG_SKY
	ar_active = false
	ar_state_changed.emit(false, "AR aus")
