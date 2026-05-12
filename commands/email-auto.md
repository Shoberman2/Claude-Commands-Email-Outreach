# Email Auto

Bulk-send personalized outreach using a template with `{{placeholders}}`. Unlike `/email-all` (which gates every individual email), `/email-auto` gates only the **template** — once approved, all qualifying prospects get personalized sends without further confirmation. Throttle defaults to 5 sends per invocation with a 60s gap (configurable per-run via `~/email-outreach/config.json` — see Batch & timing). One send per domain regardless.

## Argument

Template (path, inline content, or empty): $ARGUMENTS

## Resolving the template

1. If `$ARGUMENTS` is a path to an existing file, read it.
2. Else if `$ARGUMENTS` looks like template content (contains `Subject:` on the first line), treat it as the template and save it to `~/email-outreach/template.md` (overwrite).
3. Else if `~/email-outreach/template.md` exists, read it.
4. Else: tell the user "No template found. Run `/email-auto` again with template text as the argument, or write one to `~/email-outreach/template.md` first." and stop.

## Template format

First line is `Subject: <subject>`, then a blank line, then the body. Placeholders use double-brace syntax: `{{field}}`.

```
Subject: thoughts on your work at {{company}}

Hey {{first_name}},

{{why_relevant}}. Quick note — I'm building <pitch>, and your perspective on
<thing> would be genuinely useful.

Worth a 15-min call this month?

— Spencer
```

**Supported placeholders** (all map to fields in `prospects.json`):
- `{{name}}` — full name
- `{{first_name}}` — computed: first whitespace-separated token of `name`
- `{{email}}`
- `{{role}}`
- `{{company}}`
- `{{why_relevant}}`
- `{{source_url}}`

If the template uses anything else (e.g., `{{custom_field}}`), refuse to proceed and tell the user which placeholder is unsupported.

## Setup

1. **Read prospects.** `~/email-outreach/prospects.json`, filter to `status == "new"`.

2. **Dedupe by domain** (mandatory, same rule as `/email-all`): at most one prospect per recipient email domain. Domains `gmail.com`, `outlook.com`, `icloud.com`, `proton.me`, `yahoo.com` count as separate (personal mailboxes). All other domains dedupe — defer the extras with `status: "new"` for the next run.

3. **Render check.** For each remaining prospect, attempt to render every placeholder in the template against their record. If any placeholder maps to a missing or empty field, **skip that prospect** (leave them as `status: "new"`) and add them to a "skipped (missing fields)" list. Never send a literal `{{name}}` to anyone.

4. **Read `~/email-outreach/sender.txt`.** Stop if missing. This is the From address.

5. **Read `~/email-outreach/signature.md`** if it exists — appended to the body if the template doesn't already include a sign-off.

## Batch & timing configuration

Same flow as `/email-all`. Read `~/email-outreach/config.json` (defaults: `{ "batch_size": 5, "gap_seconds": 60 }`), surface the saved values plus the eligible-prospect count, and accept one round-trip of changes (`size N`, `gap N` or `Nm`, `start <expr>`). Persist `batch_size` and `gap_seconds`; `start` is per-run only.

Warnings:
- `size > 10` — require a second explicit `yes` (template mode removes per-email gating, so volume bites harder).
- `gap < 30s` — require a second explicit `yes`.

If `start` is in the future, ask whether to wait via `sleep` (Claude stays open) or `background` (hand off to macOS `at` / Windows Task Scheduler — verify `atq` works first on macOS).

## Approval gate (one decision, covers the whole batch)

Show the user, in this order:

1. **The exact template** (so they can spot bad copy before it goes out 5x).
2. **One fully-rendered preview** using the first qualifying prospect. Show subject AND body, exactly as Mail.app/Outlook will receive them.
3. **The recipient list** — for each qualifying prospect: `<name> <email> — rendered subject`.
4. **Sender:** `<value from sender.txt>`.
5. **Counts:** "N to send, K skipped (missing fields), J deferred (same domain)."

Then ask:

```
Approve this template for all N sends? (yes / cancel)
```

If the user says anything other than an explicit yes (`yes`, `y`, `send`, `approve`), STOP and change nothing. No silent defaults.

## Sending

**OS dispatch (do this once before the loop).** Detect the user's platform:
- **macOS** (`darwin`) → use `~/email-outreach/send.sh`
- **Windows** (`win32`) → use `$HOME\email-outreach\send.ps1` (invoke via `powershell -ExecutionPolicy Bypass -File`)
- **Linux** → stop, this command is macOS- and Windows-only.

### Foreground send (start = now, OR sleep mode)

If `start` is `now`, proceed immediately. If `start` is future + `sleep` mode chosen, run `sleep <seconds-until-target>` first, then proceed. Tell the user: "Waiting until <resolved time>. Keep this session open."

For each prospect in the approved batch (up to `batch_size`):

1. Render the template using that prospect's fields. Subject and body separately.
2. If the body doesn't include a sign-off and `signature.md` exists, append `\n\n<signature>` to the body.
3. Write the rendered body to a UTF-8 temp file (`mktemp /tmp/email-XXXXXX.txt` on Unix, `Join-Path $env:TEMP "email-$(New-Guid).txt"` on Windows).
4. Call the OS-appropriate helper with `<email> <rendered subject> <temp-file>`.
5. If the helper exits non-zero, STOP the batch. Report which prospect failed and why. The remaining prospects stay `status: "new"`.
6. On success, update that prospect's entry: `status: "sent"`, `sent_at: <ISO 8601>`. Append a record to `~/email-outreach/sent.json` with `{name, email, subject, body, sent_at, template_used: "auto"}`.
7. Sleep `<gap_seconds>` (`sleep <gap_seconds>` / `Start-Sleep -Seconds <gap_seconds>`).
8. Clean up the temp file.

### Background send (start = future, `background` mode chosen)

Same mechanism as `/email-all`: generate `~/email-outreach/scheduled-batches/<id>/send.sh` with the rendered subjects, body files, and per-prospect calls to the helper. Use `python3` inline to update `prospects.json` and `sent.json` on success (append `template_used: "auto"`). Schedule via `at -t <YYYYMMDDhhmm>` on macOS or `schtasks /create /sc ONCE` on Windows. Verify `atq` works before scheduling on macOS; if not, tell the user to enable `atrun` or pick `sleep`. Report the job id and status-log path.

## Cap

Per-run cap is **configurable via `batch_size` in `~/email-outreach/config.json`** (default 5). The auto-send mode removes the per-email gate, so volume cap and pacing carry more weight than in `/email-all` — warnings fire at `size > 10` and `gap < 30s` and require a second explicit `yes`. If more prospects qualify than `batch_size`, send the first N and tell the user: "Sent <N>, K remaining qualifying still marked 'new'. Run `/email-auto` again later."

## Report

```
Sent: N
From: <sender>
Template: ~/email-outreach/template.md (M chars)
Skipped (missing fields): K
  - <name> (<email>): missing field {{<field>}}
  - ...
Deferred (same domain): J
Remaining 'new': L
Log: ~/email-outreach/sent.json
```

## Follow-up TODOs

After a successful send (N >= 1), ask once: "Want to add follow-up TODOs for any of these? (newline-separated text, or 'skip')". If they provide items, append to `~/email-outreach/TODO.md` Pending section in the `- [ ] <text>  _(added <YYYY-MM-DD>)_` format used by `/email-todo`.

## Rules

- ONE explicit approval covers the entire batch. No silent defaults. "Maybe" and "looks good" don't count — require `yes` / `y` / `send` / `approve`.
- Never send if any placeholder fails to resolve — skip that prospect instead. A literal `{{name}}` in a recipient's inbox is the worst possible outcome of this command.
- Never auto-resend. Already-`sent` prospects stay out unless the user explicitly resets their status.
- If the helper script (`send.sh` on macOS, `send.ps1` on Windows) is missing or unrunnable, stop and tell the user. Don't inline AppleScript or COM code.
- If Mail.app or Outlook is not configured with the sender account, the helper will fail. Surface the error verbatim.
- Default cap is 5 — overridable per-run, but warn at `size > 10` and require a second explicit `yes`. If the user wants real high-volume cold email, point them at dedicated tools (Instantly, Smartlead) — this command is for low-volume, high-care templated outreach.
