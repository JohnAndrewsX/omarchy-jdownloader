# Contributing

Thanks for looking. This widget is small on purpose, and it is meant to stay
that way — so the most useful contributions are bug reports with the exact
observation, translations, and fixes that keep the scope. Read this page and
[`AGENTS.md`](AGENTS.md) once; together they are the whole rulebook.

## The one rule that outranks everything

**Nothing in this repository describes a real machine, a real download
folder, or a real person.** That includes issues, pull request text, and
commit messages — all of it is public. Write `~/Downloads`, not your real
path; say "a folder with many files", not how many; leave out hostnames,
window addresses, process ids. `bin/check privacy` catches the common
shapes; the intent is in `AGENTS.md §0`.

## What fits, what does not

The widget deliberately reads nothing from JDownloader's internals. No
deprecated RemoteAPI (port 3128), no MyJDownloader cloud, no parsing of
`downloadList.zip`, no writing under `~/.jd/cfg/`. Speed, progress bars and
package lists are therefore out of scope by construction, not by neglect —
[`DESIGN.md`](DESIGN.md) explains why. A pull request that crosses that
line will be closed with a pointer here, however good the code.

Good territory:

- anything the three channels can already see (Hyprland window state,
  Click'n'Load, the watched folders) shown better or more robustly
- keyboard navigation in the panel (rows, not only letter keys)
- a new language in `Lang.js`
- portability: another compositor's IPC behind `bin/jd-window`, another
  tray convention, a JDownloader installed somewhere unusual
- documentation that corrects something wrong

## Language

English everywhere — code, comments, commit messages, documents. Interface
text goes through `Lang.js`: add the English key first, then the other
languages. English is the source; a language missing a key falls back to
English, and `bin/check` fails when tables drift apart.

## Setting up

```bash
git clone https://github.com/JohnAndrewsX/omarchy-jdownloader
cd omarchy-jdownloader
bin/check            # privacy, gitleaks, syntax — the same job CI runs
```

To try a change in a running Omarchy shell:

```bash
omarchy plugin add file://$PWD --enable          # first time
# after edits: the shell reloads QML from the plugin folder on save;
# for the clone that omarchy plugin add made, push commits to it or rsync.
omarchy-shell io.github.johnandrewsx.jdownloader summary
```

Two things that bite: new IPC functions need `omarchy restart shell`, and a
QML syntax error fails the reload *silently* — the old panel keeps running.
`journalctl --user -t omarchy-shell | grep "Plugin widget"` tells you.

The scripts in `bin/` need no shell at all: `bin/jd-window status`,
`bin/jd-scan`, `bin/jd-cnl check`, `bin/jd-display get` all print JSON.

## Pull requests

- One change per pull request, with a title that says what changed.
- `bin/check` green. CI runs the same script; a red check is not reviewed.
- Say what you tested, on what (compositor version, Omarchy version,
  JDownloader revision from `jdcheck.js`) — not where.
- Commits carry a no-reply address. If an agent wrote part of it, add a
  `Co-Authored-By` line; no session links.

Maintainer review is honest but not fast; this is a side project. If a pull
request sits for a while, a polite ping is fine.

## Reporting a bug

Use the bug template. The single most useful thing you can attach is the
output of `omarchy-shell io.github.johnandrewsx.jdownloader summary` and
the relevant lines from `journalctl --user -t omarchy-shell` — after you
have replaced your home path and anything else that names your machine.

## Security

See [`SECURITY.md`](SECURITY.md). Do not open a public issue for something
that could be abused.

## License

By contributing you agree that your contribution is licensed under the
MIT license, like the rest of the repository.
