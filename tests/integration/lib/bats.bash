TEST_DIR="/tmp/tests"

# Only ever talks to the isolated test server (TMUX_TMPDIR), never the user's.
_stop_tmux() {
  tmux kill-server 2>/dev/null || true
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

  mkdir -p "$TEST_DIR"
  # Isolate the test tmux server from any real one: tmux puts its socket in
  # TMUX_TMPDIR, so kill-server/list-sessions here can never touch the user's
  # sessions. Unsetting TMUX also makes it safe to run tests from inside tmux.
  export TMUX_TMPDIR="$TEST_DIR/tmux-socket"
  mkdir -p "$TMUX_TMPDIR"
  unset TMUX
  export SESSION_WIZARD_INTEGRATION_TEST=true
  _stop_tmux
  _add_tmux_plugin
}

_common_teardown() {
  _stop_tmux
  rm -rf "$TEST_DIR"
}
