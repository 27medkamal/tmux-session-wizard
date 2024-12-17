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
  sessions_counter=$(tmux list-sessions | wc -l)
  assert_equal 1 "$sessions_counter"
  session_name="$(tmux list-sessions -F "#{session_name}")"
  assert_equal "$session_name" "$expected_session_name"
  # Cleanup
  _stop_tmux
}

@test "Session name for 'directory' mode should be normalized directory name" {
  declare -A test_data
  test_data=(
    ["dir"]="/tmp/dir"
    ["dir-2"]="/tmp/dir.2"
    ["dir_3"]="/tmp/DIR_3"
  )

  for expected_session_name in "${!test_data[@]}"; do
    dir="${test_data[${expected_session_name}]}"
    assert_session_name "$dir" "$expected_session_name"
  done
}

@test "Session name for 'full-path' mode should be normalized full path" {
  declare -A test_data
  test_data=(
    ["/tmp/dir"]="/tmp/dir"
    ["/tmp/dir-2"]="/tmp/dir.2"
    ["/tmp/dir_3"]="/tmp/DIR_3"
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
    ["/tm/dir"]="/tmp/dir"
    ["/tm/dir-2"]="/tmp/dir.2"
    ["/tm/-h/dir_3"]="/tmp/.hidden/DIR_3"
  )
  echo "set -g @session-wizard-mode 'short-path'" >>"$TMUX_CONFIG"
  HOME="/tmp/home"

  for expected_session_name in "${!test_data[@]}"; do
    dir="${test_data[${expected_session_name}]}"
    assert_session_name "$dir" "$expected_session_name"
  done
}
