assert_tmux_running() {
  run pgrep tmux
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
  actual="$(tmux list-sessions | wc -l)"
  assert_equal "$actual" "$expected"
}

assert_tmux_session_exists() {
  local session_name=$1
  output="$(tmux list-sessions -F "#{session_name}")"
  assert_output "$session_name"
}
  
