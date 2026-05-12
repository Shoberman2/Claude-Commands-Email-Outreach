# Claude Commands: Email Outreach

Three Claude Code slash commands for personalized email outreach. Sends route through your existing mail client — **Mail.app on macOS** or **Outlook desktop on Windows** — so no SMTP credentials and no third-party APIs are involved.

| Command | What it does |
|---|---|
| `/find-emails <target description>` | WebSearch + WebFetch to find real personal email addresses for people matching your target. Appends to `~/email-outreach/prospects.json`. |
| `/email-all [pitch override]` | Drafts a personalized email for each prospect with `status: "new"`, shows them all for approval, sends the approved ones via Mail.app (macOS) or Outlook (Windows). Caps at 5 sends/run, 60s gap, one per domain. |
| `/email-auto [template]` | Mail-merge mode. Approve one template with `{{name}}`-style placeholders, then up to 5 qualifying prospects get personalized sends automatically — no per-email gate. Same throttle as `/email-all`. |
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

- **5 sends max per invocation**
- **60 seconds between sends** (human pacing, not script pacing)
- **One email per recipient domain per run** (avoids the "list import" pattern that triggers spam classifiers)

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

## Customizing

- **Throttle settings** live in `~/.claude/commands/email-all.md` (the `## Cap` and `## Sending` sections). Raise the cap or shorten the sleep at your own deliverability risk.
- **Sender** — edit `~/email-outreach/sender.txt` to change which account sends.
- **Prospect schema** — `prospects.json` is plain JSON. Add fields if you want; the commands only read the ones they reference.

## License

MIT. See [LICENSE](LICENSE).
