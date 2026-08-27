# bats file_tags=integration
setup() {
  load ./lib/bats.bash
  _common_setup
}

teardown() {
  _common_teardown
}

@test "t --kill-row kills the session for a picker row" {
  mkdir -p "$TEST_DIR/dir1" "$TEST_DIR/dir2"
  t "$TEST_DIR/dir1"
  t "$TEST_DIR/dir2"
  assert_tmux_sessions_number 2
  t --kill-row "dir1:"
  assert_tmux_sessions_number 1
  assert_tmux_session_exists "dir2"
}

@test "t --kill-row leaves sessions alone for a directory row" {
  mkdir -p "$TEST_DIR/dir1"
  t "$TEST_DIR/dir1"
  assert_tmux_sessions_number 1
  t --kill-row "$TEST_DIR/dir1"
  assert_tmux_sessions_number 1
}

@test "t --list-sessions prints picker rows for existing sessions" {
  mkdir -p "$TEST_DIR/dir1"
  t "$TEST_DIR/dir1"
  run t --list-sessions off
  assert_line --index 0 --partial "dir1: 1 window(s)"
}
