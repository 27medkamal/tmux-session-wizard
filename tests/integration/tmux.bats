# bats file_tags=integration
#
setup() {
  load ./lib/bats.bash
  _common_setup
}

teardown() {
  _common_teardown
}

@test "Can run 't' with loaded plugin" {
  t .
  assert_tmux_running
  # Checking default key binding for plugin (basic test if plugin is loaded)
  option=$(tmux show-option -gqv @session-wizard)
  assert_equal "$option" "T"
}

@test "Can overwrite default options" {
  # Change default binding for plugin
  echo "set-option -g @session-wizard 't'" >>"$TEST_DIR/tmux.conf"
  t .
  assert_tmux_running
  # Checking default option for plugin
  option=$(tmux show-option -gqv @session-wizard-width)
  assert_equal "$option" "80"
  # Checking  new binding for plugin
  option=$(tmux show-option -gqv @session-wizard)
  assert_equal "$option" "t"
}
