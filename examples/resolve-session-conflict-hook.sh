#!/usr/bin/env bash
# Hook that detects when a session name would collide with an existing session
# that points to a different directory. Prompts the user to enter a new name via fzf.
# Custom name mappings are stored in /tmp and reset on OS reboot.

session="$1"
dir="$2"

if ! tmux has-session -t="$session" 2>/dev/null; then
  # No session with this name exists, proceed with normal flow
  exit 0
fi

MAPPING_FILE="/tmp/tmux-session-wizard-mappings"

# Check if this directory already has a custom session name
if [ -f "$MAPPING_FILE" ]; then
  stored_session=$(grep "^${dir};" "$MAPPING_FILE" | tail -1 | cut -d';' -f2-)
  if [ -n "$stored_session" ]; then
    echo "$stored_session"
    echo "$dir"
    exit 0
  fi
fi

session_dir=$(tmux display-message -t "$session" -p "#{pane_current_path}")
if [ "$dir" != "$session_dir" ]; then
  # Session name already taken by a different directory, ask user for a new name
  new_session=$(echo "" | fzf --print-query --prompt="Session '$session' already exists. Enter new name: " | head -1)
  if [ -z "$new_session" ]; then
    exit 1
  fi
  # Remember the mapping for next time
  echo "${dir};${new_session}" >>"$MAPPING_FILE"
  echo "$new_session"
  echo "$dir"
fi

# Session exists and directory matches — no output, so original values are kept and existing session is reused.
