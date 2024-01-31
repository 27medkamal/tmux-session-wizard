setup() {
  bats_load_library 'bats-support'
  bats_load_library 'bats-assert'
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  SRC_DIR="$DIR/../src"
  source "$SRC_DIR/helpers.sh"
}

TEST_PATH="/MOO/.foo BAR/.moo FOO-bar.baz"

@test "create session name with last folder in path" {
  name=$(session_name --folder "$TEST_PATH")
  assert_equal "$name" "_moo-foo-bar_baz"
}

@test "create session name with full path" {
  name=$(session_name --full-path "$TEST_PATH")
  assert_equal "$name" "/moo/_foo-bar/_moo-foo-bar_baz"
}


@test "create session name with shortened path and last folder in path" {
  name=$(session_name --short-path "$TEST_PATH")
  assert_equal "$name" "/mo/_f/_moo-foo-bar_baz"
}

@test "fold home directory to symbol" {
  HOME="/home/user"
  FOLDER=$HOME

  name=$(fold_home "--" "$FOLDER")
  assert_equal "$name" "--"
}

@test "fold home directory to symbol with path" {
  HOME="/home/user"
  FOLDER="${HOME}/.foo/M O O"

  name=$(fold_home "++" "$FOLDER")
  assert_equal "$name" "++/.foo/M O O"
}
