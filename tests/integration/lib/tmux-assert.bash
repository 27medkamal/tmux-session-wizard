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
  local session_name=$1
  run tmux list-sessions -F "#{session_name}"
  assert_line "$session_name"
}

# bin/t under SESSION_WIZARD_INTEGRATION_TEST records the session it would
# have attached to instead of attaching (which would steal the terminal).
assert_tmux_session_attached() {
  local expected=$1
  assert_equal "$(cat "$BATS_TEST_TMPDIR/attached_session")" "$expected"
}
  
