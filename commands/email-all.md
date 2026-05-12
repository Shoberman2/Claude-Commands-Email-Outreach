# Email All

Draft and send personalized outreach emails via macOS Mail.app or Windows Outlook desktop to every prospect with `status: "new"` in `~/email-outreach/prospects.json`. The command auto-detects the OS and uses the right helper.

## Argument

Pitch override (optional): $ARGUMENTS

## Setup

1. Read `~/email-outreach/prospects.json`. Filter to entries where `status == "new"`. If there are none, tell the user "No new prospects. Run `/find-emails <target>` first." and stop.

   **Domain dedupe (mandatory):** From the filtered set, keep at most ONE prospect per email domain. If multiple `@acme.com` prospects exist, keep the one with the most specific `why_relevant`, and leave the others as `status: "new"` for the next run. Tell the user "Deferred N prospects sharing domains with this batch — run `/email-all` again to reach them." Domains like `gmail.com`, `outlook.com`, `proton.me` count as separate (they're not shared inboxes), but `@<company>.com` always dedupes.

2. Determine the pitch:
   - If `$ARGUMENTS` is non-empty, that is the pitch for this run. Also save it to `~/email-outreach/pitch.md` (overwrite).
   - Else if `~/email-outreach/pitch.md` exists and is non-empty, read it.
   - Else ask the user: "What are you pitching? 1-2 sentences on what you're building, who it's for, and the ask. I'll save this for next time." Save the response to `~/email-outreach/pitch.md`.

3. Also ask once per run (only if not already in `~/email-outreach/signature.md`): "How should I sign these? (e.g., 'Alex', '— Alex, alex@example.com')". Save to `~/email-outreach/signature.md` for reuse.

4. Read `~/email-outreach/sender.txt` (single line: the email address the local mail client will send from). If missing or empty, stop and tell the user to write their sending address there. Surface this address to the user in the approval gate — it determines which inbox replies land in and which sender identity recipients see.

## Batch & timing configuration

Read `~/email-outreach/config.json`. If it doesn't exist, treat as `{ "batch_size": 5, "gap_seconds": 60 }` and create it.

Show the user the eligible-prospect count and the saved defaults, then prompt for changes in one round-trip:

```
Found N eligible prospects after dedupe.

Send settings (saved):
  Batch size: <batch_size>   (max sends this run)
  Gap:        <gap_seconds>s between sends
  Start:      now

Reply 'ok' to keep these, or specify changes — examples:
  size 3
  gap 120
  start 9am
  start 'tomorrow 10am' size 10 gap 90
```

Parse the reply:

- `size N` — set `batch_size` to N. If N > 10, warn: "Above 10/run pushes personal Gmail's classifier toward spam. Still apply?" Require a second explicit `yes`.
- `gap N` (seconds) or `gap Nm` (minutes) — set `gap_seconds`. If <30s, warn: "Faster than 30s between sends reads as automated. Still apply?" Require a second explicit `yes`.
- `start <expr>` — parse as a future timestamp. Accept natural forms (`9am`, `tomorrow 10am`, `in 2 hours`) and ISO 8601. Resolve in the user's local timezone. If parsing is ambiguous or resolves to the past, re-ask. If `start` is omitted or `now`, send immediately.

Persist the new `batch_size` and `gap_seconds` back to `config.json`. `start` is per-run and is NOT persisted.

**If `start` is in the future**, ask one more question:

```
Deferring batch until <resolved local time>. How should I wait?
  1. sleep   — Claude waits inside this session (keep it open until done)
  2. background — hand off to macOS `at` (close this session whenever you want)
```

If the user picks `background` on macOS, verify `atq >/dev/null 2>&1` succeeds first. If it fails, tell the user:
"macOS `atrun` isn't loaded. Enable once with `sudo launchctl load -F /System/Library/LaunchDaemons/com.apple.atrun.plist`, or pick `sleep` instead." Do not silently fall back.

On Windows, the equivalent is `schtasks /create /sc ONCE`. Surface any errors verbatim.

## Drafting

For each new prospect, draft an email that:

- **Subject**: short, lowercase or sentence case, specific to them. No clickbait, no "quick question". 4-8 words. Reference something concrete (their project, post, tool, role).
- **Body**: 4-6 sentences. Structure:
  1. Personal opener referencing `why_relevant` — proves you actually know who they are.
  2. The pitch in 1-2 sentences.
  3. Why it connects to them specifically.
  4. One concrete, low-friction ask (try it / 15 min chat / feedback / share it / etc.).
  5. Sign-off from `signature.md`.
- **Forbidden**: "I hope this email finds you well", "I came across your profile", "synergy", em-dashes used as decoration, emoji (unless the pitch uses them), corporate filler, marketing buzzwords, "circle back".
- Vary openers across the batch — don't make them all sound templated.

## Approval gate (mandatory)

Show ALL drafts to the user as a numbered list before sending anything. Lead with the sender so they're never confused about which identity these go from:

```
Sending FROM: <value from sender.txt>

1. To: jane@example.com
   Subject: thoughts on your last devtools post
   Hey Jane — your post on prompt-driven CLIs landed for me because…
   [shows first ~3 lines]

2. To: ...
```

Then ask: "Send all / approve specific numbers (e.g., '1,3,5') / cancel?"

Do not send anything until the user explicitly approves. If they say "cancel", stop and change nothing.

## Sending

**OS dispatch (do this once before the loop).** Detect the user's platform from the environment:

- **macOS** (`darwin`) → use `~/email-outreach/send.sh` (drives Mail.app via AppleScript).
- **Windows** (`win32`) → use `$HOME\email-outreach\send.ps1` (drives Outlook desktop via COM), invoked as:
  ```
  powershell -ExecutionPolicy Bypass -File "$HOME\email-outreach\send.ps1" -To "<email>" -Subject "<subject>" -BodyFile "<temp-body-file>"
  ```
- **Linux** → not supported by these helpers. Stop and tell the user this command works on macOS and Windows only.

Both helpers accept the same logical args (`<to>`, `<subject>`, `<body-file-path>`), both read the sender from `sender.txt`, and both exit non-zero on failure.

### Foreground send (start = now, OR sleep mode)

If `start` is `now`, proceed immediately. If `start` is future + `sleep` mode chosen, run `sleep <seconds-until-target>` first, then proceed. Tell the user: "Waiting until <resolved time>. Keep this session open."

Then, for each approved draft (up to `batch_size`):

1. Write the body to a temp file as UTF-8. macOS/Linux: `mktemp /tmp/email-XXXXXX.txt`. Windows: a path under `$env:TEMP`, e.g., `Join-Path $env:TEMP "email-$(New-Guid).txt"`.
2. Call the OS-appropriate helper with the recipient email, subject, and body-file path.
3. If the helper exits non-zero, STOP the batch. Report which prospect failed and why. Do not continue.
4. On success, update that prospect's entry in `prospects.json`: set `status` to `"sent"` and add `sent_at` (ISO 8601).
5. Append a record to `~/email-outreach/sent.json` with `{name, email, subject, body, sent_at}`.
6. Sleep `<gap_seconds>` between sends (`sleep <gap_seconds>` on Unix, `Start-Sleep -Seconds <gap_seconds>` on Windows). Human pacing, not script pacing — the single biggest signal classifiers use to distinguish you from a sequencer tool.
7. Clean up the temp file.

### Background send (start = future, `background` mode chosen)

Generate a self-contained batch script and hand it off to the OS scheduler.

1. Create a batch directory: `~/email-outreach/scheduled-batches/<YYYYMMDD-HHMMSS>/`.
2. For each approved draft, write the body to `<batch-dir>/body-<index>.txt` as UTF-8.
3. Write `<batch-dir>/send.sh` containing a bash script that:
   - Iterates the approved prospects (each line has `email`, `subject`, `body-file`).
   - For each: calls `~/email-outreach/send.sh "<email>" "<subject>" "<body-file>"`. On success, uses `python3` (always present on macOS) to update `~/email-outreach/prospects.json` (set `status: "sent"`, `sent_at: <ISO>`) and append a record to `~/email-outreach/sent.json`. On failure, appends to `<batch-dir>/errors.log` and exits non-zero.
   - Sleeps `<gap_seconds>` between sends.
   - Writes `<batch-dir>/status.log` lines like `2026-05-12T09:00:00Z SENT <email>`.
4. `chmod +x <batch-dir>/send.sh`.
5. Schedule with `at`: `echo "/bin/bash <batch-dir>/send.sh" | at -t <YYYYMMDDhhmm>`. Capture the job id from stderr.
6. Tell the user: "Batch scheduled (at job #<id>). Status log: `<batch-dir>/status.log`. View pending jobs with `atq`. Cancel with `atrm <id>`. You can close this session."

On Windows, do the analogous thing with `schtasks /create /tn email-outreach-<id> /tr "powershell -File <batch-dir>\send.ps1" /sc ONCE /st <hh:mm> /sd <date>`.

If at any step the scheduler errors, surface the error verbatim and offer to fall back to `sleep` mode.

## Cap

Per-run cap is **configurable via `batch_size` in `~/email-outreach/config.json`** (default 5). The Batch & timing configuration step shows the saved value and lets the user override it. If more prospects qualify than `batch_size`, send the first N and tell the user "Sent <N>, K remaining still marked 'new'. Run `/email-all` again later." Encourage spacing batches across days, not stacking them in the same hour.

The 5-per-run / 60s-gap defaults exist for a reason: personal Gmail/Outlook deliverability degrades sharply with higher volume or faster pacing. The user can raise them — warnings fire at `size > 10` or `gap < 30s`.

## Report

When done, print:

```
Sent: N
From: <value from sender.txt>
Failed: M (if any — list each with reason)
Remaining 'new': K
Log: ~/email-outreach/sent.json
```

## Follow-up TODOs

After a successful send batch (N >= 1), ask the user once: "Want to add follow-up TODOs for any of these? Common patterns: 'follow up with <name> in 1 week if no reply', 'check <name>'s blog for new posts', 'connect on LinkedIn'. Type the items separated by newlines, or 'skip'."

If they provide items, append each as a new line in the **Pending** section of `~/email-outreach/TODO.md` using the same format `/email-todo` uses: `- [ ] <text>  _(added <YYYY-MM-DD>)_`. Then print "Added N follow-ups to TODO.md. View with `/email-todo`."

Never auto-generate follow-up TODOs — only add what the user explicitly types.

## Rules

- NEVER send without explicit user approval of the drafts in this run. A previous run's approval doesn't count.
- NEVER edit the prospect's `email` field — if it looks wrong, ask the user.
- NEVER send to anyone whose `status` isn't `"new"`. Already-sent prospects stay out unless the user explicitly says to re-send.
- If the OS-appropriate helper (`send.sh` on macOS, `send.ps1` on Windows) is missing or unrunnable, stop and tell the user — do not try to inline AppleScript or COM code yourself.
- If Mail.app (macOS) or Outlook desktop (Windows) is not configured with the sender account, the helper will fail. Surface the error verbatim.
