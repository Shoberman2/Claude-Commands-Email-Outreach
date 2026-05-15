# Claude Commands: Email Outreach

Three Claude Code slash commands for personalized email outreach. Sends route through your existing mail client — **Mail.app on macOS** or **Outlook desktop on Windows** — so no SMTP credentials and no third-party APIs are involved.

| Command | What it does |
|---|---|
| `/find-emails <target description>` | **Front door of outreach.** On first run, asks your goal and saves it to `~/email-outreach/pitch.md`. Then WebSearch + WebFetch to find real personal emails for people matching your target. Appends to `~/email-outreach/prospects.json`. |
| `/email-all [pitch override]` | Shows a dropdown picker of eligible prospects (up to 4). You check the ones to send. Claude auto-drafts a unique email per recipient using the saved pitch + their `why_relevant`, then auto-sends with a 60s gap via Mail.app (macOS) or Outlook (Windows). One prompt total. |
| `/email-auto [template]` | Mail-merge mode. Approve one template with `{{name}}`-style placeholders, then qualifying prospects get personalized sends automatically — no per-email gate. Default 5/run, 60s gap, configurable via `config.json`. |
| `/email-todo [args]` | Manage `~/email-outreach/TODO.md`. List, add, mark done, remove. |

## `/email-all` vs `/email-auto`

| | `/email-all` | `/email-auto` |
|---|---|---|
| **What it sends** | Unique, hand-drafted email per prospect (Claude writes each one fresh from the pitch + `why_relevant`) | Same template rendered with `{{placeholders}}` for each prospect (mail-merge) |
| **Approval style** | Pick recipients from a dropdown — selection IS approval | One approval on the template; covers every send in the batch |
| **Recipient selection** | You pick which prospects (up to 4 in the dropdown) | Sends to everyone in the deduped eligible set |
| **Per-run volume** | Up to 4 (AskUserQuestion limit) | Default 5, configurable, warns above 10 |
| **Token cost** | High — N bespoke drafts per run | Low — one template rendered N times, no LLM drafting per email |
| **Quality / personalization** | Higher; each email reads custom | Lower; varies only by what you put in `{{placeholders}}` |
| **Best for** | Small batches where the relationship matters (founders, creators, partnerships) | Larger batches with a proven template (beta invites, launch announcements, structured asks) |

**Rule of thumb:** if you'd write each email differently anyway, use `/email-all`. If you'd copy-paste the same message and change a few words, use `/email-auto`.

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
Claude reads ~/email-outreach/prospects.json, dedupes by domain,
shows up to 4 recipients in a dropdown picker
        |   you check the ones to send
        v
Claude drafts a unique email per selected recipient using the saved
pitch + their why_relevant, shows each draft, then begins sending
        |
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
Recipient's inbox (next send fires after a 60s gap)
```

**Claude never sees your email password.** Authentication lives entirely inside Mail.app or Outlook. The tool just hands the mail client a pre-written message and asks it to send.

## Cold-email warning

Cold email at scale damages sender reputation. The defaults are deliberately conservative:

- **`/email-all`: up to 4 sends per invocation** (dropdown picker limit)
- **`/email-auto`: 5 sends per invocation by default** (configurable in `config.json` — warning above 10)
- **60 seconds between sends** (configurable — warning below 30s; human pacing, not script pacing)
- **One email per recipient domain per run** (avoids the "list import" pattern that triggers spam classifiers; not configurable)

If you ignore these defaults and blast hundreds of cold emails, you will burn the sending account's deliverability. That affects every email from that account — including legitimate replies to people you know — for weeks afterward.

If you want sustained outreach volume, use a dedicated cold-email service (Instantly, Smartlead, etc.) with a separate sending domain. This tool is for low-volume, high-care outreach: a handful per day from your real account.

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

## Customizing

The commands read their defaults silently — no config prompt at runtime. To change defaults, edit the files directly.

### `~/email-outreach/config.json`

```json
{ "batch_size": 5, "gap_seconds": 60 }
```

- **`batch_size`** — max sends per `/email-auto` invocation. `/email-all` is independently capped at 4 by its dropdown picker.
- **`gap_seconds`** — pause between sends. Going below 30s reads as automated to spam classifiers.

### `~/email-outreach/pitch.md`

Your outreach goal in 1-2 sentences. `/find-emails` writes this on first run; `/email-all` reads it for every draft. Edit the file to change your goal — no prompts.

### Other knobs

- **Sender** — edit `~/email-outreach/sender.txt` to change which account sends.
- **Signature** — edit `~/email-outreach/signature.md` to change your sign-off.
- **Template** (`/email-auto`) — edit `~/email-outreach/template.md` directly, or pass new content as `$ARGUMENTS`.
- **Prospect schema** — `prospects.json` is plain JSON. Add fields if you want; the commands only read the ones they reference.
- **Deliverability defaults** — the conservative 4-5/60s defaults exist for a reason (see the Cold-email warning above). Raise them at your own risk, especially on a personal Gmail account.

## License

MIT. See [LICENSE](LICENSE).
