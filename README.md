# JDownloader for the Omarchy bar

A bar widget for [Omarchy](https://omarchy.org/) Quattro that gives
JDownloader 2 what it lacks under Wayland: a tray icon. Bring the window back
or tuck it away, send links from the clipboard, see finished downloads, set
font smoothing and interface size — no cloud, no MyJDownloader account, no
deprecated RemoteAPI.

**What it is:** a launcher, a window toggle, a drop slot for links.
**What it is not:** a dashboard. No speed, no progress bar, no package list,
no starting or pausing of downloads. That data only leaves JDownloader
through the deprecated API or the cloud, and both are deliberately out of
scope. The design notes live in [DESIGN.md](DESIGN.md).

Interface languages: English (default) and German. The widget follows the
session locale; a setting pins it.

## Why

JDownloader is Java/Swing and runs through XWayland. Its tray icon speaks
XEmbed only and looks for `_NET_SYSTEM_TRAY_S0` — the Omarchy bar is
Quickshell and speaks StatusNotifierItem over D-Bus. JDownloader's log says
it plainly:

```
[TrayExtension(start)] -> Error initializing SystemTray: Tray isn't supported jet
```

This widget does what a tray icon would, through three channels, none of
them deprecated:

| Channel | Used for |
|---|---|
| Hyprland IPC | Is JD running? Bring back, tuck away, focus, launch, close the window |
| Click'n'Load (`127.0.0.1:9666`) | Liveness (`jdcheck.js`) and handing over links (`/flash/add`) |
| File system (`inotifywait`) | Watched folders: what is in progress (`.part`), what finished |

Plus the desktop file `~/.local/share/applications/jdownloader.desktop`,
which carries the JVM switches for font smoothing and scaling.

## Install

Requirements: Omarchy Quattro, JDownloader 2 (AUR `jdownloader2`),
`inotify-tools`, `jq`, `curl`, `wl-clipboard`, `python3` — everything except
`inotify-tools` ships with Omarchy.

```bash
omarchy pkg add inotify-tools
omarchy plugin add https://github.com/JohnAndrewsX/omarchy-jdownloader --enable
```

From a local checkout (development):

```bash
omarchy plugin add file:///path/to/omarchy-jdownloader --enable
```

The plugin lands in `~/.config/omarchy/plugins/io.github.johnandrewsx.jdownloader/` and
appears on the right of the bar. Move it with
`omarchy bar move io.github.johnandrewsx.jdownloader --section center`.

## Use

| Gesture on the icon | Effect |
|---|---|
| Left click | Open the panel |
| Right click | JD not running → launch · tucked away → bring back · visible → tuck away (or focus, per setting) |
| Middle click | Send URLs from the clipboard to JDownloader |

In the panel: **H** window back/away · **L** link from clipboard ·
**O** open the default folder · **R** refresh · **S** settings ·
**Q** close JDownloader · **Esc** closes the panel.

The dot on the icon: pulsing = something is being written in a watched
folder; solid = something finished since you last opened the panel.

### First link

JDownloader shows its Click'n'Load prompt once ("allow requests from
`omarchy-jdownloader.local`?"). Confirm with "remember"; it will not ask
again.

### Closing

"Quit" closes the window like a click on the X — JDownloader asks first if
Settings → Tray → "On close" is set to *ask*. That is its setting, not ours.
The restart button under "Appearance" uses SIGTERM instead: JDownloader
saves its lists through AppWork's ShutdownController, no dialog.

## Settings

In the panel under "More" (S) — stored inline in the layout entry of
`~/.config/omarchy/shell.json`:

| Key | Default | Meaning |
|---|---|---|
| `language` | `auto` | `auto` follows the session locale; `en` or `de` pins it |
| `watchDefaultFolder` | `true` | Watch the default folder from JDownloader's `GeneralSettings.json`; follows changes automatically |
| `extraFolders` | `[]` | More folders, e.g. targets of Packagizer rules |
| `notifyOnFinish` | `true` | Desktop notification when something finishes |
| `clickAction` | `hide` | Right-click on a visible, focused window: `hide` or `focus` |
| `recentCount` | `8` | Finished files shown in the panel |
| `statusIntervalSec` | `5` | Status poll interval |

From the CLI: `omarchy bar set io.github.johnandrewsx.jdownloader extraFolders '["~/Videos"]' --json`

### Appearance

Font smoothing and scaling are Java VM switches, not JDownloader settings.
The widget writes them into the `Exec=` line of the user override of the
desktop file; they take effect on the next launch:

```
Exec=env _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dsun.java2d.uiScale=2" JDownloader
```

**Scaling in whole steps only (1, 2, 3).** Java's X11 backend truncates
fractions — `sun.java2d.uiScale=1.5` is the same as 1. For "a bit larger"
without doubling everything, use JDownloader's own font scaling (Settings →
Advanced Settings → `fontScaleFactor`); it enlarges text only, icons stay.

Nothing under `~/.jd/cfg/` is touched — that belongs to JDownloader, which
writes it while running.

## What the widget does not see

Downloads outside the watched folders. JDownloader can give a package its
own destination and reroute through Packagizer rules; that only lives in its
internal `downloadList.zip`, which we deliberately do not read. If you use
such rules, add the target folders once under "Watched folders".

## IPC

```bash
omarchy-shell io.github.johnandrewsx.jdownloader status      # JSON: running/alive/hidden/focused/…
omarchy-shell io.github.johnandrewsx.jdownloader window      # bring back / tuck away / launch
omarchy-shell io.github.johnandrewsx.jdownloader clipboard   # send the clipboard
omarchy-shell io.github.johnandrewsx.jdownloader add 'https://…'
omarchy-shell io.github.johnandrewsx.jdownloader toggle      # panel
omarchy-shell io.github.johnandrewsx.jdownloader summary     # everything at once, for a look or for debugging
```

New IPC functions only register after `omarchy restart shell` — the hot
reload picks up QML but does not register new IPC handlers.

For a keybinding in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER SHIFT", "J", "omarchy-shell io.github.johnandrewsx.jdownloader clipboard", { desc = "Link to JDownloader" })
```

## Helpers in `bin/`

All usable by hand, all print JSON:

- `jd-window status|launch|show|hide|focus|toggle|quit` — the Hyprland side
- `jd-cnl check|add URL…|clipboard` — Click'n'Load
- `jd-scan` — snapshot of the watched folders
- `jd-watch DIR…` — the inotify stream the widget reads
- `jd-display get|set SCALE SMOOTHING|restart` — JVM switches in the desktop file
- `jd-notify TITLE BODY` — notification, deduplicated via `flock` (the bar runs per monitor, so the widget runs more than once)

## Translations

`Lang.js` holds one table per language, English being the source of truth;
missing keys fall back to English. To add a language, add a table and its
tag to `LANGUAGES`, and the option to `LANGUAGE_VALUES` in `Model.js` plus a
`language.<tag>` label. Scripts return a stable `code` with every message so
the panel can translate it.

## Security

Network only to `127.0.0.1:9666`. No account, no credentials, no keyring,
no daemon. The clipboard is read on gesture only. One file is written: the
desktop file in the user directory. Plain QML plus six small scripts; no
binaries.

Like every Omarchy plugin, the code runs unsandboxed inside the shell. Read
it before enabling it — it is short.

## Contributing

Bug reports, translations and fixes that keep the scope are welcome — see
[CONTRIBUTING.md](CONTRIBUTING.md). Two things to know before opening
anything: this repository never contains a real path, machine or person
(issues included), and the widget will not grow into a dashboard — what it
cannot see and why is in [DESIGN.md](DESIGN.md). Security reports go through
GitHub's private reporting, see [SECURITY.md](SECURITY.md).

## License

MIT.
