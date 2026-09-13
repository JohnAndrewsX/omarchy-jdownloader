// Pure helpers for the JDownloader widget: text, glyphs, formats.
// No process or file access here — that lives in Service.qml.
// Functions that produce user-visible text take a `tr(key, args)` callback
// so the language is decided in one place (Service.language + Lang.js).

.pragma library

var GLYPH = {
  download: "󰇚",     // nf-md-download
  folderDown: "󰉍",   // nf-md-folder_download
  folder: "󰉋",       // nf-md-folder
  folderOpen: "󰝰",   // nf-md-folder_open
  refresh: "󰑐",      // nf-md-refresh
  close: "󰅖",        // nf-md-close
  play: "󰐊",         // nf-md-play
  power: "󰐥",        // nf-md-power
  paste: "󰆒",        // nf-md-content_paste
  plus: "󰐕",         // nf-md-plus
  cog: "󰒓",          // nf-md-cog
  minimize: "󰖰",     // nf-md-window_minimize
  maximize: "󰖯",     // nf-md-window_maximize
  restart: "󰜉",      // nf-md-restart
  file: "󰈔",
  image: "󰋩",
  video: "󰈫",
  audio: "󰈣",
  archive: "󰗄",      // nf-md-zip_box
  document: "󰈙"
}

var IMAGE = ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "heic", "avif"]
var VIDEO = ["mkv", "mp4", "avi", "mov", "webm", "m4v", "ts", "wmv"]
var AUDIO = ["mp3", "flac", "ogg", "opus", "m4a", "wav", "aac"]
var ARCHIVE = ["zip", "rar", "7z", "tar", "gz", "xz", "bz2", "zst", "iso", "dlc", "part1"]
var DOCUMENT = ["pdf", "epub", "txt", "md", "doc", "docx", "odt", "cbz", "cbr"]

function extension(name) {
  var s = String(name || "")
  var dot = s.lastIndexOf(".")
  return dot > 0 ? s.slice(dot + 1).toLowerCase() : ""
}

function fileGlyph(name) {
  var ext = extension(name)
  if (IMAGE.indexOf(ext) !== -1) return GLYPH.image
  if (VIDEO.indexOf(ext) !== -1) return GLYPH.video
  if (AUDIO.indexOf(ext) !== -1) return GLYPH.audio
  if (ARCHIVE.indexOf(ext) !== -1) return GLYPH.archive
  if (DOCUMENT.indexOf(ext) !== -1) return GLYPH.document
  return GLYPH.file
}

// Foreign strings (file names, window titles) end up in shared shell
// components whose Text sinks are not ours — defuse angle brackets.
function plain(text) {
  return String(text === undefined || text === null ? "" : text).replace(/</g, "‹").replace(/>/g, "›")
}

function formatBytes(bytes) {
  var value = Number(bytes || 0)
  if (!isFinite(value) || value <= 0) return "0 B"
  var units = ["B", "KB", "MB", "GB", "TB"]
  var index = 0
  while (value >= 1000 && index < units.length - 1) { value = value / 1000; index++ }
  var decimals = value >= 100 || index === 0 ? 0 : (value >= 10 ? 1 : 2)
  return value.toFixed(decimals).replace(/\.0+$/, "").replace(/(\.\d)0$/, "$1") + " " + units[index]
}

function ago(tr, epochSeconds, nowMs) {
  var t = Number(epochSeconds || 0) * 1000
  if (!isFinite(t) || t <= 0) return ""
  var diff = Math.max(0, (nowMs || Date.now()) - t)
  var m = Math.floor(diff / 60000)
  if (m < 1) return tr("time.justNow")
  if (m < 60) return tr("time.minutes", { n: m })
  var h = Math.floor(m / 60)
  if (h < 24) return tr("time.hours", { n: h })
  var d = Math.floor(h / 24)
  if (d < 7) return tr("time.days", { n: d })
  var date = new Date(t)
  var dd = ("0" + date.getDate()).slice(-2), mm = ("0" + (date.getMonth() + 1)).slice(-2)
  return date.getFullYear() + "-" + mm + "-" + dd
}

function shortPath(path, home) {
  var p = String(path || "")
  if (home && p.indexOf(home) === 0) return "~" + p.slice(home.length)
  return p
}

function expandHome(path, home) {
  return String(path || "").replace(/^~(?=\/|$)/, home || "")
}

function baseName(path) {
  var p = String(path || "").replace(/\/+$/, "")
  var i = p.lastIndexOf("/")
  return i === -1 ? p : p.slice(i + 1)
}

function fileMeta(tr, file, home, nowMs) {
  if (!file) return ""
  var parts = [formatBytes(file.size)]
  var when = ago(tr, file.mtime, nowMs)
  if (when) parts.push(when)
  if (file.dir) parts.push(shortPath(file.dir, home))
  return parts.join(" · ")
}

// One honest sentence for the hero line.
function statusText(tr, s) {
  if (!s || !s.known) return tr("status.checking")
  if (s.starting) return tr("status.starting")
  if (!s.running && !s.alive) return tr("status.notRunning")
  if (!s.running && s.alive) return tr("status.noWindow")
  if (s.hidden) return tr("status.hidden")
  var ws = s.workspace && s.workspace.name ? tr("status.onWorkspace", { name: s.workspace.name }) : ""
  return (s.focused ? tr("status.focused") : tr("status.visible")) + ws
}

function heroMeta(tr, s, activeCount, unseenCount) {
  var base = statusText(tr, s)
  var extra = []
  if (activeCount > 0) extra.push(tr("meta.inProgress", { n: activeCount }))
  if (unseenCount > 0) extra.push(tr("meta.newlyFinished", { n: unseenCount }))
  return extra.length ? base + " · " + extra.join(" · ") : base
}

function barTooltip(tr, s, activeCount, unseenCount, version) {
  var lines = ["JDownloader" + (version ? " (" + version + ")" : "")]
  lines.push(statusText(tr, s))
  if (activeCount > 0) lines.push(tr("tooltip.inProgress", { n: activeCount }))
  if (unseenCount > 0) lines.push(tr("tooltip.unseen", { n: unseenCount }))
  return lines.join("\n")
}

function toggleHint(tr, s, clickAction) {
  if (!s || !s.known) return "JDownloader"
  if (!s.running) return tr("hint.launch")
  if (s.hidden) return tr("hint.show")
  if (s.focused && clickAction === "hide") return tr("hint.hide")
  return tr("hint.focus")
}

// Classify a line from the inotify stream ("EVENTS\tPATH").
//   MOVED_TO\t/path/name.mkv              → finished (JD renames the .part)
//   CLOSE_WRITE,CLOSE\t/path/x            → finished (small files skip .part)
//   CREATE\t/path/name.part               → active
//   MOVED_TO\t…/cfg/…GeneralSettings.json → configuration rewritten
function classifyEvent(line) {
  var text = String(line || "")
  var tab = text.indexOf("\t")
  if (tab === -1) return null
  var events = text.slice(0, tab).toUpperCase()
  var path = text.slice(tab + 1)
  var name = baseName(path)
  if (name === "org.jdownloader.settings.GeneralSettings.json") return { kind: "cfg", path: path }
  if (path.indexOf("/.jd/cfg/") !== -1 || path.indexOf("/opt/JDownloader/cfg/") !== -1) return { kind: "ignore", path: path }
  if (name.charAt(0) === ".") return { kind: "ignore", path: path }
  var isPart = name.slice(-5) === ".part"
  var isDir = events.indexOf("ISDIR") !== -1
  if (isDir) return { kind: "dir", path: path }
  if (isPart) {
    if (events.indexOf("CREATE") !== -1 || events.indexOf("MOVED_TO") !== -1) return { kind: "active", path: path }
    return { kind: "activity", path: path }
  }
  if (events.indexOf("MOVED_TO") !== -1 || events.indexOf("CLOSE_WRITE") !== -1) return { kind: "finished", path: path, name: name }
  if (events.indexOf("DELETE") !== -1 || events.indexOf("MOVED_FROM") !== -1) return { kind: "removed", path: path }
  return { kind: "activity", path: path }
}

// Whole numbers only: Java's X11 backend truncates the UI scale
// (X11GraphicsDevice.initScaleFactor: `return (int) debugScale`), so 1.25
// would silently be 1. The widget offers nothing that does not work.
var SCALE_VALUES = ["1", "2", "3"]
var SMOOTHING_VALUES = ["on", "lcd", "off"]
var CLICK_VALUES = ["hide", "focus"]
var LANGUAGE_VALUES = ["auto", "en", "de"]

function options(tr, prefix, values) {
  return values.map(function(v) { return { value: v, label: tr(prefix + "." + v) } })
}

function normalizeScale(value) {
  var n = parseFloat(String(value === undefined || value === null ? "" : value))
  if (!isFinite(n) || n < 1) return "1"
  return String(Math.max(1, Math.min(3, Math.floor(n))))
}
