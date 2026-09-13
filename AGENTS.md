# Working rules for this repository

This is an Omarchy shell plugin: QML, a little JavaScript, six small
scripts. `README.md` says what it does; `DESIGN.md` says why it is built
the way it is. This file says how to work on it.

---

## 0 The rule that outranks every other

**This repository is public. Nothing in it describes a real machine, a
real download library, or a real person.**

Not a style preference — the first thing checked in review and the first
thing a pull request is rejected for. "The repository" is every commit ever
made, every commit message and author line, every issue and pull request
text, every release note.

| Never commit | Write instead |
|---|---|
| An absolute path from a real system | `~/Downloads`, `/srv/media` |
| A hostname, hardware model, monitor layout, window address, PID | nothing — state the property, not the machine |
| A file name from a real download folder | a synthetic name (`film.mkv`) |
| A count or size measured on a real folder | a property of the mechanism |
| A personal name or address in a commit, comment, or document | the project handle and a no-reply address |
| Session links, tool telemetry, URLs that identify a working environment | nothing |

Removing a leak is not fixing it: the deleting commit leaves the line in the
object store. Before a push, rewrite; after a push, rotate what leaked and
accept the rest. `bin/check` therefore scans the whole history every time.

The other half — why this exists, what was measured on a real machine, which
paths were tried and dropped — lives in a private development log outside
this repository. `*.local.md` beside the code is ignored for that reason.

## 1 Before a commit

`bin/check` runs the same passes as CI: privacy patterns, gitleaks over the
history, syntax of QML, JavaScript, shell and Python, manifest validity
where `omarchy` is available, and English/German key parity in `Lang.js`.
A commit that fails it is not ready.

## 2 Conventions

- **Language: English**, everywhere — code, comments, documents, commit
  messages, interface text. Interface text goes through `Lang.js`; English
  is the source, every other language falls back to it key by key.
- **Scripts return `code` + `message`.** The panel translates the code and
  shows the English message when it does not know one.
- **Nothing reads JDownloader's internals.** No deprecated RemoteAPI, no
  MyJDownloader cloud, no `downloadList.zip`, and nothing under `~/.jd/cfg/`
  is ever written. See `DESIGN.md`; a pull request that crosses this line
  is out of scope by construction.
- **Long-running processes are `exec`ed**, never backgrounded from a script:
  the shell kills the direct child on reload, nothing else.
- **The bar runs once per monitor.** Every side effect (notifications,
  writes) must tolerate a second instance seeing the same event.
- Commits carry `Co-Authored-By` where an agent wrote them, with a no-reply
  address. No session links.

## 3 Testing on a machine

The scripts are the test surface: `bin/jd-window status`, `bin/jd-scan`,
`bin/jd-cnl check`, `bin/jd-display get` all print JSON and need no shell.
For the widget itself, copy or `omarchy plugin add file://…` the checkout,
then `omarchy-shell io.github.johnandrewsx.jdownloader summary`. New IPC
functions need `omarchy restart shell`; a QML syntax error fails the reload
silently — check `journalctl --user -t omarchy-shell` for
`Plugin widget … failed`.
