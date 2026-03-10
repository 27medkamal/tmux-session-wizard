# bats file_tags=unit
SESSION_EXISTS=0
SESSION_NOT_EXISTS=1

setup() {
  bats_load_library 'bats-support'
  bats_load_library 'bats-assert'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  SRC_DIR="$DIR/../src"
  source "$SRC_DIR/helpers.sh"
  TEST_PATH="/MOO/.foo BAR/.moo FOO-bar.baz"
}

teardown() {
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

@test "create_session creates new tmux session and echoes session name" {
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_NOT_EXISTS" ;;
    new-session) ;;
    show-option) ;;
    esac
  }
  export -f tmux
  run create_session "my-session" "/tmp/my-dir"
  assert_output "my-session"
}

@test "create_session does not create new session for existing session" {
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_EXISTS" ;;
    new-session)
      echo "new-session should not be called" >&2
      return 1
      ;;
    show-option) ;;
    esac
  }
  export -f tmux
  run create_session "existing-session" "/tmp/dir"
  assert_output "existing-session"
}

# NOTE: This setup function is used for the next two tests to verify if the hook's modification of session name and/or target directory will be applied when creating a session.
_setup_hook_test() {
  local has_session_result="$1"
  NEW_SESSION_ARGS_FILE="$BATS_TEST_TMPDIR/new_session_args"
  function tmux() {
    case "$1" in
    has-session) return "$has_session_result" ;;
    # XXX: This is flaky, based on parameter order of tmux new-session
    new-session)
      echo "$4" >"$NEW_SESSION_ARGS_FILE"
      echo "$6" >>"$NEW_SESSION_ARGS_FILE"
      ;;
    show-option)
      if [ "$3" = "@session-wizard-pre-create-session-hook" ]; then
        echo "my_hook"
      fi
      ;;
    esac
  }
  function my_hook() {
    echo "modified-session"
    echo "/modified/dir"
  }
  export NEW_SESSION_ARGS_FILE
  export -f tmux my_hook
}

@test "create_session runs pre-create-session-hook and uses its output" {
  _setup_hook_test "$SESSION_NOT_EXISTS"
  run create_session "original-session" "/original/dir"
  assert_output "modified-session"
  assert_equal "$(sed -n '1p' "$NEW_SESSION_ARGS_FILE")" "modified-session"
  assert_equal "$(sed -n '2p' "$NEW_SESSION_ARGS_FILE")" "/modified/dir"
}

@test "create_session runs pre-create-session-hook and creates new session when hook changes name of existing session" {
  _setup_hook_test "$SESSION_EXISTS"
  run create_session "original-session" "/original/dir"
  assert_output "modified-session"
  assert_equal "$(sed -n '1p' "$NEW_SESSION_ARGS_FILE")" "modified-session"
  assert_equal "$(sed -n '2p' "$NEW_SESSION_ARGS_FILE")" "/modified/dir"
}

@test "create_session keeps original values when hook outputs nothing" {
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_NOT_EXISTS" ;;
    new-session) echo "new-session:$4:$6" ;;
    show-option)
      if [ "$3" = "@session-wizard-pre-create-session-hook" ]; then
        echo "silent_hook"
      fi
      ;;
    esac
  }
  function silent_hook() { :; }
  export -f tmux silent_hook
  run create_session "my-session" "/my/dir"
  assert_line --index 0 "new-session:my-session:/my/dir"
  assert_line --index 1 "my-session"
}

@test "create_session hook receives session and dir as arguments" {
  local hook_args_file="$BATS_TEST_TMPDIR/hook_args"
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_NOT_EXISTS" ;;
    new-session) ;;
    show-option)
      if [ "$3" = "@session-wizard-pre-create-session-hook" ]; then
        echo "arg_check_hook"
      fi
      ;;
    esac
  }
  # Hooks should got session name and session dir
  function arg_check_hook() {
    echo "$1" >"$HOOK_ARGS_FILE"
    echo "$2" >>"$HOOK_ARGS_FILE"
  }
  export HOOK_ARGS_FILE="$hook_args_file"
  export -f tmux arg_check_hook
  run create_session "test-session" "/test/dir"
  assert_equal "$(sed -n '1p' "$hook_args_file")" "test-session"
  assert_equal "$(sed -n '2p' "$hook_args_file")" "/test/dir"
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
