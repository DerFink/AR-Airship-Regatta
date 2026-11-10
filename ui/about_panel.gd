# 2026-11-10 21:10 – Erstversion: „Grundlagen des Simulators“ mit Reitern Physik, Luftschiff-Modell, Regler (PID), Akku, Über / Lizenz (Texte Deutsch und Englisch; andere Sprachen zeigen den englischen Text)
# =============================================================================
# AboutPanel.gd
# -----------------------------------------------------------------------------
#   ┌ Grundlagen des Simulators ─────────────────────────────── [Schließen] ┐
#   │ [Physik] [Luftschiff-Modell] [Regler (PID)] [Akku] [Über / Lizenz]     │
#   │ ┌──────────────────────────────────────────────────────────────────┐ │
#   │ │ Text mit Formeln (scrollt)                                       │ │
#   │ └──────────────────────────────────────────────────────────────────┘ │
#   └────────────────────────────────────────────────────────────────────────┘
# Die Texte stehen unten als BBCode (RichTextLabel). Sie beschreiben, was der
# Simulator wirklich rechnet (airship_physics.gd, flight_controller.gd,
# battery.gd) – bei Änderungen dort bitte hier nachziehen.
# =============================================================================
class_name AboutPanel
extends Control

signal closed

const CONTACT := "erich.fink ät aerarium.de"
const TABS := ["Physik", "Luftschiff-Modell", "Regler (PID)", "Akku", "Über / Lizenz"]

var _text: RichTextLabel
var _tab_btns: Array[Button] = []
var _tab := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.14, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := UITheme.make_vbox("md")
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24; root.offset_right = -24; root.offset_top = 18; root.offset_bottom = -18
	add_child(root)
	# Kopfzeile
	var head := UITheme.make_hbox("sm")
	var title := UITheme.make_title("Grundlagen des Simulators")
	title.add_theme_font_size_override("font_size", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var b_close := UITheme.make_button("Schließen")
	b_close.pressed.connect(func(): closed.emit())
	head.add_child(b_close)
	root.add_child(head)
	# Reiter
	var tabs := UITheme.make_hbox("xs")
	var grp := UITheme.make_toggle_group()
	for i in TABS.size():
		var b := UITheme.make_pill(TABS[i], true)
		b.toggle_mode = true
		b.button_group = grp
		var idx := i
		b.pressed.connect(func(): _show(idx))
		tabs.add_child(b)
		_tab_btns.append(b)
	root.add_child(tabs)
	# Text
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.box(Color("161d27"), Color("2c3746"), -1, 16))
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.selection_enabled = false
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_font_size_override("bold_font_size", 19)
	box.add_child(_text)
	root.add_child(box)
	visibility_changed.connect(func(): if visible: _show(_tab))
	_show(0)


## Reiter i anzeigen (Deutsch oder Englisch – andere Sprachen nehmen Englisch).
func _show(i: int) -> void:
	_tab = i
	for k in _tab_btns.size():
		_tab_btns[k].set_pressed_no_signal(k == i)
	var lang := "de" if I18n.current == "de" else "en"
	var t: String = (TEXT_DE if lang == "de" else TEXT_EN)[i]
	_text.text = t.replace("{CONTACT}", CONTACT).replace("{VERSION}", BuildInfo.text())
	_text.scroll_to_line(0)


# =============================================================================
# Texte (BBCode). [b]…[/b] fett, [code]…[/code] Formeln.
# =============================================================================
const TEXT_DE := [
# --- Physik ---
"""[b]Bewegungsgleichungen (6 Freiheitsgrade)[/b]
Das Luftschiff ist ein starrer Körper mit 3 Verschiebungen und 3 Drehungen. Gerechnet wird im Körpersystem (Ursprung im Auftriebszentrum, Nase nach vorn) mit 60 Schritten pro Sekunde:

[code](m + Mₐ)·a = F + Mₐ·(ω × v) − ω × (Mₐ·v)
(I + Iₐ)·ω̇ = T − ω × ((I + Iₐ)·ω) − v × (Mₐ·v)[/code]

m, I: Masse und Trägheit des Schiffs (Hülle, Traggas, Motoren, Akku, Flossen)
Mₐ, Iₐ: virtuelle Massen und Trägheiten der mitbewegten Luft
F, T: Kräfte und Momente aus Gewicht, Auftrieb, Rumpf, Flossen und Motoren

[b]Virtuelle Massen[/b]
Ein Luftschiff ist fast so leicht wie die Luft, die es verdrängt. Beim Beschleunigen muss es diese Luft mit anschieben – und zwar quer viel mehr als längs. Der Simulator nutzt dafür die Lamb-Faktoren des Rotationsellipsoids (ATTAS-Ansatz):
[code]längs: k₁·ρ·V      quer: k₂·ρ·V      Drehung: k'·I_Luft[/code]
Bei L/D = 6 ist k₁ ≈ 0,05 und k₂ ≈ 0,92: quer schiebt das Schiff fast eine zweite Luftfüllung mit.

[b]Munk-Moment[/b]
Aus den ungleichen virtuellen Massen folgt direkt der letzte Term der zweiten Gleichung, [code]−v × (Mₐ·v)[/code]. Bei Schräganströmung unter dem Winkel α gilt näherungsweise
[code]M_Munk = ½·ρ·v²·V·(k₂ − k₁)·sin 2α[/code]
Dieses Moment dreht die Nase weiter aus dem Wind – der Rumpf allein ist instabil. Weil die Grenzschicht am Heck einen Teil davon aufhebt, rechnet der Simulator mit 60 % des theoretischen Werts.

[b]Flossen und Ruder[/b]
Jede Flosse ist eine kleine Tragfläche mit eigener Anströmung (Fahrt + Drehung des Schiffs). Auftrieb nach Helmbold für kleine Streckungen, Strömungsabriss bei großen Winkeln, Ruderwirkung je nach Bauart (Ruderklappe, Pendelruder, flexible Depronplatte). Hinter dem Schwerpunkt wirken Flossen stabilisierend, Canards vorne destabilisierend.

[b]Schub[/b]
Jeder Motor erzeugt Schub entlang seiner Achse, die Schwenkmotoren drehen diese Achse. Der Schub fällt mit der Fahrt (Propeller-Anströmung) und mit der Akkuspannung. Sitzt der Motor nicht im Schwerpunkt, entsteht zusätzlich ein Moment.

[b]Gewicht und Auftrieb[/b]
[code]Auftrieb = ρ_Luft · V · g      (ρ = 1,20 kg/m³)[/code]
Restmasse (Akku, Ballast) wird so bemessen und gelegt, dass das Schiff leicht schwerer als Luft ist und waagrecht hängt. Liegt der Schwerpunkt unter dem Auftriebszentrum, richtet ein Pendelmoment das Schiff auf.""",
# --- Luftschiff-Modell ---
"""[b]Hülle nach Gertler[/b]
Die Form der Hülle stammt aus der DTMB-Serie 58 (Gertler, 1950). Ein Polynom 6. Grades beschreibt den Radius über der Länge; die Parameter sind Länge/Durchmesser (L/D), Lage des dicksten Querschnitts, Nasen- und Heckradius und Völligkeit. Aus der Form folgen Volumen, Oberfläche, Auftriebszentrum und die virtuellen Massen.

[b]Standardmodelle[/b]
[b]Chewie[/b] – das echte Rennluftschiff: L/D 6, Lambda-Leitwerk aus drei leichten Pendelflossen (±50°), zwei schwenkbare Motoren seitlich unten, Teensy-Flugcontroller.
[b]Albacore Standard[/b] – nach dem U-Boot USS Albacore, L/D 7,5, Kreuzleitwerk mit Ruderklappen, zwei Motoren seitlich unten.

[b]Massen[/b]
Hülle (verteilt über die Fläche), Motoren und Flossen am Einbauort, Elektronik und Akku unten an der Hülle. Daraus berechnet der Simulator Schwerpunkt und Trägheitsmomente; die Restmasse wird automatisch getrimmt.

[b]Leitwerksgröße[/b]
Der Baukasten prüft das Leitwerksvolumen [code]V_H = S_Flossen · Hebelarm / V_Hülle[/code]. Ist es zu klein, kann das Leitwerk das Munk-Moment nicht ausgleichen und es erscheint eine Warnung.

[b]Eigene Modelle[/b]
Unter „Modell & Bau“ → „Eigenbau“ lassen sich Hülle, Leitwerk, Antrieb und Aussehen frei einstellen. Modelle können als Datei exportiert und an den Admin geschickt werden – geprüfte Modelle kommen als Standardmodell für alle in die App.""",
# --- Regler (PID) ---
"""[b]Der virtuelle Flugcontroller[/b]
Er bildet den Teensy-Flugcontroller (dRehmFlight) des echten Chewie nach. Gemessen werden Drehraten und Lage (wie Kreisel und Beschleunigungssensor), gestellt werden Ruder und Schwenkmotoren. Das Gas bleibt immer beim Piloten – der Regler verändert den Schub nie.

[b]PID-Regler[/b]
[code]u = Kp·e + Ki·∫e dt + Kd·de/dt[/code]
e ist die Abweichung zwischen Soll und Ist. P reagiert sofort, I beseitigt bleibende Abweichungen (begrenzt gegen Aufschaukeln), D dämpft schnelle Änderungen.

[b]Modi[/b]
[b]Direkt[/b]: Knüppel gehen ohne Regler auf Ruder und Schwenker.
[b]Mode 2[/b]: Nick als Lageregler (Knüppel = Sollwinkel, loslassen = waagrecht), Gier als Ratenregler.
[b]Mode 3[/b]: wie Mode 2, Gier mit PID-Ratenregler (max. 110 °/s), Nick-Schutz begrenzt den Nickwinkel, Rollen über die Schwenkmotoren.

[b]Mischer[/b]
Jede Flosse bekommt Nick- und Gieranteile nach ihrem Einbauwinkel. Schwenkmotoren übernehmen Nick gemeinsam und Rollen gegenläufig.

[b]Autopilot[/b]
Der Autopilot fliegt die Acht um die Pylone mit dem aktuellen Modell und den aktuellen Reglerwerten – nur über die Knüppel, wie ein Pilot. Er kann scheitern, z. B. wenn der Akku leer ist oder das Schiff die Bahn verliert.""",
# --- Akku ---
"""[b]Akku-Modell[/b]
Standard: LiPo 4S, 300 mAh (Chewie).

[b]Spannung unter Last[/b]
Die Leerlaufspannung E hängt vom Ladezustand ab (typische LiPo-Kurve je Zelle). Mit dem Innenwiderstand R und der Motorleistung P gilt
[code]V = E − I·R,   I = P(V) / V[/code]
und daraus [code]a·V² + V − E = 0[/code] mit [code]a = R·P₀ / V₀³[/code].

[b]Leistung[/b]
[code]P_Motor ≈ 25 W · (Schub in N)^1,5[/code]   plus 2 W für Elektronik und Servos. Die Werte sind Annahmen und können durch Messungen ersetzt werden.

[b]Rückwirkung auf den Flug[/b]
Sinkt die Spannung, drehen die Motoren langsamer: [code]Schub ∝ (V/V₀)²[/code]. Ist der Akku leer, gibt es keinen Schub mehr.

Grobe Flugzeiten (Chewie geradeaus): 30 % Gas ≈ 12 min, 50 % ≈ 3 min, 70 % ≈ 77 s, Vollgas ≈ 34 s. „Zurücksetzen“ lädt den Akku wieder voll.""",
# --- Über / Lizenz ---
"""[b]RC Airship Regatta[/b]
Open-Source-Simulator für DIY-Rennluftschiffe. Gebaut mit der Godot Engine 4.

{VERSION}

[b]Lizenz[/b]
MIT-Lizenz – © 2026 Erich Fink (DerFink). Der Quelltext darf frei verwendet, verändert und weitergegeben werden.
Godot Engine: MIT-Lizenz. Schrift für Chinesisch: Noto Sans CJK (SIL Open Font License).

[b]Quellen[/b]
Gertler, M.: Resistance Experiments on a Systematic Series of Streamlined Bodies of Revolution (DTMB Report 719, 1950)
Munk, M. M.: The Aerodynamic Forces on Airship Hulls (NACA Report 184, 1924)
Lamb, H.: Hydrodynamics
dRehmFlight (Nicholas Rehm) – Grundlage des Teensy-Flugcontrollers

[b]Kontakt[/b]
{CONTACT}""",
]

const TEXT_EN := [
# --- Physics ---
"""[b]Equations of motion (6 degrees of freedom)[/b]
The airship is a rigid body with 3 translations and 3 rotations. The simulator works in body axes (origin at the centre of buoyancy, nose forward) at 60 steps per second:

[code](m + Mₐ)·a = F + Mₐ·(ω × v) − ω × (Mₐ·v)
(I + Iₐ)·ω̇ = T − ω × ((I + Iₐ)·ω) − v × (Mₐ·v)[/code]

m, I: mass and inertia of the ship (envelope, lifting gas, motors, battery, fins)
Mₐ, Iₐ: added (virtual) masses and inertias of the air moved along
F, T: forces and moments from weight, buoyancy, hull, fins and motors

[b]Added masses[/b]
An airship is almost as light as the air it displaces. When it accelerates it has to push that air along – much more sideways than lengthwise. The simulator uses Lamb's coefficients for the prolate ellipsoid (ATTAS approach):
[code]axial: k₁·ρ·V      lateral: k₂·ρ·V      rotation: k'·I_air[/code]
At L/D = 6, k₁ ≈ 0.05 and k₂ ≈ 0.92: sideways the ship drags almost a second load of air.

[b]Munk moment[/b]
The unequal added masses directly produce the last term of the second equation, [code]−v × (Mₐ·v)[/code]. At an angle of attack α, approximately
[code]M_Munk = ½·ρ·v²·V·(k₂ − k₁)·sin 2α[/code]
This moment turns the nose further out of the wind – the bare hull is unstable. Because the boundary layer at the tail cancels part of it, the simulator uses 60 % of the theoretical value.

[b]Fins and rudders[/b]
Each fin is a small wing with its own local flow (airspeed + rotation of the ship). Lift follows Helmbold for low aspect ratios, with stall at large angles; control effect depends on the type (flap, all-moving, flexible Depron plate). Fins behind the centre of gravity stabilise, canards at the front destabilise.

[b]Thrust[/b]
Each motor pushes along its axis; swivelling motors rotate that axis. Thrust drops with airspeed (propeller inflow) and with battery voltage. A motor away from the centre of gravity also adds a moment.

[b]Weight and buoyancy[/b]
[code]Buoyancy = ρ_air · V · g      (ρ = 1.20 kg/m³)[/code]
The remaining mass (battery, ballast) is sized and placed so that the ship is slightly heavier than air and hangs level. With the centre of gravity below the centre of buoyancy, a pendulum moment rights the ship.""",
# --- Airship model ---
"""[b]Gertler hull[/b]
The envelope shape comes from the DTMB Series 58 (Gertler, 1950). A 6th-order polynomial gives the radius along the length; parameters are length/diameter (L/D), position of maximum diameter, nose and tail radius and prismatic coefficient. Volume, surface, centre of buoyancy and added masses follow from the shape.

[b]Standard models[/b]
[b]Chewie[/b] – the real racing airship: L/D 6, lambda tail of three light all-moving fins (±50°), two swivelling motors low on the sides, Teensy flight controller.
[b]Albacore Standard[/b] – after the submarine USS Albacore, L/D 7.5, cross tail with flaps, two motors low on the sides.

[b]Masses[/b]
Envelope (spread over the surface), motors and fins where they are mounted, electronics and battery underneath the hull. From these the simulator computes centre of gravity and moments of inertia; the remaining mass is trimmed automatically.

[b]Tail size[/b]
The builder checks the tail volume [code]V_H = S_fins · lever arm / V_hull[/code]. If it is too small, the tail cannot balance the Munk moment and a warning appears.

[b]Your own models[/b]
Under “Model & Build” → “Custom build” you can set hull, tail, propulsion and appearance freely. Models can be exported as a file and sent to the admin – checked models become standard models for everyone.""",
# --- Controller (PID) ---
"""[b]The virtual flight controller[/b]
It mirrors the Teensy flight controller (dRehmFlight) of the real Chewie. It measures rates and attitude (like gyro and accelerometer) and drives fins and swivelling motors. Throttle always stays with the pilot – the controller never changes thrust.

[b]PID controller[/b]
[code]u = Kp·e + Ki·∫e dt + Kd·de/dt[/code]
e is the error between setpoint and measurement. P reacts immediately, I removes steady errors (limited against wind-up), D damps fast changes.

[b]Modes[/b]
[b]Direct[/b]: sticks go straight to fins and swivels, no controller.
[b]Mode 2[/b]: pitch as attitude controller (stick = target angle, release = level), yaw as rate controller.
[b]Mode 3[/b]: like Mode 2, yaw with PID rate controller (max. 110 °/s), pitch protection limits the pitch angle, roll via the swivelling motors.

[b]Mixer[/b]
Each fin gets pitch and yaw shares according to its mounting angle. Swivelling motors take pitch together and roll in opposition.

[b]Autopilot[/b]
The autopilot flies the figure eight around the pylons with the current model and current controller values – only through the sticks, like a pilot. It can fail, e.g. when the battery runs empty or the ship loses the track.""",
# --- Battery ---
"""[b]Battery model[/b]
Default: LiPo 4S, 300 mAh (Chewie).

[b]Voltage under load[/b]
The open-circuit voltage E depends on the state of charge (typical LiPo curve per cell). With internal resistance R and motor power P:
[code]V = E − I·R,   I = P(V) / V[/code]
hence [code]a·V² + V − E = 0[/code] with [code]a = R·P₀ / V₀³[/code].

[b]Power[/b]
[code]P_motor ≈ 25 W · (thrust in N)^1.5[/code]   plus 2 W for electronics and servos. These are assumptions and can be replaced by measurements.

[b]Effect on flight[/b]
As voltage drops, the motors spin slower: [code]thrust ∝ (V/V₀)²[/code]. An empty battery gives no thrust.

Rough flight times (Chewie straight ahead): 30 % throttle ≈ 12 min, 50 % ≈ 3 min, 70 % ≈ 77 s, full ≈ 34 s. “Reset” recharges the battery.""",
# --- About / license ---
"""[b]RC Airship Regatta[/b]
Open-source simulator for DIY racing airships. Built with the Godot Engine 4.

{VERSION}

[b]License[/b]
MIT License – © 2026 Erich Fink (DerFink). The source code may be used, changed and shared freely.
Godot Engine: MIT License. Chinese font: Noto Sans CJK (SIL Open Font License).

[b]References[/b]
Gertler, M.: Resistance Experiments on a Systematic Series of Streamlined Bodies of Revolution (DTMB Report 719, 1950)
Munk, M. M.: The Aerodynamic Forces on Airship Hulls (NACA Report 184, 1924)
Lamb, H.: Hydrodynamics
dRehmFlight (Nicholas Rehm) – basis of the Teensy flight controller

[b]Contact[/b]
{CONTACT}""",
]
