# 2026-11-11 16:40 – Rennanzeige rechts (Runde, Gesamt, Gewertet)
# 2026-11-11 15:40 – Stickmode 1–4
# 2026-11-11 14:45 – Erstversion: Übersetzungen Teil 4 (Aufprall und Platzen)
# Spalten: de, en, fr, es, it, cs, pl, zh_TW
E = [
("Nähte geplatzt – Luftschiff kaputt · Zurücksetzen = neues Luftschiff", "Seams burst – airship wrecked · Reset = new airship", "Coutures éclatées – dirigeable détruit · Réinitialiser = nouveau dirigeable", "Costuras reventadas: dirigible destrozado · Reiniciar = dirigible nuevo", "Cuciture scoppiate – dirigibile distrutto · Ripristina = nuovo dirigibile", "Švy praskly – vzducholoď je zničená · Reset = nová vzducholoď", "Szwy pękły – sterowiec zniszczony · Reset = nowy sterowiec", "接縫爆裂——飛艇已損毀 · 重設 = 新飛艇"),
("Hülle platzt bei zu hartem Aufprall", "Envelope bursts on a hard impact", "L'enveloppe éclate en cas de choc trop violent", "La envolvente revienta con un impacto fuerte", "L'involucro scoppia con un urto troppo forte", "Obal praskne při příliš tvrdém nárazu", "Powłoka pęka przy zbyt mocnym uderzeniu", "撞擊過猛時艇身會爆裂"),
("Platzt ab (senkrecht zur Wand)", "Bursts from (perpendicular to wall)", "Éclate à partir de (perpendiculaire au mur)", "Revienta a partir de (perpendicular a la pared)", "Scoppia da (perpendicolare alla parete)", "Praskne od (kolmo ke stěně)", "Pęka od (prostopadle do ściany)", "爆裂門檻（垂直撞牆速度）"),
("Mode %d · links %s + %s · rechts %s + %s", "Mode %d · left %s + %s · right %s + %s", "Mode %d · gauche %s + %s · droite %s + %s", "Modo %d · izquierda %s + %s · derecha %s + %s", "Mode %d · sinistra %s + %s · destra %s + %s", "Mode %d · vlevo %s + %s · vpravo %s + %s", "Mode %d · lewy %s + %s · prawy %s + %s", "Mode %d · 左 %s + %s · 右 %s + %s"),
("Stickmode (gilt für Sender-Anzeige, Bildschirmknüppel und Tastatur)", "Stick mode (applies to transmitter display, on-screen sticks and keyboard)", "Mode de manches (pour l'affichage de l'émetteur, les manches à l'écran et le clavier)", "Modo de sticks (para la vista de la emisora, los sticks en pantalla y el teclado)", "Modo leve (vale per la visualizzazione del radiocomando, le leve a schermo e la tastiera)", "Režim kniplů (platí pro zobrazení vysílače, knipl na obrazovce a klávesnici)", "Tryb drążków (dla widoku nadajnika, drążków na ekranie i klawiatury)", "搖桿模式（適用於遙控器顯示、螢幕搖桿與鍵盤）"),
("Gas · Rolle", "Throttle · roll", "Gaz · roulis", "Gas · alabeo", "Gas · rollio", "Plyn · klonění", "Gaz · przechył", "油門 · 滾轉"),
("Nick · Rolle", "Pitch · roll", "Tangage · roulis", "Cabeceo · alabeo", "Beccheggio · rollio", "Klopení · klonění", "Pochylenie · przechył", "俯仰 · 滾轉"),
("Runde %d", "Lap %d", "Tour %d", "Vuelta %d", "Giro %d", "Kolo %d", "Okrążenie %d", "第 %d 圈"),
("Runde %d / %d", "Lap %d / %d", "Tour %d / %d", "Vuelta %d / %d", "Giro %d / %d", "Kolo %d / %d", "Okrążenie %d / %d", "第 %d / %d 圈"),
("Ziel", "Finish", "Arrivée", "Meta", "Arrivo", "Cíl", "Meta", "終點"),
("Gesamt", "Total", "Total", "Total", "Totale", "Celkem", "Razem", "總計"),
("Gewertet", "Scored", "Classé", "Puntuado", "Valutato", "Hodnoceno", "Wynik", "計分"),
("= Gesamt × V_Box^(1/3) (Box %.2f × %.2f × %.2f m)", "= total × V_box^(1/3) (box %.2f × %.2f × %.2f m)", "= total × V_boîte^(1/3) (boîte %.2f × %.2f × %.2f m)", "= total × V_caja^(1/3) (caja %.2f × %.2f × %.2f m)", "= totale × V_box^(1/3) (box %.2f × %.2f × %.2f m)", "= celkem × V_box^(1/3) (box %.2f × %.2f × %.2f m)", "= razem × V_box^(1/3) (box %.2f × %.2f × %.2f m)", "= 總計 × V_box^(1/3)（box %.2f × %.2f × %.2f m）"),
("gespeichert ✓", "saved ✓", "enregistré ✓", "guardado ✓", "salvato ✓", "uloženo ✓", "zapisano ✓", "已儲存 ✓"),
("Bestenliste", "Leaderboard", "Classement", "Clasificación", "Classifica", "Žebříček", "Ranking", "排行榜"),
("Support", "Support", "Soutien", "Apoyo", "Supporto", "Podpora", "Wsparcie", "支持"),
("Dir gefällt der Simulator? Spendier mir ein Bier – per PayPal:", "Enjoying the simulator? Buy me a beer – via PayPal:", "Le simulateur te plaît ? Offre-moi une bière – par PayPal :", "¿Te gusta el simulador? Invítame a una cerveza por PayPal:", "Ti piace il simulatore? Offrimi una birra – con PayPal:", "Líbí se ti simulátor? Kup mi pivo – přes PayPal:", "Podoba ci się symulator? Postaw mi piwo – przez PayPal:", "喜歡這個模擬器嗎？請我喝杯啤酒——透過 PayPal："),
("PayPal öffnen", "Open PayPal", "Ouvrir PayPal", "Abrir PayPal", "Apri PayPal", "Otevřít PayPal", "Otwórz PayPal", "開啟 PayPal"),
("Schließen", "Close", "Fermer", "Cerrar", "Chiudi", "Zavřít", "Zamknij", "關閉"),
]
