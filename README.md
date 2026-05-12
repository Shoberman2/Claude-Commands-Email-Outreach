# Claude Commands: Email Outreach

Three Claude Code slash commands for personalized email outreach. Sends route through your existing mail client — **Mail.app on macOS** or **Outlook desktop on Windows** — so no SMTP credentials and no third-party APIs are involved.

| Command | What it does |
|---|---|
| `/find-emails <target description>` | WebSearch + WebFetch to find real personal email addresses for people matching your target. Appends to `~/email-outreach/prospects.json`. |
| `/email-all [pitch override]` | Drafts a personalized email for each prospect with `status: "new"`, shows them all for approval, sends the approved ones via Mail.app (macOS) or Outlook (Windows). Default: 5 sends/run, 60s gap, one per domain — batch size, gap, and start time all configurable per-run. |
| `/email-auto [template]` | Mail-merge mode. Approve one template with `{{name}}`-style placeholders, then qualifying prospects get personalized sends automatically — no per-email gate. Same configurable throttle as `/email-all`. |
| `/email-todo [args]` | Manage `~/email-outreach/TODO.md`. List, add, mark done, remove. |

## Requirements

One of these platform combos:

- **macOS** + **Mail.app** with at least one sending account configured (helper uses AppleScript)
- **Windows** + **Outlook desktop** with at least one sending account configured (helper uses COM)

Plus **[Claude Code](https://claude.com/claude-code)** installed (`claude` on your PATH).

Linux isn't supported yet — the helpers drive Mail.app and Outlook specifically. To add Linux you'd need a third helper that drives Thunderbird or sends via SMTP directly.

## Install

Clone the repo, then run the installer for your OS.

**macOS:**
```bash
git clone https://github.com/Shoberman2/Claude-Commands-Email-Outreach.git
cd Claude-Commands-Email-Outreach
./install.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/Shoberman2/Claude-Commands-Email-Outreach.git
cd Claude-Commands-Email-Outreach
powershell -ExecutionPolicy Bypass -File install.ps1
```

Both installers:
- Copy the four command files to `~/.claude/commands/`
- Create `~/email-outreach/` with the OS-appropriate helper (`send.sh` on macOS, `send.ps1` on Windows) and empty data files
- Prompt for your sending email and write it to `~/email-outreach/sender.txt`
- Verify the local mail client (Mail.app or Outlook) has that account configured

Re-running the installer is safe — your prospects, sent log, and TODO list are preserved.

## How sending actually works

```
You type /email-all in Claude Code
        |
        v
Claude reads ~/email-outreach/prospects.json, drafts emails, shows them
        |   you approve which ones to send
        v
Claude picks the helper based on your OS:
  macOS    -> ~/email-outreach/send.sh   (bash + osascript + AppleScript)
  Windows  -> ~/email-outreach/send.ps1  (PowerShell + COM)
        |
        v
Helper composes a new outgoing message in the local mail client:
  macOS    -> Mail.app
  Windows  -> Outlook desktop
        |
        v
The mail client routes through the account matching sender.txt,
using its existing SMTP/OAuth connection.
        |
        v
Recipient's inbox
```

**Claude never sees your email password.** Authentication lives entirely inside Mail.app or Outlook. The tool just hands the mail client a pre-written message and asks it to send.

## Cold-email warning

Cold email at scale damages sender reputation. The defaults are deliberately conservative:

- **5 sends max per invocation** (configurable — warning above 10)
- **60 seconds between sends** (configurable — warning below 30s; human pacing, not script pacing)
- **One email per recipient domain per run** (avoids the "list import" pattern that triggers spam classifiers; not configurable)

If you ignore these defaults and blast hundreds of cold emails, you will burn the sending account's deliverability. That affects every email from that account — including legitimate replies to people you know — for weeks afterward.

If you want sustained outreach volume, use a dedicated cold-email service (Instantly, Smartlead, etc.) with a separate sending domain. This tool is for low-volume, high-care outreach: 5/day from your real account.

## Where your data lives

Everything stays local. No data leaves your machine via this tool. Web searches go through Claude's WebSearch.

| File | Purpose |
|---|---|
| `~/email-outreach/prospects.json` | Your contact list (status: new / sent) |
| `~/email-outreach/sent.json` | Append-only send log |
| `~/email-outreach/pitch.md` | Your pitch text, reused across runs |
| `~/email-outreach/signature.md` | Your sign-off line |
| `~/email-outreach/sender.txt` | The email address Mail.app (macOS) or Outlook (Windows) sends from |
| `~/email-outreach/template.md` | Mail-merge template used by `/email-auto` (with `{{name}}`-style placeholders) |
| `~/email-outreach/TODO.md` | Follow-up checklist managed by `/email-todo` |
| `~/email-outreach/config.json` | Saved `batch_size` and `gap_seconds` defaults |
| `~/email-outreach/scheduled-batches/` | Generated scripts + status logs for `background` mode sends |

## Customizing

### Batch size, gap, and send time

`/email-all` and `/email-auto` each open with a one-line prompt showing your saved defaults plus the eligible-prospect count:

```
Found 7 eligible prospects after dedupe.

Send settings (saved):
  Batch size: 5    (max sends this run)
  Gap:        60s  between sends
  Start:      now

Reply 'ok' to keep these, or specify changes — examples:
  size 3
  gap 120
  start 9am
  start 'tomorrow 10am' size 10 gap 90
```

- **`size N`** — max sends this run. Warning fires at `> 10` (personal Gmail's classifier territory).
- **`gap N`** seconds, or `Nm` minutes — pause between sends. Warning fires below 30s.
- **`start <expr>`** — defer the batch until a future time. Accepts natural forms (`9am`, `tomorrow 10am`, `in 2 hours`) and ISO 8601.

When `start` is in the future, the command asks how to wait:

1. **`sleep`** — Claude waits inside the session. Keep the terminal open.
2. **`background`** — hand off to macOS `at` (or Windows Task Scheduler). You can close the session; the batch runs on its own. On macOS, `atrun` must be loaded:
   ```bash
   sudo launchctl load -F /System/Library/LaunchDaemons/com.apple.atrun.plist
   ```
   Scheduled batches live under `~/email-outreach/scheduled-batches/<id>/` with a `status.log`. Cancel with `atrm <job-id>` (shown when the batch is scheduled).

`batch_size` and `gap_seconds` persist to `~/email-outreach/config.json`. `start` is per-run only.

### Other knobs

- **Sender** — edit `~/email-outreach/sender.txt` to change which account sends.
- **Prospect schema** — `prospects.json` is plain JSON. Add fields if you want; the commands only read the ones they reference.
- **Deliverability defaults** — the conservative 5/60s defaults exist for a reason (see the Cold-email warning above). Raise them at your own risk, especially on a personal Gmail account.

## License

MIT. See [LICENSE](LICENSE).
