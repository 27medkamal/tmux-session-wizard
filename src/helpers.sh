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
echo "$HOME" | grep -E "^[a-zA-Z0-9\-_/.@]+$" &>/dev/null # chars safe to use in sed
HOME_SED_SAFE=$?
if [ $HOME_SED_SAFE -eq 0 ]; then # $HOME should be safe to use in sed
  HOME_REPLACER="s|^$HOME|~|"
  TILDE_REPLACER="s|^~|$HOME|"
fi

__fzfcmd() {
  [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

build_session_list() {
  local select_window="$1"
  local result
  if [ "$select_window" == "on" ]; then
    result=$(tmux list-windows -a -F "#{session_last_attached} #{session_name}: #{window_name}(#{window_index})\
#{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}#{?session_attached,#{?window_active, (attached),},}")
  else
    result=$(tmux list-sessions -F "#{session_last_attached} #{session_name}: #{session_windows} window(s)\
#{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}#{?session_attached, (attached),}")
  fi
  echo "$result" |
    sort -r | (if [ -n "$TMUX" ]; then grep -v " $(tmux display-message -p '#S'):"; else cat; fi) | cut -d' ' -f2-
  zoxide query -l | sed -e "$HOME_REPLACER"
}
