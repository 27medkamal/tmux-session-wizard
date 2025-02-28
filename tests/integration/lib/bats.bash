TEST_DIR="/tmp/tests"

_stop_tmux() {
  run pgrep tmux
  if [ "$status" -eq 0 ]; then
    tmux kill-server
  fi
}

_add_tmux_plugin() {
  export _ZO_DATA_DIR="$TEST_DIR/zoxide"
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  export TMUX_CONFIG="$TEST_DIR/tmux.conf"
  echo "run-shell $DIR/../../session-wizard.tmux" >"$TMUX_CONFIG"
}

_common_setup() {
  bats_require_minimum_version 1.5.0
  bats_load_library 'bats-support'
  bats_load_library 'bats-assert'
  # relative to the test file, not to the current directory
  load ./lib/tmux-assert

  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  PATH="$DIR/../../bin:$PATH"

  if [ -n "$TMUX" ]; then
    fail "Plase run these tests outisde of tmux"
  fi
  mkdir -p "$TEST_DIR"
  export SESSION_WIZARD_INTEGRATION_TEST=true
  _stop_tmux
  _add_tmux_plugin
}

_common_teardown() {
  _stop_tmux
  rm -rf "$TEST_DIR"
}
