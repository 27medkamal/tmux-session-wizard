setup() {
  bats_load_library 'bats-support'
  bats_load_library 'bats-assert'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  SRC_DIR="$DIR/../src"
  source "$SRC_DIR/helpers.sh"
  TEST_PATH="/MOO/.foo BAR/.moo FOO-bar.baz"
}

unset() {
  unset TEST_PATH
}

# TODO: use better stubbing for tmux (tmux show-option)
@test "get tmux option with default value" {
  # stub tmux
  function tmux() {
    assert_equal "$1" "show-option"
    assert_equal "$3" "moo-foo-bar"
  }
  run get_tmux_option "moo-foo-bar" "bar"
  assert_output "bar"
}

@test "get tmux option with value" {
  # stub tmux
  function tmux() {
    assert_equal "$1" "show-option"
    assert_equal "$3" "moo-foo-bar"
    # option value is set to "foo"
    echo "foo"
  }
  run get_tmux_option "moo-foo-bar" "bar"
  assert_output "foo"
}

@test "create session name with last directory in path" {
  run session_name --directory "$TEST_PATH"
  assert_output "-moo-foo-bar-baz"
}

@test "create session name with full path" {
  run session_name --full-path "$TEST_PATH"
  assert_output "/moo/-foo-bar/-moo-foo-bar-baz"
}

@test "create session name with shortened path and last directory in path" {
  run session_name --short-path "$TEST_PATH"
  assert_output "/mo/-f/-moo-foo-bar-baz"
}

