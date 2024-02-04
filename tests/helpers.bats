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

@test "fold home directory to symbol" {
  HOME="/home/user"
  local folder="/home/user"

  run fold_home "++" "$folder"
  assert_output "++"
}

@test "fold home directory to symbol with path" {
  local HOME="/home/user"
  local folder="/home/user/.foo/M O O"

  run fold_home "++" "$folder"
  assert_output "++/.foo/M O O"
}
