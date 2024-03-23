#!/usr/bin/env bash

# Usage: t <optional zoxide-like dir, relative or absolute path>
# If no argument is given, a combination of existing sessions and a zoxide query will be displayed in a FZF

__fzfcmd() {
  [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

for argument in "$@"; do
  if [[ $argument != "-w" ]]; then
    # An argument is given that is not -w: directory
    dir=1
    break
  else
    windows=1
  fi
done

if [ $dir ]; then
  eval "$(zoxide init bash)"
  RESULT=$(z "$argument" && pwd)
else
  if [ $windows ]; then
    RESULT=$(tmux list-windows -a -F "#{session_last_attached} #{session_name}/#{window_name}\
#{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}#{?session_attached,#{?window_active, (attached),},}")
  else
    RESULT=$(tmux list-sessions -F "#{session_last_attached} #{session_name}: #{session_windows} window(s)\
#{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}#{?session_attached, (attached),}")
  fi
  # No argument is given. Use FZF
  RESULT=$( ( echo "$RESULT" \
| sort -r | (if [ -n "$TMUX" ]; then grep -v " $(tmux display-message -p '#S'):"; else cat; fi) | cut -d' ' -f2-; zoxide query -l)  | $(__fzfcmd) --reverse --print-query | tail -n 1)
  if [ -z "$RESULT" ]; then
    exit 0
  fi
fi

# Get or create session
if [[ ! $dir -eq 1 ]]; then
  # RESULT comes from tmux
  SESSION=$(echo $RESULT | awk '{print $1}')
  SESSION=${SESSION//:/}
  if [ $windows ]; then
    WINDOW=$(echo $SESSION | awk -F'/' '{ print $2 }')
    SESSION=$(echo $SESSION | awk -F'/' '{ print $1 }')
  fi
else
  # RESULT is a path

  # Quit if directory does not exists
  if [ ! -d "$RESULT" ]; then
    exit 0
  fi

  # Promote rank in zoxide.
  zoxide add "$RESULT"

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

if [ ! -z "$WINDOW" ]; then
  tmux select-window -t $WINDOW
fi
