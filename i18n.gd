# 2026-11-10 22:10 – Weitere Texte (Einstellungen, Autopilot, Modell & Bau, Kalibrieren)
# 2026-11-10 20:00 – Erstversion: Sprachwahl (Deutsch, Englisch, Französisch, Spanisch, Italienisch, Tschechisch, Polnisch, Chinesisch traditionell) mit Flaggen; Übersetzungen über den TranslationServer von Godot
# =============================================================================
# I18n.gd
# -----------------------------------------------------------------------------
# Quelltexte sind Deutsch. Für jede andere Sprache wird beim Start eine
# Godot-Translation gebaut (deutscher Text → Übersetzung). Godot übersetzt
# danach jeden Knopf und jedes Label automatisch, dessen Text genau einem
# Eintrag entspricht. Zusammengesetzte Texte holt der Code mit tr("…").
#
# Neue Sprache: Code in LANGS und LANG_NAMES ergänzen, Flagge in _flag_svg(),
# Spalte in TEXTS. Fehlt eine Übersetzung, bleibt der deutsche Text stehen
# (lange Texte der Seite „Über“ fallen auf Englisch zurück).
# =============================================================================
class_name I18n
extends RefCounted

const LANGS := ["de", "en", "fr", "es", "it", "cs", "pl", "zh_TW"]
const LANG_NAMES := {"de": "Deutsch", "en": "English", "fr": "Français", "es": "Español",
	"it": "Italiano", "cs": "Čeština", "pl": "Polski", "zh_TW": "繁體中文"}
const SETTINGS_PATH := "user://sprache.cfg"

static var current := "de"
static var _built := false
static var _flags := {}

## Übersetzungen: deutscher Text → [en, fr, es, it, cs, pl, zh_TW]
const TEXTS := {
	# --- Startseite ---
	"Fliegen": ["Fly", "Voler", "Volar", "Vola", "Létat", "Leć", "飛行"],
	"Modell & Bau": ["Model & Build", "Modèle & construction", "Modelo y construcción", "Modello e costruzione", "Model a stavba", "Model i budowa", "模型與建造"],
	"Über den Simulator": ["About the simulator", "À propos du simulateur", "Acerca del simulador", "Informazioni sul simulatore", "O simulátoru", "O symulatorze", "關於模擬器"],
	"Buy me a beer": ["Buy me a beer", "Offre-moi une bière", "Invítame a una cerveza", "Offrimi una birra", "Kup mi pivo", "Postaw mi piwo", "請我喝杯啤酒"],
	"Rennluftschiff-Simulator · Open Source": ["Racing airship simulator · open source", "Simulateur de dirigeable de course · open source", "Simulador de dirigible de carreras · código abierto", "Simulatore di dirigibile da corsa · open source", "Simulátor závodní vzducholodě · open source", "Symulator wyścigowego sterowca · open source", "競速飛艇模擬器 · 開放原始碼"],
	"Sender kalibrieren": ["Calibrate transmitter", "Calibrer l'émetteur", "Calibrar emisora", "Calibra radiocomando", "Kalibrovat vysílač", "Kalibruj nadajnik", "校準遙控器"],
	"Nach Update suchen": ["Check for updates", "Rechercher une mise à jour", "Buscar actualización", "Cerca aggiornamenti", "Hledat aktualizaci", "Szukaj aktualizacji", "檢查更新"],
	"Sender verbunden": ["Transmitter connected", "Émetteur connecté", "Emisora conectada", "Radiocomando collegato", "Vysílač připojen", "Nadajnik podłączony", "遙控器已連接"],
	"Kein Sender": ["No transmitter", "Pas d'émetteur", "Sin emisora", "Nessun radiocomando", "Žádný vysílač", "Brak nadajnika", "未連接遙控器"],
	"Startseite": ["Home", "Accueil", "Inicio", "Home", "Úvod", "Start", "首頁"],
	"Lädt …": ["Loading …", "Chargement …", "Cargando …", "Caricamento …", "Načítání …", "Ładowanie …", "載入中 …"],
	# --- Flugansicht ---
	"Direkt": ["Direct", "Direct", "Directo", "Diretto", "Přímý", "Bezpośredni", "直接"],
	"Autopilot": ["Autopilot", "Pilote auto", "Piloto automático", "Pilota automatico", "Autopilot", "Autopilot", "自動駕駛"],
	"Autopilot stoppen": ["Stop autopilot", "Arrêter le pilote auto", "Detener piloto automático", "Ferma pilota automatico", "Zastavit autopilota", "Zatrzymaj autopilota", "停止自動駕駛"],
	"Zurücksetzen": ["Reset", "Réinitialiser", "Reiniciar", "Ripristina", "Reset", "Resetuj", "重設"],
	"Armed": ["Armed", "Armé", "Armado", "Armato", "Odjištěno", "Uzbrojony", "已解鎖"],
	"Disarmed": ["Disarmed", "Désarmé", "Desarmado", "Disarmato", "Zajištěno", "Rozbrojony", "已上鎖"],
	"Menü": ["Menu", "Menu", "Menú", "Menu", "Menu", "Menu", "選單"],
	"Pilot am Start": ["Pilot at start", "Pilote au départ", "Piloto en la salida", "Pilota alla partenza", "Pilot na startu", "Pilot na starcie", "起點飛手視角"],
	"Hinterher": ["Chase", "Poursuite", "Persecución", "Inseguimento", "Za lodí", "Za sterowcem", "跟隨"],
	"Hinterher + Lage": ["Chase + attitude", "Poursuite + assiette", "Persecución + actitud", "Inseguimento + assetto", "Za lodí + náklon", "Za sterowcem + przechył", "跟隨＋姿態"],
	"Perspektive": ["View", "Vue", "Vista", "Vista", "Pohled", "Widok", "視角"],
	"Akku leer": ["Battery empty", "Batterie vide", "Batería vacía", "Batteria scarica", "Baterie vybitá", "Akumulator pusty", "電池耗盡"],
	# --- Modell & Bau ---
	"Location": ["Location", "Lieu", "Ubicación", "Località", "Místo", "Miejsce", "場地"],
	"Modell": ["Model", "Modèle", "Modelo", "Modello", "Model", "Model", "模型"],
	"Pylonabstand": ["Pylon distance", "Distance des pylônes", "Distancia entre pilones", "Distanza piloni", "Vzdálenost pylonů", "Odległość pylonów", "標竿距離"],
	"Halle": ["Hall", "Hall", "Pabellón", "Padiglione", "Hala", "Hala", "室內場館"],
	"Wiese": ["Meadow", "Pré", "Prado", "Prato", "Louka", "Łąka", "草地"],
	"Eigenbau": ["Custom build", "Construction perso", "Construcción propia", "Costruzione propria", "Vlastní stavba", "Własna konstrukcja", "自行設計"],
	"Neues Modell oder Kopie bearbeiten": ["New model or edit a copy", "Nouveau modèle ou copie à modifier", "Modelo nuevo o editar una copia", "Nuovo modello o modifica una copia", "Nový model nebo úprava kopie", "Nowy model lub edycja kopii", "新模型或編輯副本"],
	"Bearbeiten": ["Edit", "Modifier", "Editar", "Modifica", "Upravit", "Edytuj", "編輯"],
	"Exportieren": ["Export", "Exporter", "Exportar", "Esporta", "Exportovat", "Eksportuj", "匯出"],
	"Zurück zum Flug": ["Back to flight", "Retour au vol", "Volver al vuelo", "Torna al volo", "Zpět k letu", "Powrót do lotu", "返回飛行"],
	"Regler (PID)": ["Controller (PID)", "Régulateur (PID)", "Controlador (PID)", "Regolatore (PID)", "Regulátor (PID)", "Regulator (PID)", "控制器（PID）"],
	"Autor": ["Author", "Auteur", "Autor", "Autore", "Autor", "Autor", "作者"],
	"Team": ["Team", "Équipe", "Equipo", "Team", "Tým", "Zespół", "團隊"],
	"Export: Modell als Datei speichern. Schick sie an den Admin – geprüfte Modelle werden als Standardmodell für alle aufgenommen.": [
		"Export: save the model as a file. Send it to the admin – checked models are added as standard models for everyone.",
		"Export : enregistrer le modèle dans un fichier. Envoie-le à l'administrateur – les modèles vérifiés deviennent des modèles standard pour tous.",
		"Exportar: guardar el modelo como archivo. Envíalo al administrador: los modelos revisados se añaden como modelos estándar para todos.",
		"Esporta: salva il modello come file. Invialo all'amministratore – i modelli verificati diventano modelli standard per tutti.",
		"Export: uložit model jako soubor. Pošli ho správci – ověřené modely se přidají jako standardní pro všechny.",
		"Eksport: zapisz model jako plik. Wyślij go administratorowi – sprawdzone modele zostaną dodane jako standardowe dla wszystkich.",
		"匯出：將模型存成檔案並寄給管理員，審核後會成為所有人可用的標準模型。"],
	# --- Über ---
	# --- Ergänzungen 10.11.2026 (Startseite, Modell & Bau, Autopilot, Kalibrieren) ---
	"Einstellungen": ["Settings", "Paramètres", "Ajustes", "Impostazioni", "Nastavení", "Ustawienia", "設定"],
	"Danke! Der Spendenlink folgt.": ["Thank you! The donation link is coming soon.", "Merci ! Le lien de don arrive bientôt.", "¡Gracias! El enlace de donación llegará pronto.", "Grazie! Il link per le donazioni arriverà presto.", "Děkuji! Odkaz na příspěvek bude brzy.", "Dziękuję! Link do wsparcia wkrótce.", "謝謝！贊助連結即將推出。"],
	"Bahn verloren": ["lost the track", "trajectoire perdue", "trayectoria perdida", "traiettoria persa", "ztratil dráhu", "zgubił trasę", "偏離航線"],
	"Werkseinstellung": ["Factory defaults", "Réglages d'usine", "Valores de fábrica", "Impostazioni di fabbrica", "Tovární nastavení", "Ustawienia fabryczne", "原廠設定"],
	"Abbrechen": ["Cancel", "Annuler", "Cancelar", "Annulla", "Zrušit", "Anuluj", "取消"],
	"Mitte übernehmen": ["Set centre", "Prendre le centre", "Fijar centro", "Imposta centro", "Nastavit střed", "Ustaw środek", "設定中立點"],
	"Speichern": ["Save", "Enregistrer", "Guardar", "Salva", "Uložit", "Zapisz", "儲存"],
	"Halle FN": ["Hall FN", "Hall FN", "Pabellón FN", "Padiglione FN", "Hala FN", "Hala FN", "FN 室內場館"],
	"Bestenliste": ["Leaderboard", "Classement", "Clasificación", "Classifica", "Žebříček", "Ranking", "排行榜"],
	"Zu geringe Rechenleistung, Klang vereinfacht": ["Not enough performance, sound simplified", "Puissance insuffisante, son simplifié", "Rendimiento insuficiente, sonido simplificado", "Prestazioni insufficienti, suono semplificato", "Nedostatečný výkon, zvuk zjednodušen", "Za mała wydajność, dźwięk uproszczony", "效能不足，音效已簡化"],
	"Fertig": ["Done", "Terminé", "Listo", "Fatto", "Hotovo", "Gotowe", "完成"],
	"Grundlagen des Simulators": ["Simulator fundamentals", "Bases du simulateur", "Fundamentos del simulador", "Fondamenti del simulatore", "Základy simulátoru", "Podstawy symulatora", "模擬器原理"],
	"Physik": ["Physics", "Physique", "Física", "Fisica", "Fyzika", "Fizyka", "物理"],
	"Luftschiff-Modell": ["Airship model", "Modèle de dirigeable", "Modelo del dirigible", "Modello del dirigibile", "Model vzducholodě", "Model sterowca", "飛艇模型"],
	"Akku": ["Battery", "Batterie", "Batería", "Batteria", "Baterie", "Akumulator", "電池"],
	"Über / Lizenz": ["About / license", "À propos / licence", "Acerca de / licencia", "Info / licenza", "O aplikaci / licence", "O programie / licencja", "關於／授權"],
	"Kontakt": ["Contact", "Contact", "Contacto", "Contatto", "Kontakt", "Kontakt", "聯絡"],
	"Schließen": ["Close", "Fermer", "Cerrar", "Chiudi", "Zavřít", "Zamknij", "關閉"],
	"Sprache": ["Language", "Langue", "Idioma", "Lingua", "Jazyk", "Język", "語言"],
}


## Beim Start einmal aufrufen: Übersetzungen anlegen, gespeicherte Sprache setzen.
static func setup() -> void:
	if not _built:
		for li in range(1, LANGS.size()):
			var tr_res := Translation.new()
			tr_res.locale = LANGS[li]
			for src in TEXTS:
				var row: Array = TEXTS[src]
				if li - 1 < row.size() and str(row[li - 1]) != "":
					tr_res.add_message(src, row[li - 1])
			TranslationServer.add_translation(tr_res)
		_built = true
	var cfg := ConfigFile.new()
	var lang := "de"
	if cfg.load(SETTINGS_PATH) == OK:
		lang = str(cfg.get_value("sprache", "code", "de"))
	set_language(lang, false)


## Sprache wechseln (alle Knöpfe und Labels übersetzen sich selbst).
static func set_language(code: String, save := true) -> void:
	current = code if code in LANGS else "de"
	TranslationServer.set_locale(current)
	if save:
		var cfg := ConfigFile.new()
		cfg.set_value("sprache", "code", current)
		cfg.save(SETTINGS_PATH)


## Flagge der Sprache als kleines Bild (SVG → Textur; läuft ohne Emoji-Schrift).
static func flag(code: String, w := 30) -> Texture2D:
	var key := "%s_%d" % [code, w]
	if _flags.has(key):
		return _flags[key]
	var img := Image.new()
	img.load_svg_from_string(_flag_svg(code), float(w) / 30.0)
	var tex := ImageTexture.create_from_image(img)
	_flags[key] = tex
	return tex


static func _flag_svg(code: String) -> String:
	var body := ""
	match code:
		"de": body = '<rect width="30" height="20" fill="#FFCE00"/><rect width="30" height="13.33" fill="#DD0000"/><rect width="30" height="6.67" fill="#000"/>'
		"en": body = ('<rect width="30" height="20" fill="#012169"/><path d="M0 0L30 20M30 0L0 20" stroke="#fff" stroke-width="4"/>'
			+ '<path d="M0 0L30 20M30 0L0 20" stroke="#C8102E" stroke-width="1.5"/><path d="M15 0V20M0 10H30" stroke="#fff" stroke-width="6"/>'
			+ '<path d="M15 0V20M0 10H30" stroke="#C8102E" stroke-width="3.5"/>')
		"fr": body = '<rect width="10" height="20" fill="#002395"/><rect x="10" width="10" height="20" fill="#fff"/><rect x="20" width="10" height="20" fill="#ED2939"/>'
		"es": body = '<rect width="30" height="20" fill="#AA151B"/><rect y="5" width="30" height="10" fill="#F1BF00"/>'
		"it": body = '<rect width="10" height="20" fill="#009246"/><rect x="10" width="10" height="20" fill="#fff"/><rect x="20" width="10" height="20" fill="#CE2B37"/>'
		"cs": body = '<rect width="30" height="20" fill="#D7141A"/><rect width="30" height="10" fill="#fff"/><path d="M0 0L15 10L0 20Z" fill="#11457E"/>'
		"pl": body = '<rect width="30" height="20" fill="#DC143C"/><rect width="30" height="10" fill="#fff"/>'
		"zh_TW":
			body = '<rect width="30" height="20" fill="#FE0000"/><rect width="15" height="10" fill="#000095"/><g transform="translate(7.5 5)">'
			for i in 12:
				body += '<path d="M0 -3.6 L0.75 -1.6 L-0.75 -1.6Z" fill="#fff" transform="rotate(%d)"/>' % (i * 30)
			body += '<circle r="1.9" fill="#000095"/><circle r="1.6" fill="#fff"/></g>'
	return '<svg xmlns="http://www.w3.org/2000/svg" width="30" height="20" viewBox="0 0 30 20">' + body + '</svg>'
