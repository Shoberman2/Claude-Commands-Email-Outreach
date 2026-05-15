# Email All

Pick recipients from a dropdown, then auto-draft and auto-send. **One prompt total** (plus first-run setup if pitch/signature/sender aren't saved yet).

For high-volume templated mail-merge, use `/email-auto` instead — this command does one bespoke email per prospect.

## Argument

Pitch override (optional): $ARGUMENTS

## Setup (silent — no prompts unless a required file is missing)

1. Read `~/email-outreach/prospects.json`. Filter to `status == "new"`. If none: **"No new prospects. Run `/find-emails <target>` first — it's the front door of outreach: captures your goal and researches real recipients."** Stop.

2. **Domain dedupe (mandatory).** Keep at most ONE prospect per recipient email domain. Personal mailbox domains (`gmail.com`, `outlook.com`, `icloud.com`, `proton.me`, `yahoo.com`) count as separate. All other domains dedupe — keep the entry with the most specific `why_relevant`, leave the others at `status: "new"`.

3. **Pitch:**
   - If `$ARGUMENTS` is non-empty, that's the pitch — save to `~/email-outreach/pitch.md` (overwrite).
   - Else read `~/email-outreach/pitch.md`.
   - Else stop with: **"No saved pitch. Run `/find-emails <target>` first — it's the front door that captures your goal once and reuses it everywhere. Or re-run this command with the pitch as $ARGUMENTS."** Don't ask for the pitch inline — keep `/find-emails` as the single capture point.

4. **Signature:** read `~/email-outreach/signature.md`. If missing, ask once: "How should I sign these? (e.g., 'Alex', '— Alex, alex@example.com')". Save.

5. **Sender:** read `~/email-outreach/sender.txt`. If missing or empty, stop and tell the user to write their sending address there. This is the From identity replies land in.

6. **Config:** read `~/email-outreach/config.json`. If missing, create with `{ "batch_size": 4, "gap_seconds": 60 }`. Use the values silently — **no config gate**. The user can edit `config.json` directly if they want different defaults.

## The one prompt: pick recipients

Take the first `min(eligible_count, batch_size, 4)` deduped prospects (the cap of 4 is AskUserQuestion's hard limit — for higher volume, use `/email-auto`).

Call `AskUserQuestion` with `multiSelect: true`:

- **question:** `"Sending FROM <sender>. Pick recipients — I'll draft and send immediately after selection."`
- **header:** `"Recipients"`
- **options** (one per prospect):
  - `label`: `"<first_name> <last_initial>. (<email>)"` (keep under 60 chars)
  - `description`: `"<role> @ <company> — <why_relevant>"` (this is what helps the user decide)

If `eligible_count > 4`, append one sentence to the question text: `"Showing 4 of N — run /email-all again for the rest."`

If the user picks zero recipients, stop and change nothing.

## Auto-draft and auto-send (no further prompts)

For each selected prospect, **in order**:

1. **Draft the email:**
   - **Subject:** 4-8 words, specific to them, lowercase or sentence case. Reference something concrete (their project, post, tool, role). No clickbait, no "quick question".
   - **Body:** 4-6 sentences:
     1. Personal opener referencing `why_relevant` — prove you know who they are.
     2. The pitch in 1-2 sentences.
     3. Why it connects to them specifically.
     4. One concrete, low-friction ask (try it / 15 min chat / feedback / share it).
     5. Sign-off from `signature.md`.
   - **Forbidden:** "I hope this email finds you well", "I came across your profile", "synergy", "circle back", em-dashes as decoration, emoji (unless the pitch uses them), corporate filler, marketing buzzwords.
   - Vary openers across the batch — don't sound templated.

2. **Show the rendered draft** (full subject + body) in the assistant response so the user sees what's about to send. During the `gap_seconds` sleep before the *next* send they can Ctrl+C if something looks wrong.

3. **Write the body** to a UTF-8 temp file:
   - macOS/Linux: `mktemp /tmp/email-XXXXXX.txt`
   - Windows: `Join-Path $env:TEMP "email-$(New-Guid).txt"`

4. **OS dispatch** (detect from the environment, do this check once before the loop):
   - macOS (`darwin`) → `~/email-outreach/send.sh "<email>" "<subject>" "<body-file>"`
   - Windows (`win32`) → `powershell -ExecutionPolicy Bypass -File "$HOME\email-outreach\send.ps1" -To "<email>" -Subject "<subject>" -BodyFile "<body-file>"`
   - Linux → stop, not supported.

5. **If the helper exits non-zero, STOP the batch.** Report which prospect failed and why. Remaining selected prospects stay `status: "new"`.

6. **On success:**
   - Update that prospect's entry in `prospects.json`: `status: "sent"`, `sent_at: <ISO 8601>`.
   - Append to `~/email-outreach/sent.json`: `{name, email, subject, body, sent_at}`.

7. **Sleep `gap_seconds`** before the next send. This is the single biggest signal classifiers use to distinguish humans from sequencers — keep it. (Default 60s; the user can lower it in `config.json` but personal Gmail/Outlook deliverability degrades sharply below 30s.)

8. **Clean up** the temp file.

## Report

```
Sent: N
From: <sender>
Failed: M (each with reason, if any)
Deferred (same domain): J
Remaining 'new': K
Log: ~/email-outreach/sent.json
```

## Rules

- **One user prompt: the recipient picker.** That selection IS approval to draft and send. No second gate. No follow-up TODO prompt — the user can run `/email-todo` directly.
- Setup prompts (pitch, signature) fire **only when their saved files don't exist**. Subsequent runs skip them.
- Never send to a prospect whose `status` isn't `"new"`.
- Never edit a prospect's `email` field.
- If `send.sh` (macOS) or `send.ps1` (Windows) is missing or unrunnable, stop — never inline AppleScript or COM code.
- If Mail.app / Outlook isn't configured with the sender account, surface the helper error verbatim.
- Per-run cap is `min(batch_size, 4)`. For higher volume, use `/email-auto` (template-based, no per-recipient picker).
