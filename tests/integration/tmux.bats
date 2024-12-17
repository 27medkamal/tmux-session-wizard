# bats file_tags=integration
_stop_tmux() {
  run pgrep tmux
  if [ "$status" -eq 0 ]; then
    tmux kill-server
  fi
}

_add_tmux_plugin() {
  export _ZO_DATA_DIR=/tmp/zoxite
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  echo "run-shell $DIR/../../session-wizard.tmux" >/tmp/tmux.conf
  export TMUX_CONFIG=/tmp/tmux.conf
}

setup() {
  bats_require_minimum_version 1.5.0
  bats_load_library 'bats-support'
  bats_load_library 'bats-assert'

  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  PATH="$DIR/../../bin:$PATH"

  if [ -n "$TMUX" ]; then
    fail "Plase run these tests outisde of tmux"
  fi
  export INTEGRATION_TEST=true
  _stop_tmux
  _add_tmux_plugin
}

assert_tmux_running() {
  run pgrep tmux
  assert_success
}

teardown() {
  _stop_tmux
  rm -rf /tmp/zoxite
  rm -rf /tmp/tmux.conf
}

@test "Can run 't' with loaded plugin" {
  t .
  assert_tmux_running
  # Checking default key binding for session wizard plugin
  option=$(tmux show-option -gqv @session-wizard)
  assert_equal "$option" "T"
}

@test "Can overwrite default options" {
  echo "set-option -g @session-wizard 't'" >>/tmp/tmux.conf
  t .
  assert_tmux_running
  # Checking default key binding for session wizard plugin
  option=$(tmux show-option -gqv @session-wizard-width)
  assert_equal "$option" "80"
  option=$(tmux show-option -gqv @session-wizard)
  assert_equal "$option" "t"
}
