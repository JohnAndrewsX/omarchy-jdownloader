// Translations for the JDownloader widget. English is the source of truth;
// every other language falls back to it key by key, so a missing string is
// never blank. Quickshell plugins have no QTranslator, hence a plain table.
//
// Keys are stable identifiers, values may contain {placeholders}.

.pragma library

var STRINGS = {
  en: {
    "status.checking": "Checking…",
    "status.starting": "Starting…",
    "status.notRunning": "Not running",
    "status.noWindow": "Running without a window",
    "status.hidden": "Tucked away",
    "status.focused": "In front",
    "status.visible": "Visible",
    "status.onWorkspace": " on workspace {name}",
    "meta.inProgress": "{n} in progress",
    "meta.newlyFinished": "{n} newly finished",
    "tooltip.inProgress": "{n} download(s) in progress",
    "tooltip.unseen": "{n} finished, not looked at yet",
    "hint.launch": "Launch JDownloader",
    "hint.show": "Bring the window back",
    "hint.hide": "Tuck the window away",
    "hint.focus": "Bring the window to the front",

    "action.link": "Link",
    "action.link.tip": "Send URLs from the clipboard to JDownloader (L)",
    "action.folder": "Folder",
    "action.folder.tip": "Open the default download folder (O)",
    "action.refresh": "Refresh",
    "action.refresh.tip": "Re-read status and folders (R)",
    "action.more": "More",
    "action.more.tip": "Show or hide settings (S)",
    "action.quit": "Quit",
    "action.quit.tip": "Close JDownloader — it asks first if it is set up that way (Q)",
    "notRunning.hint": "JDownloader is not running. Right-click the icon or press ▶ to launch it; sending a link from the clipboard launches it as well.",

    "section.inProgress": "IN PROGRESS",
    "section.finished": "FINISHED",
    "section.folders": "WATCHED FOLDERS",
    "section.appearance": "APPEARANCE",
    "list.more": "… and {n} more",
    "list.noFolders": "No folder is being watched.",
    "list.nothingYet": "Nothing in the watched folders yet.",
    "file.tip.working": "Downloading · right-click opens the folder",
    "file.tip.done": "Click opens the file · right-click the folder",
    "file.soFar": "{size} so far",

    "folders.default": "JDownloader's default folder",
    "folders.default.missing": "not found — is JDownloader running in global scope?",
    "folders.placeholder": "watch another folder, e.g. ~/Videos",
    "folders.add": "Add folder",
    "folders.added": "Folder added",
    "folders.duplicate": "Folder is already listed",
    "folders.open": "Open folder",
    "folders.remove": "Stop watching",
    "folders.missing": "Folder does not exist",
    "folders.summary": "{files} files · {bytes}",
    "folders.summary.parts": " · {n} in progress",
    "folders.note": "Only the folders listed here are watched. JDownloader can send downloads elsewhere (a per-package destination, Packagizer rules) — such files will not show up here.",

    "notify.label": "Notify when something finishes",
    "notify.description": "Desktop notification through the Omarchy shell",
    "click.label": "Right-click on a visible window",
    "click.hide": "Tuck away",
    "click.focus": "Focus only",
    "language.label": "Language",
    "language.auto": "Automatic",
    "language.en": "English",
    "language.de": "Deutsch",

    "scale.label": "Interface size",
    "scale.1": "1× — Java default",
    "scale.2": "2× — double",
    "scale.3": "3× — triple",
    "smoothing.label": "Font smoothing",
    "smoothing.on": "On (grayscale)",
    "smoothing.lcd": "Subpixel (lcd)",
    "smoothing.off": "Off",
    "appearance.note": "These are Java VM switches in ~/.local/share/applications/jdownloader.desktop — Swing reads no XSettings under Hyprland. They take effect on the next launch. Whole steps only: Java's X11 backend truncates fractions (1.5 would be 1). For \"a bit larger\" without doubling, JDownloader has its own font scaling (Advanced Settings → fontScaleFactor) that enlarges text only. Subpixel only fits a desktop that uses subpixel smoothing.",
    "restart": "Restart JDownloader",
    "restart.now": "Restart JDownloader now",
    "restart.tip": "Stops JDownloader cleanly (SIGTERM, lists are saved) and launches it again.",
    "footer.keys": "Keys: H window · L link · O folder · R refresh · S more · Q quit · Esc closes",

    "msg.launching": "JDownloader is starting…",
    "msg.closing": "Closing JDownloader…",
    "msg.clipboard": "Reading the clipboard…",
    "msg.saved": "Saved",
    "msg.savedNextStart": "Saved — takes effect on the next launch",
    "msg.restarting": "Restarting JDownloader…",
    "msg.noWindow": "No JDownloader window found",
    "msg.windowFailed": "Window action failed",
    "msg.statusFailed": "Status check failed",
    "msg.statusHung": "Status check hung and was aborted",
    "msg.scanFailed": "Folder scan failed",
    "msg.scanHung": "Folder scan hung and was aborted",
    "msg.badJson": "Helper returned no JSON",
    "msg.displayFailed": "Could not write the desktop file",
    "msg.restartFailed": "Restart failed",
    "msg.cnlFailed": "Click'n'Load failed",

    "cnl.added": "{n} link(s) handed to JDownloader",
    "cnl.no_url": "No URL found",
    "cnl.clipboard_empty": "Clipboard is empty or holds no text",
    "cnl.clipboard_no_url": "No URL in the clipboard",
    "cnl.launch_failed": "JDownloader could not be launched",
    "cnl.timeout": "JDownloader did not answer Click'n'Load within {secs}s",
    "cnl.http": "Click'n'Load answered with HTTP {code}",
    "display.invalid_scale": "Scale must be 1, 2 or 3 — Java on X11 has no in-between values",
    "display.invalid_smoothing": "Smoothing must be on, lcd or off",
    "display.no_desktop_file": "No desktop file found",
    "display.still_running": "JDownloader did not exit within 30s",

    "notification.one": "Download finished",
    "notification.many": "Downloads finished",
    "notification.files": "{n} files: {names}",

    "time.justNow": "just now",
    "time.minutes": "{n} min ago",
    "time.hours": "{n} h ago",
    "time.days": "{n} d ago"
  },

  de: {
    "status.checking": "Prüfe …",
    "status.starting": "Startet …",
    "status.notRunning": "Läuft nicht",
    "status.noWindow": "Läuft ohne Fenster",
    "status.hidden": "Weggeräumt",
    "status.focused": "Im Vordergrund",
    "status.visible": "Sichtbar",
    "status.onWorkspace": " auf Workspace {name}",
    "meta.inProgress": "{n} in Arbeit",
    "meta.newlyFinished": "{n} neu fertig",
    "tooltip.inProgress": "{n} Download(s) in Arbeit",
    "tooltip.unseen": "{n} fertig, noch nicht angesehen",
    "hint.launch": "JDownloader starten",
    "hint.show": "Fenster holen",
    "hint.hide": "Fenster wegräumen",
    "hint.focus": "Fenster in den Vordergrund",

    "action.link": "Link",
    "action.link.tip": "URLs aus der Zwischenablage an JDownloader geben (L)",
    "action.folder": "Ordner",
    "action.folder.tip": "Standard-Downloadordner öffnen (O)",
    "action.refresh": "Neu",
    "action.refresh.tip": "Status und Ordner neu einlesen (R)",
    "action.more": "Mehr",
    "action.more.tip": "Einstellungen ein- oder ausblenden (S)",
    "action.quit": "Ende",
    "action.quit.tip": "JDownloader schließen — fragt nach, wenn er so eingestellt ist (Q)",
    "notRunning.hint": "JDownloader läuft nicht. Rechtsklick auf das Symbol oder ▶ startet ihn; ein Link aus der Zwischenablage startet ihn ebenfalls.",

    "section.inProgress": "IN ARBEIT",
    "section.finished": "FERTIG",
    "section.folders": "BEOBACHTETE ORDNER",
    "section.appearance": "DARSTELLUNG",
    "list.more": "… und {n} weitere",
    "list.noFolders": "Kein Ordner wird beobachtet.",
    "list.nothingYet": "Noch nichts in den beobachteten Ordnern.",
    "file.tip.working": "Wird geladen · Rechtsklick öffnet den Ordner",
    "file.tip.done": "Klick öffnet die Datei · Rechtsklick den Ordner",
    "file.soFar": "{size} bisher",

    "folders.default": "Standardordner von JDownloader",
    "folders.default.missing": "nicht gefunden — läuft JDownloader im global scope?",
    "folders.placeholder": "weiteren Ordner beobachten, z. B. ~/Videos",
    "folders.add": "Ordner hinzufügen",
    "folders.added": "Ordner hinzugefügt",
    "folders.duplicate": "Ordner ist schon dabei",
    "folders.open": "Ordner öffnen",
    "folders.remove": "Nicht mehr beobachten",
    "folders.missing": "Ordner existiert nicht",
    "folders.summary": "{files} Dateien · {bytes}",
    "folders.summary.parts": " · {n} in Arbeit",
    "folders.note": "Beobachtet werden nur die hier gelisteten Ordner. JDownloader kann Downloads auf andere Pfade leiten (eigenes Ziel pro Paket, Packagizer-Regeln) — solche Dateien tauchen hier nicht auf.",

    "notify.label": "Benachrichtigen, wenn etwas fertig ist",
    "notify.description": "Desktop-Benachrichtigung über die Omarchy-Shell",
    "click.label": "Rechtsklick auf sichtbares Fenster",
    "click.hide": "Wegräumen",
    "click.focus": "Nur fokussieren",
    "language.label": "Sprache",
    "language.auto": "Automatisch",
    "language.en": "English",
    "language.de": "Deutsch",

    "scale.label": "Oberflächengröße",
    "scale.1": "1× — Java-Standard",
    "scale.2": "2× — doppelt",
    "scale.3": "3× — dreifach",
    "smoothing.label": "Kantenglättung",
    "smoothing.on": "An (grayscale)",
    "smoothing.lcd": "Subpixel (lcd)",
    "smoothing.off": "Aus",
    "appearance.note": "Schalter der Java-VM in ~/.local/share/applications/jdownloader.desktop — Swing liest unter Hyprland keine XSettings. Sie greifen beim nächsten Start. Nur ganze Stufen: Javas X11-Backend schneidet Zwischenwerte ab (1.5 wäre 1). Für „etwas größer“ ohne Verdopplung hat JDownloader selbst eine Schriftskalierung (Erweiterte Einstellungen → fontScaleFactor), die nur die Schrift vergrößert. Subpixel passt nur, wenn der Desktop auf Subpixel steht.",
    "restart": "JDownloader neu starten",
    "restart.now": "JDownloader jetzt neu starten",
    "restart.tip": "Beendet JDownloader sauber (SIGTERM, Listen werden gesichert) und startet ihn neu.",
    "footer.keys": "Tasten: H Fenster · L Link · O Ordner · R Neu · S Mehr · Q Ende · Esc schließt",

    "msg.launching": "JDownloader startet …",
    "msg.closing": "JDownloader wird geschlossen …",
    "msg.clipboard": "Zwischenablage wird gelesen …",
    "msg.saved": "Gespeichert",
    "msg.savedNextStart": "Gespeichert — greift beim nächsten Start",
    "msg.restarting": "JDownloader wird neu gestartet …",
    "msg.noWindow": "Kein JDownloader-Fenster gefunden",
    "msg.windowFailed": "Fensteraktion schlug fehl",
    "msg.statusFailed": "Statusabfrage schlug fehl",
    "msg.statusHung": "Statusabfrage hing und wurde abgebrochen",
    "msg.scanFailed": "Ordnerabfrage schlug fehl",
    "msg.scanHung": "Ordnerabfrage hing und wurde abgebrochen",
    "msg.badJson": "Helfer lieferte kein JSON",
    "msg.displayFailed": "Desktop-Datei ließ sich nicht schreiben",
    "msg.restartFailed": "Neustart schlug fehl",
    "msg.cnlFailed": "Click'n'Load schlug fehl",

    "cnl.added": "{n} Link(s) an JDownloader übergeben",
    "cnl.no_url": "Keine URL gefunden",
    "cnl.clipboard_empty": "Zwischenablage ist leer oder enthält keinen Text",
    "cnl.clipboard_no_url": "Keine URL in der Zwischenablage",
    "cnl.launch_failed": "JDownloader ließ sich nicht starten",
    "cnl.timeout": "JDownloader antwortet nach {secs}s nicht auf Click'n'Load",
    "cnl.http": "Click'n'Load antwortete mit HTTP {code}",
    "display.invalid_scale": "Skalierung muss 1, 2 oder 3 sein — Java auf X11 kennt keine Zwischenwerte",
    "display.invalid_smoothing": "Kantenglättung muss on, lcd oder off sein",
    "display.no_desktop_file": "Keine Desktop-Datei gefunden",
    "display.still_running": "JDownloader hat sich nach 30 s nicht beendet",

    "notification.one": "Download fertig",
    "notification.many": "Downloads fertig",
    "notification.files": "{n} Dateien: {names}",

    "time.justNow": "gerade eben",
    "time.minutes": "vor {n} min",
    "time.hours": "vor {n} h",
    "time.days": "vor {n} Tg."
  }
}

var LANGUAGES = ["en", "de"]

// Resolve "auto" against the session environment (first tag of LANGUAGE,
// then LC_ALL, LC_MESSAGES, LANG). Anything unknown becomes English.
function detect(setting, env) {
  var s = String(setting || "auto").toLowerCase()
  if (LANGUAGES.indexOf(s) !== -1) return s
  var candidates = [env.LANGUAGE, env.LC_ALL, env.LC_MESSAGES, env.LANG]
  for (var i = 0; i < candidates.length; i++) {
    var v = String(candidates[i] || "").split(":")[0].toLowerCase()
    if (v === "" || v === "c" || v === "posix") continue
    var tag = v.split(/[_.@-]/)[0]
    if (LANGUAGES.indexOf(tag) !== -1) return tag
    return "en"
  }
  return "en"
}

function t(lang, key, args) {
  var table = STRINGS[lang] || STRINGS.en
  var s = table[key]
  if (s === undefined) s = STRINGS.en[key]
  if (s === undefined) return key
  if (args) {
    for (var k in args) s = s.split("{" + k + "}").join(String(args[k]))
  }
  return s
}
