# Find Emails

The front door of email outreach. Captures the user's goal, researches real personal emails for the target, and saves both. After this, `/email-all` or `/email-auto` can send without asking for the pitch again.

## Argument

Target description: $ARGUMENTS

If empty, ask once: "Who do you want to reach? (e.g., 'indie hackers building dev tools', 'design system leads at fintechs', 'creators with 10-50k followers in AI')". Don't proceed without a concrete target.

## Capture the goal (saves the pitch)

Check `~/email-outreach/pitch.md`. If missing or empty, ask once:

> "What's your goal for these emails? 1-2 sentences on what you're building, who it's for, and the ask. (E.g., 'I'm building a CLI for AI agents and want feedback from indie hackers who've shipped similar tools.')"

Save the answer to `~/email-outreach/pitch.md` (overwrite). This is the pitch every `/email-all` and `/email-auto` run will use from now on.

If `pitch.md` already exists, use it silently. The user can edit the file to change their goal.

## Setup

1. Ensure `~/email-outreach/` exists. If `prospects.json` is missing, initialize as `[]`.
2. Load web tools: call `ToolSearch` with `select:WebSearch,WebFetch`. Without this they won't run.

## Research

Brainstorm 5-8 search queries from different angles (direct contact searches, "best <niche> creators" listicles, Show HN / Product Hunt makers, newsletter author bios, YC batch directories). Bias query selection toward people who'd care about the saved pitch, not just the demographic — a CLI-tools pitch wants makers who've shipped CLI tools, not generic devs. **Run searches in parallel.** Then fetch the most promising results in parallel, looking for `mailto:` links, plain-text emails in author/contact/about/footer sections, and personal homepages linked from social profiles.

Keep only prospects where you can write a specific, non-generic `why_relevant` sentence that ties the person to **the pitch**, not just the target description. **Reject:** role accounts (`support@`, `info@`, `hello@`, `team@`) unless it's a one-person company, placeholder emails (`name@domain.com`), and anything you didn't actually see on a real page. Never invent an email.

Dedupe against existing entries in `prospects.json` by email.

## Append

For each new prospect, append to `prospects.json` (keep the file a single JSON array; don't reformat existing entries):

```json
{
  "name": "...",
  "email": "...",
  "role": "founder of X / writes Y newsletter / ...",
  "company": "...",
  "why_relevant": "1-2 specific sentences tying this person to the saved pitch",
  "source_url": "URL where you found the email",
  "found_at": "ISO 8601 timestamp",
  "status": "new"
}
```

## Report

```
Goal: <one-line summary of pitch.md>
Found N new prospects (M total)

  #  Name           Email                   Why
  1  Jane Doe       jane@example.com        Runs newsletter on X with 8k devs; built Y last month
```

Then: **"Next: run `/email-all` to draft and send — it'll use the saved pitch."**

## Rules

- 5 well-researched prospects beat 50 spammy ones. If the niche is tiny and you only find 1-2 real people, report that honestly.
- Never invent an email. If it's not on a real page you visited, skip the person.
- Prefer a personal email over a role account when both are visible.
- The prospects file is append-only — never delete or reorder.
- `pitch.md` is the source of truth for the goal. If the user wants to change goals, they edit that file (or delete it to be re-prompted next run).
