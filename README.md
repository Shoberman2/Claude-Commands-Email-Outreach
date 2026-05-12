# Claude Commands: Email Outreach

Three Claude Code slash commands for personalized email outreach via macOS Mail.app. No SMTP credentials, no third-party APIs — everything routes through your existing Mail.app account.

| Command | What it does |
|---|---|
| `/find-emails <target description>` | WebSearch + WebFetch to find real personal email addresses for people matching your target. Appends to `~/email-outreach/prospects.json`. |
| `/email-all [pitch override]` | Drafts a personalized email for each prospect with `status: "new"`, shows them all for approval, sends the approved ones via Mail.app. Caps at 5 sends/run, 60s gap, one per domain. |
| `/email-todo [args]` | Manage `~/email-outreach/TODO.md`. List, add, mark done, remove. |

## Requirements

- **macOS** (the helper script drives Mail.app via AppleScript)
- **Mail.app configured** with at least one sending account
- **[Claude Code](https://claude.com/claude-code)** installed (`claude` on your PATH)

## Install

```bash
git clone https://github.com/Shoberman2/Claude-Commands-Email-Outreach.git
cd Claude-Commands-Email-Outreach
./install.sh
```

The installer:
- Copies the three command files to `~/.claude/commands/`
- Creates `~/email-outreach/` with `send.sh` and empty data files
- Prompts for your sending email and writes it to `~/email-outreach/sender.txt`
- Verifies Mail.app has that account configured

Re-running the installer is safe — your prospects, sent log, and TODO list are preserved.

## How sending actually works

```
You type /email-all in Claude Code
        |
        v
Claude reads ~/email-outreach/prospects.json, drafts emails, shows them
        |   you approve which ones to send
        v
Claude calls ~/email-outreach/send.sh "<to>" "<subject>" "<body-file>"
        |
        v
send.sh runs osascript with an AppleScript snippet
        |
        v
AppleScript tells Mail.app to compose a new outgoing message
        |
        v
Mail.app routes through the account matching sender.txt
        |   (using its existing SMTP/OAuth connection)
        v
Recipient's inbox
```

**Claude never sees your email password.** Authentication lives entirely inside Mail.app. The tool just hands Mail.app a pre-written message and asks it to send.

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
| `~/email-outreach/sender.txt` | The email address Mail.app sends from |
| `~/email-outreach/TODO.md` | Follow-up checklist managed by `/email-todo` |

## Customizing

- **Throttle settings** live in `~/.claude/commands/email-all.md` (the `## Cap` and `## Sending` sections). Raise the cap or shorten the sleep at your own deliverability risk.
- **Sender** — edit `~/email-outreach/sender.txt` to change which account sends.
- **Prospect schema** — `prospects.json` is plain JSON. Add fields if you want; the commands only read the ones they reference.

## License

MIT. See [LICENSE](LICENSE).
