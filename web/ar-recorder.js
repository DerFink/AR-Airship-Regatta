// 2026-11-17 00:35 – Texte übersetzbar (arRec.setTexts)
// 2026-11-17 00:20 – Erstversion: Rennen im Browser als Film aufnehmen (MP4, sonst WebM), danach Fenster zum Zuschneiden
// =============================================================================
// ar-recorder.js  (wird vom Build in die Seite ar-<Nr>.html eingebunden, VOR Godot)
// -----------------------------------------------------------------------------
// Godot (ui/race_recorder.gd) ruft über JavaScriptBridge:
//   arRec.supported()            → Aufnahme möglich? (MediaRecorder + captureStream)
//   arRec.start(mitTon)          → Aufnahme des Spielbilds (Canvas, 30 Bilder/s) starten
//   arRec.mark("Runde 1")        → Marke auf der Zeitleiste (Start, Runden, Ziel)
//   arRec.elapsed()              → Sekunden seit Aufnahmebeginn
//   arRec.stop("Name", true)     → beenden; true = Schneidefenster öffnen
// Ton: Dieses Skript läuft vor Godot. Es merkt sich jede Verbindung eines
// Audio-Knotens zum Lautsprecher und führt sie zusätzlich auf einen
// Aufnahme-Ausgang – so kommt der Motorklang mit in den Film.
// Schneiden: Der gewählte Ausschnitt wird einmal abgespielt, auf eine
// unsichtbare Zeichenfläche kopiert und dabei neu aufgenommen (dauert so lange
// wie der Ausschnitt). Alles bleibt im Browser, nichts wird hochgeladen.
// =============================================================================
(function () {
  "use strict";

  // --- 1. Ton abzweigen (vor Godots Audio-Start) -----------------------------
  let audioDest = null;                       // MediaStreamDestination des Spiel-Tons
  const origConnect = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function (target, ...rest) {
    const result = origConnect.call(this, target, ...rest);
    try {
      if (target instanceof AudioDestinationNode) {
        if (!audioDest || audioDest.context !== target.context) {
          audioDest = target.context.createMediaStreamDestination();
        }
        origConnect.call(this, audioDest);
      }
    } catch (e) { /* Ton ist Zugabe – Fehler hier dürfen das Spiel nicht stören */ }
    return result;
  };

  // Texte des Schneidefensters (Godot setzt sie in der eingestellten Sprache)
  const T = {
    title: "Aufnahme", discard: "Verwerfen", saveAll: "Ganz speichern", cut: "Zuschneiden & speichern",
    cutting: "Schneide …", section: "Ausschnitt",
    help: "Anfang und Ende mit den blauen Griffen setzen (rasten an Start, Runden und Ziel ein). Zuschneiden spielt den Ausschnitt einmal ab und nimmt ihn neu auf – das dauert so lange wie der Ausschnitt.",
    file: "Datei",
  };

  const R = {
    state: "idle",          // idle | rec | ready
    mime: "",
    chunks: [],
    blob: null,
    t0: 0,
    dur: 0,
    marks: [],
    name: "Rennen",
    rec: null,
  };

  // --- 2. Aufnahme ------------------------------------------------------------
  R.setTexts = function (json) {
    try { Object.assign(T, JSON.parse(json)); } catch (e) { /* Standardtexte bleiben */ }
  };

  R.supported = function () {
    return !!(window.MediaRecorder && HTMLCanvasElement.prototype.captureStream);
  };

  // MP4, wo der Browser es kann (Chrome/Edge/Safari), sonst WebM (Firefox)
  R.pickMime = function () {
    const types = [
      "video/mp4;codecs=avc1.42E01E,mp4a.40.2", "video/mp4;codecs=avc1", "video/mp4",
      "video/webm;codecs=vp9,opus", "video/webm;codecs=vp8,opus", "video/webm",
    ];
    for (const t of types) {
      if (MediaRecorder.isTypeSupported(t)) return t;
    }
    return "";
  };

  R.ext = function () { return R.mime.startsWith("video/mp4") ? "mp4" : "webm"; };

  // Aufnahme aus einem Bild-Strom (+ optional Ton) mit einheitlichen Einstellungen
  function makeRecorder(stream, onStop) {
    const opts = { videoBitsPerSecond: 6000000 };
    if (R.mime) opts.mimeType = R.mime;
    const chunks = [];
    const rec = new MediaRecorder(stream, opts);
    rec.ondataavailable = (e) => { if (e.data && e.data.size) chunks.push(e.data); };
    rec.onstop = () => onStop(new Blob(chunks, { type: R.mime || "video/webm" }));
    rec.start(1000);
    return rec;
  }

  R.start = function (withAudio) {
    if (R.state === "rec" || !R.supported()) return "";
    const canvas = document.querySelector("canvas");
    if (!canvas) return "";
    R.mime = R.pickMime();
    const stream = canvas.captureStream(30);
    if (withAudio && audioDest) {
      audioDest.stream.getAudioTracks().forEach((t) => stream.addTrack(t));
    }
    R.marks = [];
    R.blob = null;
    R.t0 = performance.now();
    R.rec = makeRecorder(stream, (blob) => {
      R.blob = blob;
      R.dur = (performance.now() - R.t0) / 1000;
      R.state = "ready";
      if (R._openEditor) R.editor();
    });
    R.state = "rec";
    return R.mime;
  };

  R.elapsed = function () { return R.state === "rec" ? (performance.now() - R.t0) / 1000 : 0; };

  R.mark = function (label) {
    if (R.state === "rec") R.marks.push({ t: (performance.now() - R.t0) / 1000, label: String(label) });
  };

  R.stop = function (name, openEditor) {
    if (R.state !== "rec" || !R.rec) return;
    R.name = String(name || "Rennen").replace(/[^\w\-]+/g, "_");
    R._openEditor = !!openEditor;
    R.rec.stop();
    R.rec = null;
  };

  R.save = function (blob, suffix) {
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = R.name + (suffix || "") + "." + R.ext();
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 60000);
  };

  // --- 3. Schneidefenster ------------------------------------------------------
  //   ┌ Aufnahme · Name ─────── [Verwerfen] [Ganz speichern] [Zuschneiden & speichern] ┐
  //   │ Video-Vorschau                                                                 │
  //   │ Zeitleiste: blaue Griffe Anfang/Ende, gelbe Marken Start/Runden/Ziel            │
  //   └────────────────────────────────────────────────────────────────────────────────┘
  const CSS = `
  #arrec{position:fixed;inset:0;z-index:99999;background:rgba(8,12,18,.82);display:flex;align-items:center;justify-content:center;
    font:15px system-ui,"Segoe UI",Roboto,sans-serif;color:#e6e9ee}
  #arrec .w{background:#121a24;border:1px solid #2c3746;border-radius:12px;padding:12px 16px;width:min(900px,94vw);max-height:94vh;overflow:auto;box-sizing:border-box}
  #arrec .h{display:flex;flex-wrap:wrap;gap:8px;align-items:center;justify-content:space-between;margin-bottom:8px}
  #arrec .t{font-size:18px;font-weight:600}
  #arrec button{background:#1b2531;color:#e6e9ee;border:1px solid #3a4758;border-radius:8px;padding:5px 12px;font:inherit;cursor:pointer}
  #arrec button.p{border-color:#2f7de1}
  #arrec button:disabled{opacity:.5;cursor:default}
  #arrec video{width:100%;max-height:52vh;background:#000;border-radius:8px}
  #arrec .tl{position:relative;height:38px;margin:12px 0 4px;background:#1b2531;border-radius:6px;touch-action:none;user-select:none}
  #arrec .sel{position:absolute;top:0;bottom:0;background:rgba(47,125,225,.25)}
  #arrec .hd{position:absolute;top:-4px;bottom:-4px;width:12px;margin-left:-6px;background:#2f7de1;border-radius:4px;cursor:ew-resize}
  #arrec .mk{position:absolute;top:-4px;bottom:-4px;width:2px;background:#ffcf9a}
  #arrec .mk span{position:absolute;top:40px;left:-30px;width:60px;text-align:center;font-size:11px;color:#ffcf9a}
  #arrec .ph{position:absolute;top:-6px;bottom:-6px;width:2px;background:#fff}
  #arrec .l{display:flex;justify-content:space-between;color:#9aa3ad;font-size:13px;margin-top:18px}
  #arrec .m{color:#9aa3ad;font-size:13px;margin-top:6px}`;

  function fmt(s) {
    s = Math.max(0, s);
    const m = Math.floor(s / 60);
    return m + ":" + (s - m * 60).toFixed(1).padStart(4, "0").replace(".", ",");
  }

  R.editor = function () {
    if (!R.blob) return;
    if (document.fullscreenElement) document.exitFullscreen().catch(() => {});
    const old = document.getElementById("arrec");
    if (old) old.remove();
    if (!document.getElementById("arrec-css")) {
      const st = document.createElement("style");
      st.id = "arrec-css";
      st.textContent = CSS;
      document.head.appendChild(st);
    }
    const dur = Math.max(R.dur, 0.5);
    let a = 0, b = dur;
    // Vorschlag: 2 s vor dem Start bis 2 s nach dem Ziel
    const st = R.marks.find((m) => m.label === "Start");
    const zi = R.marks.find((m) => m.label === "Ziel");
    if (st) a = Math.max(0, st.t - 2);
    if (zi) b = Math.min(dur, zi.t + 2);

    const root = document.createElement("div");
    root.id = "arrec";
    root.innerHTML = `<div class="w">
      <div class="h"><span class="t"></span><span>
        <button data-k="x"></button> <button data-k="all"></button>
        <button class="p" data-k="cut"></button></span></div>
      <video controls playsinline></video>
      <div class="tl"><div class="sel"></div></div>
      <div class="l"><span>0:00,0</span><span class="ab"></span><span>${fmt(dur)}</span></div>
      <div class="m"><span class="hp"></span> <span class="fl"></span></div></div>`;
    document.body.appendChild(root);
    root.querySelector(".t").textContent = T.title + " · " + R.name.replace(/_/g, " ");
    root.querySelector('[data-k="x"]').textContent = T.discard;
    root.querySelector('[data-k="all"]').textContent = T.saveAll;
    root.querySelector('[data-k="cut"]').textContent = T.cut;
    root.querySelector(".hp").textContent = T.help;
    root.querySelector(".fl").textContent = T.file + ": " + R.name + "." + R.ext();
    const video = root.querySelector("video");
    const tl = root.querySelector(".tl");
    const sel = root.querySelector(".sel");
    const ab = root.querySelector(".ab");
    video.src = URL.createObjectURL(R.blob);
    // Aufnahmen ohne Längenangabe (WebM aus Chrome): einmal ans Ende springen,
    // danach kennt das Video seine Länge und lässt sich spulen
    video.addEventListener("loadedmetadata", () => {
      if (!isFinite(video.duration)) {
        video.currentTime = 1e7;
        video.addEventListener("seeked", () => { video.currentTime = a; }, { once: true });
      } else {
        video.currentTime = a;
      }
    }, { once: true });

    // Marken und Griffe
    for (const m of R.marks) {
      const d = document.createElement("div");
      d.className = "mk";
      d.style.left = (100 * m.t / dur) + "%";
      d.innerHTML = "<span></span>";
      d.firstChild.textContent = m.label;
      tl.appendChild(d);
    }
    const ha = document.createElement("div"); ha.className = "hd";
    const hb = document.createElement("div"); hb.className = "hd";
    const ph = document.createElement("div"); ph.className = "ph";
    tl.append(ha, hb, ph);
    function draw() {
      ha.style.left = (100 * a / dur) + "%";
      hb.style.left = (100 * b / dur) + "%";
      sel.style.left = (100 * a / dur) + "%";
      sel.style.width = (100 * (b - a) / dur) + "%";
      ab.textContent = T.section + " " + fmt(a) + " – " + fmt(b) + " (" + fmt(b - a) + ")";
    }
    draw();
    video.addEventListener("timeupdate", () => { ph.style.left = (100 * Math.min(video.currentTime, dur) / dur) + "%"; });
    // Ziehen der Griffe (Maus und Finger), Einrasten an Marken (±0,4 s)
    function drag(handle, setter) {
      handle.addEventListener("pointerdown", (e) => {
        e.preventDefault();
        handle.setPointerCapture(e.pointerId);
        const move = (ev) => {
          const r = tl.getBoundingClientRect();
          let t = Math.min(Math.max((ev.clientX - r.left) / r.width, 0), 1) * dur;
          for (const m of R.marks) if (Math.abs(m.t - t) < 0.4) t = m.t;
          setter(t);
          draw();
          video.currentTime = t;
        };
        const up = () => { handle.removeEventListener("pointermove", move); handle.removeEventListener("pointerup", up); };
        handle.addEventListener("pointermove", move);
        handle.addEventListener("pointerup", up);
      });
    }
    drag(ha, (t) => { a = Math.min(t, b - 0.5); });
    drag(hb, (t) => { b = Math.max(t, a + 0.5); });

    const close = () => { URL.revokeObjectURL(video.src); root.remove(); R.state = "idle"; R.blob = null; };
    root.querySelector('[data-k="x"]').onclick = close;
    root.querySelector('[data-k="all"]').onclick = () => { R.save(R.blob, ""); close(); };
    root.querySelector('[data-k="cut"]').onclick = (ev) => {
      const btns = root.querySelectorAll("button");
      btns.forEach((x) => { x.disabled = true; });
      ev.target.textContent = T.cutting;
      R.trim(video, a, b, (blob) => { R.save(blob, ""); close(); });
    };
  };

  // Ausschnitt [a, b] abspielen und neu aufnehmen (Bild über Zeichenfläche, Ton über WebAudio)
  R.trim = function (video, a, b, done) {
    const cv = document.createElement("canvas");
    cv.width = video.videoWidth || 1280;
    cv.height = video.videoHeight || 720;
    const g = cv.getContext("2d");
    const stream = cv.captureStream(30);
    let ctx = null;
    try {
      ctx = new AudioContext();
      const src = ctx.createMediaElementSource(video);
      const d = ctx.createMediaStreamDestination();
      src.connect(d);
      d.stream.getAudioTracks().forEach((t) => stream.addTrack(t));
    } catch (e) { /* ohne Ton schneiden */ }
    video.controls = false;
    video.muted = false;
    video.currentTime = a;
    video.addEventListener("seeked", () => {
      const rec = makeRecorder(stream, (blob) => { if (ctx) ctx.close(); done(blob); });
      let raf = 0;
      const tick = () => {
        g.drawImage(video, 0, 0, cv.width, cv.height);
        if (video.currentTime >= b || video.ended) {
          video.pause();
          rec.stop();
          return;
        }
        raf = requestAnimationFrame(tick);
      };
      video.play().then(() => { raf = requestAnimationFrame(tick); }).catch(() => rec.stop());
    }, { once: true });
  };

  window.arRec = R;
})();
