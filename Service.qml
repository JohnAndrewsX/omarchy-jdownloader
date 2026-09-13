import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Model.js" as Model
import "Lang.js" as Lang

// State and actions of the JDownloader widget. Three channels, none of which
// reads JDownloader's internals:
//   1. Hyprland (via bin/jd-window): is there a window? visible? focused?
//   2. Click'n'Load on 127.0.0.1:9666: liveness in, links out.
//   3. The file system (bin/jd-watch + bin/jd-scan): watched folders.
// Plus the desktop file carrying the JVM switches (bin/jd-display).
Item {
  id: root

  property var settings: ({})
  property string pluginDir: ""
  property string moduleName: ""

  // ---- settings -------------------------------------------------------------
  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }
  function boolSetting(name, fallback) {
    var v = setting(name, fallback)
    if (typeof v === "string") return v !== "false" && v !== "0" && v !== "off"
    return !!v
  }
  function intSetting(name, fallback, min, max) {
    var n = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(n)) n = fallback
    return Math.max(min, Math.min(max, n))
  }
  function listSetting(name) {
    var v = setting(name, [])
    if (Array.isArray(v)) return v.map(function(x) { return String(x) }).filter(function(x) { return x !== "" })
    if (typeof v === "string" && v.trim() !== "") return v.split(/[\n,]/).map(function(x) { return x.trim() }).filter(function(x) { return x !== "" })
    return []
  }

  readonly property bool watchDefaultFolder: boolSetting("watchDefaultFolder", true)
  readonly property var extraFolders: listSetting("extraFolders")
  readonly property bool notifyOnFinish: boolSetting("notifyOnFinish", true)
  readonly property string clickAction: String(setting("clickAction", "hide")) === "focus" ? "focus" : "hide"
  readonly property int recentCount: intSetting("recentCount", 8, 3, 30)
  readonly property int statusIntervalSec: intSetting("statusIntervalSec", 5, 2, 60)
  readonly property string languageSetting: String(setting("language", "auto"))

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string binDir: pluginDir + "/bin"
  readonly property bool ready: pluginDir !== "" && pluginDir.charAt(0) === "/"

  // ---- language -------------------------------------------------------------
  // English by default; "auto" follows the session locale. Bindings that call
  // tr() read `language`, so a settings change re-renders every string.
  readonly property string language: Lang.detect(languageSetting, {
    LANGUAGE: Quickshell.env("LANGUAGE"), LC_ALL: Quickshell.env("LC_ALL"),
    LC_MESSAGES: Quickshell.env("LC_MESSAGES"), LANG: Quickshell.env("LANG")
  })
  function tr(key, args) { return Lang.t(language, key, args) }

  // ---- state: window / process -----------------------------------------------
  // known=false until the first probe answered — right after a shell restart
  // hyprctl is briefly unavailable, and "not running" would be a lie.
  property var status: ({ known: false, running: false, alive: false, starting: false, hidden: false, focused: false, address: "", version: "", workspace: null })
  readonly property bool statusKnown: !!status.known
  readonly property bool running: !!status.running
  readonly property bool alive: !!status.alive
  readonly property bool hidden: !!status.hidden
  readonly property bool focused: !!status.focused
  readonly property bool starting: !!status.starting || launchPending
  readonly property string version: String(status.version || "")
  property bool launchPending: false

  // ---- state: folders -------------------------------------------------------------
  property string defaultFolder: ""
  property var folders: []        // [{path, exists, files, bytes, parts, isDefault}]
  property var active: []         // *.part files
  property var recent: []         // finished files, newest first
  property int unseenCount: 0
  property var lastFinished: []   // names finished since the panel was last opened
  readonly property var watchDirs: {
    var dirs = []
    if (watchDefaultFolder && defaultFolder !== "") dirs.push(defaultFolder)
    for (var i = 0; i < extraFolders.length; i++) {
      var p = Model.expandHome(extraFolders[i], home)
      if (dirs.indexOf(p) === -1) dirs.push(p)
    }
    return dirs
  }

  // ---- state: appearance ------------------------------------------------------
  property string uiScale: "1"
  property string smoothing: "on"
  property bool displayOverrideExists: false
  property bool displayDirty: false   // changed, JDownloader not restarted yet

  // ---- feedback -------------------------------------------------------------------
  property string actionStatus: ""
  property string lastError: ""
  property string lastFailure: ""     // sticks around for IPC summary / journal
  readonly property bool busy: actionProcess.running || cnlProcess.running || restartProcess.running
  property double nowMs: Date.now()

  function say(text) { actionStatus = String(text || ""); lastError = ""; statusResetTimer.restart() }
  function fail(text) {
    lastError = String(text || "Error"); actionStatus = ""; statusResetTimer.restart()
    lastFailure = lastError
    console.warn("io.github.johnandrewsx.jdownloader: " + lastError)
  }
  // Helper scripts answer with {code, message, args}; translate known codes,
  // fall back to the script's English message.
  function messageFor(data, fallbackKey) {
    if (data && data.code) {
      var translated = tr(data.code, data.args || {})
      if (translated !== data.code) return translated
    }
    if (data && data.message) return String(data.message)
    return tr(fallbackKey)
  }

  // ---- actions: window ----------------------------------------------------------
  function runWindow(verb, extra) {
    if (!ready || actionProcess.running) return
    var cmd = [binDir + "/jd-window", verb]
    if (extra) cmd.push(extra)
    actionProcess.command = cmd
    actionProcess.running = true
  }
  function launch() { launchPending = true; launchGuard.restart(); runWindow("launch"); say(tr("msg.launching")) }
  function show() { runWindow("show") }
  function hide() { runWindow("hide") }
  function focusWindow() { runWindow("focus") }
  function toggleWindow() {
    if (!running && !alive) { launch(); return }
    runWindow("toggle", clickAction)
  }
  function quit() { runWindow("quit"); say(tr("msg.closing")) }

  // ---- actions: Click'n'Load ----------------------------------------------------
  function addFromClipboard() {
    if (!ready || cnlProcess.running) return
    cnlProcess.command = [binDir + "/jd-cnl", "clipboard"]
    cnlProcess.running = true
    say(tr("msg.clipboard"))
  }
  function addUrls(urls) {
    if (!ready || cnlProcess.running || !urls || urls.length === 0) return
    cnlProcess.command = [binDir + "/jd-cnl", "add"].concat(urls)
    cnlProcess.running = true
  }

  // ---- actions: folders ---------------------------------------------------------------
  function openFolder(path) {
    var p = String(path || defaultFolder || "")
    if (p === "") return
    Quickshell.execDetached(["uwsm-app", "--", "xdg-open", p])
  }
  function openFile(file) {
    if (!file || !file.path) return
    Quickshell.execDetached(["uwsm-app", "--", "xdg-open", String(file.path)])
  }
  function revealFile(file) {
    if (!file || !file.dir) return
    openFolder(file.dir)
  }
  function markSeen() { unseenCount = 0; lastFinished = [] }

  // ---- actions: appearance ---------------------------------------------------------
  function refreshDisplay() {
    if (!ready || displayGetProcess.running) return
    displayGetProcess.command = [binDir + "/jd-display", "get"]
    displayGetProcess.running = true
  }
  function setDisplay(scale, smooth) {
    if (!ready || displaySetProcess.running) return
    displaySetProcess.command = [binDir + "/jd-display", "set", String(scale), String(smooth)]
    displaySetProcess.running = true
  }
  function restartJd() {
    if (!ready || restartProcess.running) return
    restartProcess.command = [binDir + "/jd-display", "restart"]
    restartProcess.running = true
    say(tr("msg.restarting"))
  }

  // ---- probes ------------------------------------------------------------------------
  function refreshStatus() {
    if (!ready || statusProcess.running) return
    statusProcess.command = [binDir + "/jd-window", "status"]
    statusProcess.running = true
    statusWatchdog.restart()
  }
  function rescan() {
    if (!ready) return
    if (scanProcess.running) { rescanDebounce.restart(); return }
    var cmd = [binDir + "/jd-scan", "--recent", String(recentCount)]
    if (!watchDefaultFolder) cmd.push("--no-default")
    for (var i = 0; i < extraFolders.length; i++) cmd.push("--extra", Model.expandHome(extraFolders[i], home))
    scanProcess.command = cmd
    scanProcess.running = true
    scanWatchdog.restart()
  }
  function refreshAll() { refreshStatus(); rescan(); refreshDisplay() }

  function applyScan(raw) {
    var data
    try { data = JSON.parse(raw) } catch (e) { fail(tr("msg.badJson")); return }
    var newDefault = String(data.defaultFolder || "")
    if (newDefault !== defaultFolder) defaultFolder = newDefault
    folders = Array.isArray(data.folders) ? data.folders : []
    active = Array.isArray(data.active) ? data.active : []
    recent = Array.isArray(data.recent) ? data.recent : []
  }

  // ---- watcher -----------------------------------------------------------------------
  property bool watcherRestartPending: false
  function restartWatcher() {
    if (!ready) return
    if (watchProcess.running) {
      // Stop the old stream first; onExited starts the new one.
      watcherRestartPending = true
      watchProcess.running = false
      return
    }
    watcherRestartPending = false
    if (watchDirs.length === 0 && defaultFolder === "") { watcherRetry.restart(); return }
    watchProcess.command = [binDir + "/jd-watch"].concat(watchDirs)
    watchProcess.running = true
  }
  onWatchDirsChanged: restartWatcher()

  function handleWatchLine(line) {
    var ev = Model.classifyEvent(line)
    if (!ev) return
    if (ev.kind === "cfg") { rescanDebounce.restart(); return }
    if (ev.kind === "finished") {
      var list = lastFinished.slice()
      if (list.indexOf(ev.name) === -1) list.push(ev.name)
      lastFinished = list
      unseenCount = unseenCount + 1
      notifyBatch.restart()
    }
    if (ev.kind !== "ignore") rescanDebounce.restart()
  }

  function flushNotification() {
    if (!notifyOnFinish || lastFinished.length === 0) return
    var names = lastFinished.slice()
    var body = names.length === 1
      ? Model.plain(names[0])
      : tr("notification.files", { n: names.length, names: Model.plain(names.slice(0, 3).join(", ")) + (names.length > 3 ? " …" : "") })
    // Through jd-notify: the bar exists per monitor, so every instance sees
    // the same events — the script lets an identical message through once.
    Quickshell.execDetached([binDir + "/jd-notify",
      names.length === 1 ? tr("notification.one") : tr("notification.many"), body])
    // The list stays for the badge until the panel is opened.
  }

  // ---- processes ---------------------------------------------------------------------
  Process {
    id: statusProcess
    running: false
    command: []
    stdout: StdioCollector { id: statusOut; waitForEnd: true }
    stderr: StdioCollector { id: statusErr; waitForEnd: true }
    onExited: function(exitCode) {
      var text = String(statusOut.text || "").trim()
      if (exitCode !== 0 || text === "") {
        root.fail(tr("msg.statusFailed") + " (exit " + exitCode + " " + String(statusErr.text || "").trim() + ")")
        return
      }
      try {
        var s = JSON.parse(text)
        s.known = true
        root.status = s
        if (s.running || s.alive) { root.launchPending = false; launchGuard.stop() }
      } catch (e) { root.fail(tr("msg.badJson")) }
    }
  }

  Process {
    id: actionProcess
    running: false
    command: []
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: actionErr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 2) root.fail(tr("msg.noWindow"))
      else if (exitCode !== 0) root.fail(tr("msg.windowFailed") + ": " + String(actionErr.text || "").trim())
      delayedStatus.restart()
    }
  }

  Process {
    id: cnlProcess
    running: false
    command: []
    stdout: StdioCollector { id: cnlOut; waitForEnd: true }
    stderr: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      var data = null
      try { data = JSON.parse(String(cnlOut.text || "").trim()) } catch (e) {}
      if (data && data.ok) root.say(root.messageFor(data, "cnl.added"))
      else root.fail(root.messageFor(data, "msg.cnlFailed"))
      delayedStatus.restart()
    }
  }

  Process {
    id: scanProcess
    running: false
    command: []
    stdout: StdioCollector { id: scanOut; waitForEnd: true }
    stderr: StdioCollector { id: scanErr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) { root.fail(tr("msg.scanFailed") + ": " + String(scanErr.text || "").trim()); return }
      root.applyScan(String(scanOut.text || ""))
    }
  }

  Process {
    id: watchProcess
    running: false
    command: []
    stdout: SplitParser { onRead: function(line) { root.handleWatchLine(line) } }
    stderr: StdioCollector { waitForEnd: false }
    onExited: function(exitCode) {
      if (root.watcherRestartPending) { root.restartWatcher(); return }
      // inotifywait exits when a folder disappears — re-arm.
      if (root.watchDirs.length > 0) watcherRetry.restart()
    }
  }

  Process {
    id: displayGetProcess
    running: false
    command: []
    stdout: StdioCollector { id: displayOut; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) return
      try {
        var d = JSON.parse(String(displayOut.text || ""))
        root.uiScale = Model.normalizeScale(d.scale)
        root.smoothing = String(d.smoothing || "off")
        root.displayOverrideExists = !!d.overrideExists
      } catch (e) {}
    }
  }

  Process {
    id: displaySetProcess
    running: false
    command: []
    stdout: StdioCollector { id: displaySetOut; waitForEnd: true }
    stderr: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      var d = null
      try { d = JSON.parse(String(displaySetOut.text || "")) } catch (e) {}
      if (exitCode !== 0 || !d || d.ok === false) { root.fail(root.messageFor(d, "msg.displayFailed")); return }
      root.uiScale = Model.normalizeScale(d.scale || root.uiScale)
      root.smoothing = String(d.smoothing || root.smoothing)
      root.displayOverrideExists = !!d.overrideExists
      root.displayDirty = root.running || root.alive
      root.say(tr(root.displayDirty ? "msg.savedNextStart" : "msg.saved"))
    }
  }

  Process {
    id: restartProcess
    running: false
    command: []
    stdout: StdioCollector { id: restartOut; waitForEnd: true }
    stderr: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      var d = null
      try { d = JSON.parse(String(restartOut.text || "")) } catch (e) {}
      if (exitCode !== 0 || (d && d.ok === false)) root.fail(root.messageFor(d, "msg.restartFailed"))
      else { root.displayDirty = false; root.launchPending = true; launchGuard.restart(); root.say(tr("msg.launching")) }
      delayedStatus.restart()
    }
  }

  // ---- timers ------------------------------------------------------------------------
  Timer {
    id: statusTimer
    interval: root.statusIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refreshStatus()
  }
  Timer { id: delayedStatus; interval: 350; repeat: false; onTriggered: root.refreshStatus() }
  Timer {
    // A probe that never returns (or never started) would block every further
    // probe. Reap after 10 s and try again.
    id: statusWatchdog; interval: 10000; repeat: false
    onTriggered: if (statusProcess.running) { statusProcess.running = false; root.fail(tr("msg.statusHung")); delayedStatus.restart() }
  }
  Timer {
    id: scanWatchdog; interval: 20000; repeat: false
    onTriggered: if (scanProcess.running) { scanProcess.running = false; root.fail(tr("msg.scanHung")) }
  }
  Timer { id: rescanDebounce; interval: 450; repeat: false; onTriggered: root.rescan() }
  Timer { id: notifyBatch; interval: 1500; repeat: false; onTriggered: root.flushNotification() }
  Timer { id: statusResetTimer; interval: 4000; repeat: false; onTriggered: { root.actionStatus = ""; root.lastError = "" } }
  Timer { id: watcherRetry; interval: 5000; repeat: false; onTriggered: root.restartWatcher() }
  Timer { id: launchGuard; interval: 60000; repeat: false; onTriggered: root.launchPending = false }
  Timer { id: clock; interval: 30000; repeat: true; running: true; onTriggered: root.nowMs = Date.now() }
  // While JDownloader is starting, poll faster so the icon flips promptly.
  Timer { interval: 1500; repeat: true; running: root.starting; onTriggered: root.refreshStatus() }

  // A window appears or disappears: look right away instead of waiting a tick.
  Connections {
    target: ToplevelManager.toplevels
    function onValuesChanged() { delayedStatus.restart() }
  }
  Connections {
    target: ToplevelManager
    function onActiveToplevelChanged() { delayedStatus.restart() }
  }

  onReadyChanged: if (ready) { refreshStatus(); rescan(); refreshDisplay(); restartWatcher() }
  Component.onCompleted: if (ready) { rescan(); refreshDisplay() }
}
