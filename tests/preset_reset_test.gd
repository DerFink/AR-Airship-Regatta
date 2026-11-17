# 2026-11-17 09:45 – Erstversion: Standardmodell laden räumt den Mischer des vorigen Modells weg (Chewie bleibt unverändert und zählt für die Bestenliste)
extends SceneTree

func _initialize() -> void:
	var ok := true
	var s := AirshipPhysics.new()
	root.add_child(s)
	AirshipPresets.chewie(s)
	s.rebuild_mass_properties()
	var fp0 := ModelCodec.fingerprint(s)
	# anderes Modell mit eigenem Mischer (wie beim PigLeg): Schub umgedreht
	s.mix_manual = true
	s.mix_table = {"t0": [-100.0, 0.0, 0.0, 0.0], "x1": true}
	# zurück auf Chewie (Auswahl bzw. „Auf Werkseinstellung zurücksetzen“)
	AirshipPresets.chewie(s)
	s.rebuild_mass_properties()
	if s.mix_manual or not s.mix_table.is_empty():
		print("FEHLER Mischer des vorigen Modells ist noch da: ", s.mix_table); ok = false
	if ModelCodec.fingerprint(s) != fp0:
		print("FEHLER Chewie gilt als verändert"); ok = false
	if AirshipPresets.standard_model_of(s) == "":
		print("FEHLER Chewie wird nicht als Standardmodell erkannt"); ok = false
	print("preset_reset_test: " + ("OK" if ok else "FEHLER"))
	print("ENDE")
	if not ok: assert(false, "Mischer bleibt beim Modellwechsel stehen")
	quit(0 if ok else 1)
