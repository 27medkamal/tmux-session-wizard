assert_tmux_running() {
  # list-sessions only succeeds against the isolated test server (TMUX_TMPDIR)
  run tmux list-sessions
  assert_success
}

assert_tmux_option_equal() {
  local option=$1
  local expected=$2
  local actual
  actual="$(tmux show-option -gqv "$option")"
  assert_equal "$actual" "$expected"
}

assert_tmux_sessions_number() {
  local expected=$1
  local actual
  actual="$(tmux list-sessions | wc -l | tr -d '[:space:]')" # BSD wc pads with spaces
  assert_equal "$actual" "$expected"
}

assert_tmux_session_exists() {
  # Based on existing implementation of bat's asserts
  local -i is_match_line=0
  local -i is_mode_partial=0
  local -i is_mode_regexp=0

  while (($# > 0)); do
    case "$1" in
    -p | --partial)
      is_mode_partial=1
      shift
      ;;
    -e | --regexp)
      is_mode_regexp=1
      shift
      ;;
    -n | --index)
      is_match_line=1
      local -ri idx="$2"
      shift 2
      ;;
    *) break ;;
    esac
  done

  local expected=${1}
  run tmux list-sessions -F "#{session_name}"

  if ((is_match_line)); then
    if ((is_mode_partial)); then
      assert_line --index "$idx" --partial "$expected"
    elif ((is_mode_regexp)); then
      assert_line --index "$idx" --regexp "$expected"
    else
      assert_line --index "$idx" "$expected"
    fi
  else
    if ((is_mode_partial)); then
      assert_line --partial "$expected"
    elif ((is_mode_regexp)); then
      assert_line --regexp "$expected"
    else
      assert_line "$expected"
    fi
  fi
}

assert_tmux_session_attached() {
  local expected=$1
  assert_equal "$(cat "$BATS_TEST_TMPDIR/attached_session")" "$expected"
}
