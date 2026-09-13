# Design notes

Why the widget is built the way it is. `README.md` says what it does; this
file records the decisions and the facts they rest on. Anything measured on
a real machine stays in the private development log, not here.

## The problem

JDownloader 2 is a Java/Swing application and runs through XWayland. Its
tray icon uses `java.awt.SystemTray`, which on X11 speaks only the XEmbed
protocol and looks for the owner of the `_NET_SYSTEM_TRAY_S0` selection. A
Wayland desktop with a StatusNotifierItem tray (the Omarchy bar is Quickshell,
its tray is SNI over D-Bus) has no such owner, so JDownloader logs
`Tray isn't supported` and the extension stays off. The two protocols do not
talk to each other; a bridge (`xembedsniproxy`) would be an extra daemon for
one icon.

## What was ruled out, and why

**The local RemoteAPI (`deprecatedapienabled`, port 3128).** JDownloader has
one API controller shared by two doors: `MyJDRemoteAPIRequest` (the cloud)
and `DeprecatedAPIServer` (localhost). The API itself is alive — it carries
MyJDownloader — but the local door is labelled deprecated by the vendor and
may be closed. A bar widget should not hang off an entrance its maker calls a
leftover. This decision shapes everything: nothing that reads JDownloader's
internal state is available.

**MyJDownloader.** An account and a round trip through a cloud service to
talk to a program two windows away. The marketplace already has a plugin for
that case (`omajd-remote`); this one is for the local instance.

**`downloadList.zip` and anything under `~/.jd/cfg/`.** Internal formats,
rewritten while JDownloader runs. Reading them is fragile; writing them while
JDownloader runs loses data. The widget never writes there.

## What is left: three channels, none deprecated

| Channel | Direction | Used for |
|---|---|---|
| Hyprland IPC | both | window present? visible? focused? · show, hide, focus, launch, close |
| Click'n'Load, `127.0.0.1:9666` | in only | `jdcheck.js` liveness (and version) · `/flash/add` to hand over links |
| File system, `inotifywait` | out only | `.part` appears = in progress · rename/close = finished |

Click'n'Load is the interface every browser extension uses with JDownloader;
it is on regardless of settings and is not going anywhere. The parameters
`/flash/add` accepts (from `ExternInterfaceImpl`): `urls`, `source`,
`comment`, `passwords`, `package`, `dir`, `autostart`, `referer`. The widget
sends the first three.

So the widget is honest about being a launcher, a window toggle and a drop
slot — not a dashboard. No speed, no progress, no package list.

## Folders

The default download folder is read from JDownloader's
`GeneralSettings.json` (`defaultdownloadfolder`) and the file is watched, so
a change made in JDownloader is picked up at once — JDownloader writes its
configuration while running, via temp file and rename. Downloads that
JDownloader routes elsewhere (a per-package destination, Packagizer rules)
are invisible; those targets exist only in `downloadList.zip`. The widget
therefore watches a list — the default folder plus whatever the user adds —
and says so in the settings.

`.part` is JDownloader's suffix for a file being written; the rename at the
end is the "finished" event. Small files may skip `.part`, which is why
`CLOSE_WRITE` counts as finished too.

## Appearance

Swing takes font smoothing and UI scaling from XSettings. Under a Wayland
compositor there is no XSettings daemon, so Java never sees fontconfig and
renders without antialiasing at the default size. Both are JVM switches
(`-Dawt.useSystemAAFontSettings`, `-Dsun.java2d.uiScale`) and the widget
places them in the `Exec=` line of a user override of the desktop file — a
file the widget owns, read only at launch, safe to write any time.

Scaling is whole numbers only. `X11GraphicsDevice.initScaleFactor()` in
OpenJDK does `return (int) debugScale`: 1.5 is 1. The first version offered
quarter steps; a user found that nothing but 2.0 changed anything.

## Facts about the platform that shaped the code

- **The Omarchy bar exists per monitor.** Every widget instance has its own
  service, timers and processes. Side effects must be idempotent across
  instances: notifications go through `bin/jd-notify`, which deduplicates
  with a `flock` and a hash of the last message.
- **Plugin reload kills the direct child process only.** A script that
  backgrounds `inotifywait` leaves it orphaned on every reload. `bin/jd-watch`
  is a single `exec inotifywait --pdeathsig TERM`.
- **Hot reload does not register new IPC handlers**, and a QML syntax error
  fails the reload silently — the previous instance keeps running. The
  journal (`journalctl --user -t omarchy-shell`) says `Plugin widget … failed`.
- **The first status probe after a shell restart is slow.** The state carries
  a `known` flag; until it is set the panel says "Checking…" and the icon is
  not dimmed.
- **JDownloader's window class** is `org-jdownloader-update-launcher-JDLauncher`.
  The AUR package's desktop file claims `StartupWMClass=jd-Main`, which is
  wrong; the matcher tests the class for `jdownloader` case-insensitively
  and prefers a title starting with `JDownloader`, so a dialog does not win
  over the main window.
- **The manifest `schema`** is stored by the shell but not rendered by it in
  this Omarchy version, so the panel carries its own settings UI and persists
  through `bar.shell.updateEntryInline()`, which replaces the layout entry
  wholesale.

## Non-goals

Stated so they do not come in through the back door: the deprecated
RemoteAPI (also not "optional if the user enables it"), any cloud service,
reading `downloadList.zip`, writing under `~/.jd/cfg/`, a Java-side
extension exposing its own API, an XEmbed→SNI bridge.
