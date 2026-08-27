#!/usr/bin/env bash
# pre-create-session-hook example: detects when a session name would collide
# with an existing session that points at a DIFFERENT directory (e.g. two
# projects both called "api") and prompts for a new name via fzf.
#
#   set -g @session-wizard-pre-create-session-hook '/path/to/resolve-session-conflict-hook.sh'
#
# Chosen names are remembered per directory in a per-user mapping file that
# resets on reboot. Directories containing ';' are not supported by the
# mapping format.

session="$1"
dir="$2"

if ! tmux has-session -t="$session" 2>/dev/null; then
  # No session with this name exists, proceed with the normal flow
  exit 0
fi

# Per-user location: a shared /tmp file would let another local user
# pre-create it and control or capture your mappings.
MAPPING_FILE="${TMPDIR:-/tmp}/tmux-session-wizard-mappings-$(id -u)"

# Reuse a previously chosen name for this directory
if [ -f "$MAPPING_FILE" ]; then
  stored_session=$(awk -F';' -v d="$dir" '$1 == d { print substr($0, length(d) + 2) }' "$MAPPING_FILE" | tail -1)
  if [ -n "$stored_session" ]; then
    echo "$stored_session"
    echo "$dir"
    exit 0
  fi
fi

session_dir=$(tmux display-message -t "$session" -p "#{session_path}")
if [ "$dir" != "$session_dir" ]; then
  # Name taken by a different directory: ask for a new one
  new_session=$(echo "" | fzf --print-query --prompt="Session '$session' already exists. Enter new name: " | head -1)
  if [ -z "$new_session" ]; then
    # Cancelled: abort the wizard (non-zero exit aborts session creation)
    exit 1
  fi
  echo "${dir};${new_session}" >>"$MAPPING_FILE"
  echo "$new_session"
  echo "$dir"
fi

# Session exists and points at the same directory: no output keeps the
# original values and the existing session is reused.
