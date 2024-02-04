setup() {
  bats_load_library 'bats-support'
  bats_load_library 'bats-assert'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  SRC_DIR="$DIR/../src"
  source "$SRC_DIR/helpers.sh"
  TEST_PATH="/MOO/.foo BAR/.moo FOO-bar.baz"
}

# TODO: Is this the best way to mock tmux?
tmux() {
  if [ "$1" = "list-sessions" ]; then
    # Session list, first collumn is attached timestamp
    cat <<HERE
15 /infructure: 1 window(s)
20 /tmux-session-wizard: 3 window(s)  (group /tmux-session-wizard) (attached)
30 /tmux-session-wizard-3: 3 window(s)  (group /tmux-session-wizard) (attached)
35 /joe doe/project: 1 window(s)
40 /tmux-session-wizard-5: 3 window(s)  (group /tmux-session-wizard)
HERE
  elif [ "$1" = "display-message" ]; then
    # Current session
    echo "/joe doe/project"
  fi
}

# Session list tests
@test "session list should return a list of sessions in reverse attached order" {
  run session_list
  assert_line -n 0 -e '^/tmux-session-wizard-5:'
  assert_line -n 1 -e '^/joe doe/project:'
  assert_line -n 2 -e '^/tmux-session-wizard-3:'
  assert_line -n 3 -e '^/tmux-session-wizard:'
  assert_line -n 4 -e '^/infructure:'
}

@test "session list should return list without current session" {
  run session_list --without-active

  refute_output --partial "/joe doe/project"
  assert_line -n 0 -e '^/tmux-session-wizard-5:'
}

# Session name tests
@test "create session name with last folder in path" {
  run session_name --folder "$TEST_PATH"
  assert_output "_moo-foo-bar_baz"
}

@test "create session name with full path" {
  run session_name --full-path "$TEST_PATH"
  assert_output "/moo/_foo-bar/_moo-foo-bar_baz"
}

@test "create session name with shortened path and last folder in path" {
  run session_name --short-path "$TEST_PATH"
  assert_output "/mo/_f/_moo-foo-bar_baz"
}
