# bats file_tags=integration
setup() {
  load ./lib/bats.bash
  _common_setup
}

teardown() {
  _common_teardown
}

@test "t --preview-row lists directory contents for a directory row" {
  mkdir -p "$TEST_DIR/dir1"
  touch "$TEST_DIR/dir1/hello-file"
  t "$TEST_DIR/dir1" # boots the test server so tmux options resolve
  run t --preview-row "$TEST_DIR/dir1"
  assert_output --partial "hello-file"
}

@test "t --preview-row succeeds for a session row" {
  mkdir -p "$TEST_DIR/dir1"
  t "$TEST_DIR/dir1"
  run t --preview-row "dir1: 1 window(s)"
  assert_success
}
