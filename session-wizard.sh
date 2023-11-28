#!/usr/bin/env bash

# Usage: t <optional zoxide-like dir, relative or absolute path>
# If no argument is given, a combination of existing sessions and a zoxide query will be displayed in a FZF

__fzfcmd() {
  [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

# Parse optional argument
if [ "$1" ]; then
  # Argument is given
  eval "$(zoxide init bash)"
  RESULT=$(z $@ && pwd)
else
  # No argument is given. Use FZF
  RESULT=$((tmux list-sessions -F "#{session_last_attached} #{session_name}: #{session_windows} window(s)\
#{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}#{?session_attached, (attached),}"\
| sort -r | (if [ -n "$TMUX" ]; then grep -v " $(tmux display-message -p '#S'):"; else cat; fi) | cut -d' ' -f2-; zoxide query -l)  | $(__fzfcmd) --reverse)
  if [ -z "$RESULT" ]; then
    exit 0
  fi
fi

# Get or create session
if [[ $RESULT == *":"* ]]; then
  # RESULT comes from list-sessions
  SESSION=$(echo $RESULT | awk '{print $1}')
  SESSION=${SESSION//:/}
else
  # RESULT is a path
  SESSION=$(basename "$RESULT" | tr . - | tr ' ' - | tr ':' - | tr '[:upper:]' '[:lower:]')
  if ! tmux has-session -t=$SESSION 2> /dev/null; then
    tmux new-session -d -s $SESSION -c "$RESULT"
  fi
fi

# Attach to session
if [ -z "$TMUX" ]; then
  tmux attach -t $SESSION
else
  tmux switch-client -t $SESSION
fi

