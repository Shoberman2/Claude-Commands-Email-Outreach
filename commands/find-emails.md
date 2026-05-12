# Find Emails

You are doing outreach research for the user. Find real, personal email addresses for people who would plausibly help, use, or amplify whatever the user is building.

## Argument

Target description: $ARGUMENTS

If the argument is empty, ask the user: "Who do you want to reach? (e.g., 'indie hackers building dev tools', 'design system leads at fintechs', 'creators with 10-50k Twitter followers in AI')". Do not proceed until you have a concrete target.

## Setup

1. Ensure `~/email-outreach/` exists. If `~/email-outreach/prospects.json` is missing or unreadable, initialize it as `[]`.
2. Load the web tools you need: call `ToolSearch` with query `select:WebSearch,WebFetch`. WebSearch and WebFetch are deferred and won't work until you do this.

## Research workflow

1. **Brainstorm queries.** Translate the target description into 5-8 different WebSearch queries. Mix angles:
   - Direct: `<niche> founder contact email`
   - Listicles: `top <niche> creators 2025`, `best <niche> newsletters`
   - Communities: `<niche> indie hackers`, `<niche> Show HN`, `<niche> Product Hunt makers`
   - Author bylines: `<niche> blog author email`
   - Twitter/X bios with linked personal sites
   - YC batch directories if relevant: `Y Combinator <niche>`

2. **Fetch the most promising results with WebFetch.** Look on each page for:
   - `mailto:` links
   - Plain-text emails in author bios, contact pages, about pages, footers
   - Links to personal homepages from social profiles → recursively fetch those if they look like a single-person site
   - Newsletter signup pages often expose the author's email in their privacy/contact section

3. **Quality filter.** Keep only emails where you have meaningful context. Reject:
   - Role accounts: `support@`, `sales@`, `info@`, `hello@`, `team@` — unless that's clearly a 1-person company
   - Anything that looks placeholder-ish (`email@example.com`, `name@domain.com`)
   - Emails you didn't actually verify came from a real page (don't hallucinate)
   - Anyone you cannot write a specific `why_relevant` sentence about

4. **Dedupe.** Read `~/email-outreach/prospects.json` and skip any email already present.

5. **Append new prospects.** Update `~/email-outreach/prospects.json` to include the new entries. Each entry is shaped like:

   ```json
   {
     "name": "...",
     "email": "...",
     "role": "founder of X / writes Y newsletter / ...",
     "company": "...",
     "why_relevant": "1-2 specific sentences about why THIS person would care about THIS platform",
     "source_url": "URL where you found the email",
     "found_at": "ISO 8601 timestamp",
     "status": "new"
   }
   ```

   The whole file stays a single JSON array. Don't reformat or reorder existing entries.

## Report

Print a short table to the user:

```
Found N new prospects (M total)

  #  Name                  Email                          Why
  1  Jane Doe              jane@example.com               Runs newsletter on X with 8k devs; built Y last month
  2  ...
```

Followed by: "Run `/email-all` to draft and send outreach to these N people."

## Rules

- Be conservative. 5 well-researched prospects beat 50 spammy ones.
- Never invent an email. If you cannot find one from a real page, skip the person.
- Never include role accounts when a personal one is also visible — prefer the personal one.
- If the user passed a tiny niche and you can only find 1-2 real prospects, that's fine — report it honestly.
- The prospects file is append-only — never delete or overwrite existing entries.
