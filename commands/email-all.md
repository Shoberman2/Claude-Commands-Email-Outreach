# Email All

Draft and send personalized outreach emails via macOS Mail.app to every prospect with `status: "new"` in `~/email-outreach/prospects.json`.

## Argument

Pitch override (optional): $ARGUMENTS

## Setup

1. Read `~/email-outreach/prospects.json`. Filter to entries where `status == "new"`. If there are none, tell the user "No new prospects. Run `/find-emails <target>` first." and stop.

   **Domain dedupe (mandatory):** From the filtered set, keep at most ONE prospect per email domain. If multiple `@acme.com` prospects exist, keep the one with the most specific `why_relevant`, and leave the others as `status: "new"` for the next run. Tell the user "Deferred N prospects sharing domains with this batch — run `/email-all` again to reach them." Domains like `gmail.com`, `outlook.com`, `proton.me` count as separate (they're not shared inboxes), but `@<company>.com` always dedupes.

2. Determine the pitch:
   - If `$ARGUMENTS` is non-empty, that is the pitch for this run. Also save it to `~/email-outreach/pitch.md` (overwrite).
   - Else if `~/email-outreach/pitch.md` exists and is non-empty, read it.
   - Else ask the user: "What are you pitching? 1-2 sentences on what you're building, who it's for, and the ask. I'll save this for next time." Save the response to `~/email-outreach/pitch.md`.

3. Also ask once per run (only if not already in `~/email-outreach/signature.md`): "How should I sign these? (e.g., 'Steven', '— Steven, ancientbest@gmail.com')". Save to `~/email-outreach/signature.md` for reuse.

4. Read `~/email-outreach/sender.txt` (single line: the email address Mail.app will send from). If missing or empty, stop and tell the user to write their sending address there. Surface this address to the user in the approval gate — it determines which inbox replies land in and which sender identity recipients see.

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

For each approved draft:

1. Write the body to a temp file: `mktemp /tmp/email-XXXXXX.txt`, write the body there.
2. Call the helper: `~/email-outreach/send.sh "<email>" "<subject>" "<temp-body-file>"`. The helper drives Mail.app via AppleScript and handles encoding.
3. If the helper exits non-zero, STOP the batch. Report which prospect failed and why. Do not continue.
4. On success, update that prospect's entry in `prospects.json`: set `status` to `"sent"` and add `sent_at` (ISO 8601).
5. Append a record to `~/email-outreach/sent.json` with `{name, email, subject, body, sent_at}`.
6. `sleep 60` between sends. Human pacing, not script pacing — this is the single biggest signal Gmail uses to distinguish you from a sequencer tool.
7. Clean up the temp file.

## Cap

Hard cap: **5 sends per invocation.** Cold-email volume from a personal Gmail is the #1 signal that downgrades sender reputation — five/day stays under the threshold Gmail's classifier learned to flag. If more than 5 are approved, send the first 5 and tell the user "Sent 5, K remaining still marked 'new'. Run `/email-all` again tomorrow." Encourage spacing batches across days, not stacking them in the same hour.

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
- If `send.sh` is missing or not executable, stop and tell the user — do not try to inline the AppleScript yourself.
- If the user's Mail.app is not configured / no account, the AppleScript will fail. Surface the error verbatim.
