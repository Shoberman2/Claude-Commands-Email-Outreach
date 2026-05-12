# Email TODO

Manage the email-outreach TODO list at `~/email-outreach/TODO.md`. Used for follow-ups, prospects to research, templates to write — anything outreach-adjacent that isn't a single email send.

Argument: $ARGUMENTS

## Workflow

1. If `~/email-outreach/TODO.md` doesn't exist, create it with this skeleton:

   ```
   # Email Outreach TODO

   ## Pending

   ## Done
   ```

2. Read the file. Identify the **Pending** section and the **Done** section. Pending items are lines starting with `- [ ]`; Done items start with `- [x]`.

3. Decide intent from `$ARGUMENTS`:

   - **Empty argument** → list pending items, numbered 1..N (1-indexed within Pending only). If none, say "Nothing pending. Add one with `/email-todo <description>`."
   - **`list` or `ls`** → same as empty.
   - **`done <N>` / `check <N>` / `complete <N>` / `finish <N>`** → mark the Nth pending item as done. Change `- [ ]` to `- [x]`, append ` _(done <YYYY-MM-DD>)_`, and move the line to the bottom of the Done section. Confirm with "Done: <text>".
   - **`remove <N>` / `delete <N>` / `rm <N>`** → delete the Nth pending item entirely (no Done record). Confirm with "Removed: <text>".
   - **`show <N>` or just `<N>`** → print the full text of the Nth pending item.
   - **Anything else** → treat the entire `$ARGUMENTS` string as a new TODO. Append `- [ ] <text>  _(added <YYYY-MM-DD>)_` to the bottom of the Pending section. Confirm with "Added: <text>".

4. After modifying, print the current Pending list (numbered) so the user sees state.

## Rules

- Use ISO dates (`YYYY-MM-DD`), not relative.
- Preserve any free-form notes or extra sections the user added to TODO.md — only touch lines that match `- [ ]` or `- [x]` patterns in their respective sections.
- If `done N` or `remove N` is called with N out of range, say "There are only K pending items" and stop — don't guess.
- Never reformat existing entries (preserve their dates and casing).
