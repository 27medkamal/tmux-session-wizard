_normalize() {
  # Replace dots with underline, replace all "special" chars with dashes and convert everything to lowercase.
  cat | tr '_' - | tr ' ' - | tr ':' - | tr . _ | tr '[:upper:]' '[:lower:]'
}

# helper functions
get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value
  option_value=$(tmux show-option -gqv "$option")
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

# Switch to the new created session
switch_client() {
  if [ -z "$TMUX" ]; then
    tmux attach -t "$*"
  else
    tmux switch-client -t "$*"
  fi
}

# Get the list of sessions
# The output is in the format:
#   last_attached session_name: windows_count (group group_name) (attached)
session_list() {
  local list
  list=$(tmux list-sessions -F "#{session_last_attached} #{session_name}: #{session_windows} window(s) #{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}#{?session_attached, (attached),}")
  if [ -n "$TMUX" ] && [ "$1" = "--without-active" ]; then
    list=$(echo "$list" | grep -v " $(tmux display-message -p '#S'):")
  fi
  echo "$list" | sort -r | cut -d' ' -f2-
}

# Show the fzf window, data is passed through stdin
show_fzf() {
  local fzf_cmd
  if [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; }; then
    fzf_cmd="fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- "
  else
    fzf_cmd="fzf"
  fi
  cat | $fzf_cmd --reverse
}

session_name() {
  if [ "$1" = "--folder" ]; then
    shift
    basename "$@" | _normalize
  elif [ "$1" = "--full-path" ]; then
    shift
    echo "$@" | tr '/' '\n' | _normalize | tr '\n' '/' | sed 's/\/$//'
  elif [ "$1" = "--short-path" ]; then
    shift
    echo "$(echo "${@%/*}" | sed -r 's;/([^/]{,2})[^/]*;/\1;g' | _normalize)/$(basename "$@" | _normalize)"
  else
    echo "Wrong argument, you can use --last-normalized, --full or --shortened, got $1"
    return 1
  fi
}

fold_home() {
  local symbol="$1"
  shift
  # shellcheck disable=SC2001
  echo "$@" | sed "s;^$HOME;$symbol;"
}
