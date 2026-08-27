#!/usr/bin/env bash
# post-create-session-hook example: builds a default layout for every newly
# created session — names the first window "editor", adds a "shell" window,
# and, when the directory is a git repository, a "git" window.
#
#   set -g @session-wizard-post-create-session-hook '/path/to/project-layout-hook.sh'
#
# Runs only when the wizard actually creates a session (never on reuse).

session="$1"
dir="$2"

# The session's only window at this point is the active one; no index needed
# (works with any base-index).
tmux rename-window -t "$session" "editor"
tmux new-window -d -t "$session" -n "shell" -c "$dir"

if [ -d "$dir/.git" ]; then
  tmux new-window -d -t "$session" -n "git" -c "$dir"
fi
