# bats file_tags=integration

setup() {
  load ./lib/bats.bash
  _common_setup
  export SESSION_WIZARD_LOG_FILE="${TEST_DIR}/debug.log"
  rm -rf "$SESSION_WIZARD_LOG_FILE"
}

teardown() {
  _common_teardown
}

@test "No log file if @session-wizard-debug is not set" {
  t .
  assert_tmux_running
  assert_file_not_exists "$SESSION_WIZARD_LOG_FILE"
}

@test "Create log file if @session-wizard-debug is set" {
  echo "set-option -g @session-wizard-log-file '$SESSION_WIZARD_LOG_FILE'" >>"$TEST_DIR/tmux.conf"
  assert_file_not_exists "$SESSION_WIZARD_LOG_FILE"
  t .
  assert_tmux_running
  assert_file_exists "$SESSION_WIZARD_LOG_FILE"
  # Check content of logfile
  run cat "$SESSION_WIZARD_LOG_FILE"
  assert_line -p "Running session-wizard plugin"
}
