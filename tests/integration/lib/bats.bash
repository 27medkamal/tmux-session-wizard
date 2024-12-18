TEST_DIR="/tmp/tests"

_stop_tmux() {
  run pgrep tmux
  if [ "$status" -eq 0 ]; then
    tmux kill-server
  fi
}

_add_tmux_plugin() {
  export _ZO_DATA_DIR="$TEST_DIR/zoxite"
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  export TMUX_CONFIG="$TEST_DIR/tmux.conf"
  echo "run-shell $DIR/../../session-wizard.tmux" >"$TMUX_CONFIG"
}

_common_setup() {
  bats_require_minimum_version 1.5.0
  bats_load_library 'bats-support'
  bats_load_library 'bats-assert'

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

assert_tmux_session_number() {
  local expected=$1
  local actual
  actual="$(tmux list-sessions | wc -l)"
  assert_equal "$actual" "$expected"
}
