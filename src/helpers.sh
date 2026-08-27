_normalize() {
  cat | tr ' .:' '-' | tr '[:upper:]' '[:lower:]'
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

# Prevents overriding user's options
set_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value
  option_value=$(tmux show-option -gqv "$option")
  if [ -z "$option_value" ]; then
    tmux set-option -g "$option" "$default_value"
  fi
}

session_name() {
  if [ "$1" = "--directory" ]; then
    shift
    basename "$@" | _normalize
  elif [ "$1" = "--full-path" ]; then
    shift
    echo "$@" | _normalize | sed 's/\/$//'
  elif [ "$1" = "--short-path" ]; then
    shift
    echo "$(echo "${@%/*}" | sed -r 's;/([^/]{1,2})[^/]*;/\1;g' | _normalize)/$(basename "$@" | _normalize)"
  else
    echo "Wrong argument, you can use --directory, --full-path or --short-path, got $1"
    return 1
  fi
}

HOME_REPLACER=""                                          # default to a noop
TILDE_REPLACER=""                                         # default to a noop
echo "$HOME" | grep -E "^[a-zA-Z0-9_/.@-]+$" >/dev/null 2>&1 # chars safe to use in sed (dash last: BSD grep rejects escaped dash mid-bracket)
HOME_SED_SAFE=$?
if [ $HOME_SED_SAFE -eq 0 ]; then # $HOME should be safe to use in sed
  HOME_REPLACER="s|^$HOME|~|"
  TILDE_REPLACER="s|^~|$HOME|"
fi

__fzfcmd() {
  [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

# Prints the picker candidates: existing sessions (or windows when $1 is "on")
# ordered by most recently attached, followed by zoxide's directories.
# Lines are prefixed with #{session_last_attached} for sorting, then the
# timestamp is cut away. It is empty/0 for sessions never attached (e.g.
# restored by tmux-resurrect).
build_session_list() {
  local select_window="$1"
  local list
  if [ "$select_window" == "on" ]; then
    list=$(tmux list-windows -a -F "#{session_last_attached} #{session_name}: #{window_name}(#{window_index})\
#{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}#{?session_attached,#{?window_active, (attached),},}" 2>/dev/null)
  else
    list=$(tmux list-sessions -F "#{session_last_attached} #{session_name}: #{session_windows} window(s)\
#{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}#{?session_attached, (attached),}" 2>/dev/null)
  fi
  # Numeric sort so never-attached sessions (empty/0 timestamp) sink to the
  # bottom; LC_ALL=C because some locales collate blanks in ways that float
  # them to the top (GNU sort). See PR #18.
  echo "$list" |
    LC_ALL=C sort -rn | (if [ -n "$TMUX" ]; then grep -v " $(tmux display-message -p '#S'):"; else cat; fi) | cut -d' ' -f2-
  zoxide query -l | sed -e "$HOME_REPLACER"
}

# Kills the session a picker row refers to. Session/window rows have "name:"
# as their first field; anything else (a directory row) is ignored.
# $1: the row's first field, i.e. fzf's {1}
kill_session_from_row() {
  local first="$1"
  case "$first" in
  *:)
    local session="${first%:}"
    # Lone ~ would be parsed by tmux as the marked pane; escape it
    [ "$session" = "~" ] && session='\~'
    tmux kill-session -t "$session" 2>/dev/null
    ;;
  esac
}

# Succeeds when the fzf on PATH is at least version $1.$2
__fzf_version_at_least() {
  local want_major="$1" want_minor="$2" version major minor
  version=$(fzf --version 2>/dev/null | awk '{print $1}')
  major=${version%%.*}
  minor=${version#*.}
  minor=${minor%%.*}
  case "$major$minor" in *[!0-9]* | "") return 1 ;; esac
  [ "$major" -gt "$want_major" ] || { [ "$major" -eq "$want_major" ] && [ "$minor" -ge "$want_minor" ]; }
}
