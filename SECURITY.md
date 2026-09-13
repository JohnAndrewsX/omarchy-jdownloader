# Security

## Scope

The widget talks to `127.0.0.1:9666` (JDownloader's Click'n'Load), runs
`hyprctl`, `inotifywait`, `curl`, `jq`, `wl-paste` and `notify-send`, and
writes exactly one file: `~/.local/share/applications/jdownloader.desktop`.
It reads the clipboard only on an explicit gesture. It has no network access
beyond localhost, no account, no credentials.

Like every Omarchy plugin it runs unsandboxed inside the shell process, so
"the widget can be made to run something" is in scope, as is anything that
lets a page or a file in a watched folder influence what the widget
executes.

## Reporting

Please do not open a public issue for a vulnerability. Use GitHub's private
vulnerability reporting on this repository ("Security" tab → "Report a
vulnerability"). You will get an answer; this is a side project, so allow a
few days.

Once fixed, the report is credited in the release notes unless you prefer
otherwise.

## Supported versions

The latest commit on `main`. There are no maintained older branches.
