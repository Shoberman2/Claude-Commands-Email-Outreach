#!/usr/bin/env bash
# Send an email via macOS Mail.app using AppleScript.
# Usage: send.sh <to> <subject> <body-file> [--draft]
# Body file path is required to avoid AppleScript string-escaping hell.

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <to> <subject> <body-file> [--draft]" >&2
  exit 1
fi

to="$1"
subject="$2"
body_file="$3"
mode="${4:-send}"

if [[ ! -f "$body_file" ]]; then
  echo "body file not found: $body_file" >&2
  exit 1
fi

# Resolve absolute path without depending on `realpath`
abs_body="$(cd "$(dirname "$body_file")" && pwd)/$(basename "$body_file")"

# AppleScript string-literal escaping: backslash, then double-quote
escape_as() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

esc_to=$(escape_as "$to")
esc_subject=$(escape_as "$subject")

# Read the sender email from sender.txt (sits next to this script).
# Mail.app uses this to pick which configured account does the actual send.
sender_file="$(cd "$(dirname "$0")" && pwd)/sender.txt"
if [[ ! -f "$sender_file" ]]; then
  echo "error: no sender configured. Write your sending email address to:" >&2
  echo "  $sender_file" >&2
  exit 1
fi
sender=$(head -1 "$sender_file" | tr -d '[:space:]')
if [[ -z "$sender" ]]; then
  echo "error: $sender_file is empty" >&2
  exit 1
fi
esc_sender=$(escape_as "$sender")

visible="false"
do_send="send newMessage"
if [[ "$mode" == "--draft" || "$mode" == "draft" ]]; then
  visible="true"
  do_send=""
fi

osascript <<APPLESCRIPT
set bodyText to (read POSIX file "$abs_body" as «class utf8»)
tell application "Mail"
    set newMessage to make new outgoing message with properties {sender:"$esc_sender", subject:"$esc_subject", content:bodyText, visible:$visible}
    tell newMessage
        make new to recipient at end of to recipients with properties {address:"$esc_to"}
    end tell
    $do_send
end tell
APPLESCRIPT
