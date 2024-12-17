_stop_tmux() {
  run pgrep tmux
  if [ "$status" -eq 0 ]; then
    tmux kill-server
  fi
}

_add_tmux_plugin() {
  export _ZO_DATA_DIR=/tmp/zoxite
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  export TMUX_CONFIG=/tmp/tmux.conf
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
  export INTEGRATION_TEST=true
  _stop_tmux
  _add_tmux_plugin
}

_common_teardown() {
  _stop_tmux
  rm -rf /tmp/zoxite
  rm -rf /tmp/tmux.conf
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
