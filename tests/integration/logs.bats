# bats file_tags=integration

setup() {
  load ./lib/bats.bash
  _common_setup
  SESSION_WIZARD_LOG_FILE="${TEST_DIR}/debug.log"
  rm -rf "$SESSION_WIZARD_LOG_FILE"
}

teardown() {
  _common_teardown
}

@test "No log file if @session-wizard-log-file is not set" {
  t .
  assert_tmux_running
  [ ! -e "$SESSION_WIZARD_LOG_FILE" ]
}

@test "Create log file if @session-wizard-log-file is set" {
  echo "set-option -g @session-wizard-log-file '$SESSION_WIZARD_LOG_FILE'" >>"$TEST_DIR/tmux.conf"
  [ ! -e "$SESSION_WIZARD_LOG_FILE" ]
  t .
  assert_tmux_running
  [ -f "$SESSION_WIZARD_LOG_FILE" ]
  run cat "$SESSION_WIZARD_LOG_FILE"
  assert_line --partial "Running session-wizard"
}
