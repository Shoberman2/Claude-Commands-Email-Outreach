#!/usr/bin/env bash
# Install Claude Commands: Email Outreach.
# Copies command files to ~/.claude/commands/ and sets up ~/email-outreach/.
# Idempotent: re-running won't overwrite your prospects, sent log, or sender config.

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "error: macOS only (this tool drives Mail.app via AppleScript)" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CMD_DIR="$HOME/.claude/commands"
DATA_DIR="$HOME/email-outreach"

echo "Installing Claude Commands: Email Outreach"
echo "  repo:  $REPO_DIR"
echo "  cmds:  $CMD_DIR"
echo "  data:  $DATA_DIR"
echo ""

# --- Commands (always overwrite — these are code) ---
mkdir -p "$CMD_DIR"
for f in find-emails.md email-all.md email-todo.md; do
  cp "$REPO_DIR/commands/$f" "$CMD_DIR/$f"
  echo "  installed ~/.claude/commands/$f"
done

# --- Data dir + helper script ---
mkdir -p "$DATA_DIR"
cp "$REPO_DIR/send.sh" "$DATA_DIR/send.sh"
chmod +x "$DATA_DIR/send.sh"
echo "  installed ~/email-outreach/send.sh"

# --- Seed data files only if missing (don't clobber user data) ---
for f in prospects.json sent.json; do
  if [[ ! -f "$DATA_DIR/$f" ]]; then
    echo "[]" > "$DATA_DIR/$f"
    echo "  created  ~/email-outreach/$f"
  else
    echo "  kept     ~/email-outreach/$f (already exists)"
  fi
done

if [[ ! -f "$DATA_DIR/TODO.md" ]]; then
  cp "$REPO_DIR/templates/TODO.md" "$DATA_DIR/TODO.md"
  echo "  created  ~/email-outreach/TODO.md"
else
  echo "  kept     ~/email-outreach/TODO.md (already exists)"
fi

# --- Sender configuration ---
echo ""
if [[ -f "$DATA_DIR/sender.txt" && -s "$DATA_DIR/sender.txt" ]]; then
  sender_email=$(head -1 "$DATA_DIR/sender.txt" | tr -d '[:space:]')
  echo "Existing sender: $sender_email"
  echo "  (to change, edit ~/email-outreach/sender.txt directly)"
else
  echo "What email address should /email-all send from?"
  echo "It must be an account already configured in macOS Mail.app."
  printf "  sender email: "
  read -r sender_email
  if [[ -z "$sender_email" ]]; then
    echo "error: empty sender, aborting" >&2
    exit 1
  fi
  printf '%s\n' "$sender_email" > "$DATA_DIR/sender.txt"
  echo "  saved to ~/email-outreach/sender.txt"
fi

# --- Verify Mail.app has the account ---
echo ""
echo "Checking Mail.app for $sender_email..."
mail_accounts=$(osascript -e 'tell application "Mail" to get email addresses of every account' 2>/dev/null || true)
if [[ -z "$mail_accounts" ]]; then
  echo "  warning: could not query Mail.app. Make sure it is installed and has at least one account configured."
elif [[ "$mail_accounts" == *"$sender_email"* ]]; then
  echo "  ok: $sender_email is configured in Mail.app"
else
  echo "  warning: $sender_email was NOT found in Mail.app."
  echo "  Mail.app currently has: $mail_accounts"
  echo "  Add the account in System Settings -> Internet Accounts, or edit ~/email-outreach/sender.txt."
fi

echo ""
echo "Done. Start Claude Code and try:"
echo "  /find-emails  indie hackers building developer tools"
echo "  /email-all"
echo "  /email-todo"
