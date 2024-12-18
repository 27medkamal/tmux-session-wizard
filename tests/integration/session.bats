# bats file_tags=integration
setup() {
  load ./lib/bats.bash
  _common_setup
}

teardown() {
  _common_teardown
}

@test "'directory' is default mode" {
  t .
  assert_tmux_option_equal "@session-wizard-mode" "directory"
}

assert_session_name() {
  local dir="$1"
  local expected_session_name="$2"
  mkdir -p "$dir"
  # Run session-wizard
  t "$dir"
  # Check if session was created with expected name
  assert_tmux_session_number 1
  session_name="$(tmux list-sessions -F "#{session_name}")"
  assert_equal "$session_name" "$expected_session_name"
  # Cleanup
  _stop_tmux
}

@test "Session name for 'directory' mode should be normalized directory name" {
  declare -A test_data
  test_data=(
    ["dir"]="$TEST_DIR/dir"
    ["dir-2"]="$TEST_DIR/dir.2"
    ["dir_3"]="$TEST_DIR/DIR_3"
  )

  for expected_session_name in "${!test_data[@]}"; do
    dir="${test_data[${expected_session_name}]}"
    assert_session_name "$dir" "$expected_session_name"
  done
}

@test "Session name for 'full-path' mode should be normalized full path" {
  declare -A test_data
  test_data=(
    ["$TEST_DIR/dir"]="$TEST_DIR/dir"
    ["$TEST_DIR/dir-2"]="$TEST_DIR/dir.2"
    ["$TEST_DIR/dir_3"]="$TEST_DIR/DIR_3"
  )
  echo "set -g @session-wizard-mode 'full-path'" >>"$TMUX_CONFIG"
  HOME="/tmp/home"

  for expected_session_name in "${!test_data[@]}"; do
    dir="${test_data[${expected_session_name}]}"
    assert_session_name "$dir" "$expected_session_name"
  done
}

@test "Session name for 'short-path' mode should be normalized short path" {
  declare -A test_data
  test_data=(
    ["/tm/te/dir"]="/tmp/tests/dir"
    ["/tm/te/dir-2"]="/tmp/tests/dir.2"
    ["/tm/te/-h/dir_3"]="/tmp/tests/.hidden/DIR_3"
  )
  echo "set -g @session-wizard-mode 'short-path'" >>"$TMUX_CONFIG"
  HOME="/tmp/home"

  for expected_session_name in "${!test_data[@]}"; do
    dir="${test_data[${expected_session_name}]}"
    assert_session_name "$dir" "$expected_session_name"
  done
}

@test "Run session-wizzard twice with the same directory should create ONLY one session" {
  mkdir -p "$TEST_DIR/dir"
  t "$TEST_DIR/dir"
  assert_tmux_session_number 1
  t "$TEST_DIR/dir"
  assert_tmux_session_number 1
}
@test "Run session-wizzard twice with different directory should create two sessions" {
  mkdir -p "$TEST_DIR/dir1"
  mkdir -p "$TEST_DIR/dir2"
  t "$TEST_DIR/dir1"
  assert_tmux_session_number 1
  t "$TEST_DIR/dir2"
  assert_tmux_session_number 2
}
