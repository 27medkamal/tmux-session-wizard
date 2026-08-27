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

# Appends a timestamped line to @session-wizard-log-file, when set.
# Needs a reachable tmux server (options live on the server); silently a no-op
# otherwise.
log_message() {
  local log_file
  log_file=$(get_tmux_option "@session-wizard-log-file")
  if [ -z "$log_file" ]; then
    return 0
  fi
  echo "$(date +"%Y-%m-%d %H:%M:%S") $1" >>"$log_file"
}

# Ensures a session named $1 exists (creating it for directory $2 when
# needed) and echoes the final session name.
# When @session-wizard-pre-create-session-hook is set, it runs first as:
#   <hook> <session-name> <directory>
# If it prints two lines, they replace the session name and directory.
# If it exits non-zero, the wizard aborts (returns 1, no session created).
create_session() {
  local session="$1" dir="$2"
  local pre_hook hook_output
  pre_hook=$(get_tmux_option "@session-wizard-pre-create-session-hook")
  if [ -n "$pre_hook" ]; then
    log_message "Running pre-create-session-hook: $pre_hook"
    # The hook command itself is expanded (it may carry its own flags), but
    # session/dir are passed as quoted arguments and never re-parsed, so
    # hostile directory names cannot inject shell code.
    if ! hook_output=$(eval "$pre_hook \"\$session\" \"\$dir\""); then
      log_message "pre-create-session-hook failed, aborting"
      return 1
    fi
    if [ -n "$hook_output" ]; then
      session=$(echo "$hook_output" | sed -n '1p')
      dir=$(echo "$hook_output" | sed -n '2p')
    fi
  fi

  if ! tmux has-session -t="$session" 2>/dev/null; then
    log_message "Creating session '$session' for directory '$dir'"
    tmux new-session -d -s "$session" -c "$dir"

    # Runs only when a session was actually created (e.g. to build a project
    # layout), as: <hook> <session-name> <directory>. Output is discarded and
    # a failure is logged but does not abort: the session already exists and
    # the user should still land in it.
    local post_hook
    post_hook=$(get_tmux_option "@session-wizard-post-create-session-hook")
    if [ -n "$post_hook" ]; then
      log_message "Running post-create-session-hook: $post_hook"
      if ! eval "$post_hook \"\$session\" \"\$dir\"" >/dev/null 2>&1; then
        log_message "post-create-session-hook failed (continuing)"
      fi
    fi
  fi

  echo "$session"
}

# Attaches (outside tmux) or switches (inside tmux) to a session, optionally
# selecting a window.
attach_to_tmux_session() {
  local session="$1" window="$2"
  # Escape a lone ~, which tmux would otherwise parse as the marked pane:
  # https://github.com/tmux/tmux/blob/master/cmd-find.c#L1024C51-L1024C57
  session=$(echo "$session" | sed 's/^~$/\\~/')

  if [ -n "$SESSION_WIZARD_INTEGRATION_TEST" ]; then
    # Test double: attaching would steal the test terminal
    [ -n "$BATS_TEST_TMPDIR" ] && echo "$session" >"$BATS_TEST_TMPDIR/attached_session"
    return 0
  fi

  if [ -z "$TMUX" ]; then
    tmux attach -t "$session"
  else
    tmux switch-client -t "$session"
  fi

  if [ -n "$window" ]; then
    tmux select-window -t "$session:$window"
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

# Renders the fzf preview for a picker row: pane contents for session/window
# rows, a directory listing (eza when available, ls otherwise) for directory
# rows.
# $1: the full row, i.e. fzf's {}
preview_row() {
  local row="$1"
  if [[ "$row" == *:* ]]; then
    local session="${row%%:*}"
    # Lone ~ would be parsed by tmux as the marked pane; escape it
    [ "$session" = "~" ] && session='\~'
    local window target="$session"
    window=$(echo "$row" | sed -n 's/.*(\([0-9][0-9]*\)).*/\1/p')
    [ -n "$window" ] && target="$session:$window"
    # Captures are pane-sized, usually larger than the preview window: drop
    # the blank tail below the prompt and show the most recent lines that fit
    # (fzf exports FZF_PREVIEW_LINES to preview commands).
    tmux capture-pane -ep -t "$target" 2>/dev/null |
      awk 'NF { last = NR } { lines[NR] = $0 } END { for (i = 1; i <= last; i++) print lines[i] }' |
      tail -n "${FZF_PREVIEW_LINES:-40}"
  else
    local dir="${row/#\~/$HOME}"
    if command -v eza >/dev/null 2>&1; then
      eza --tree --level=1 --color=always "$dir"
    else
      ls -A "$dir"
    fi
  fi
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
