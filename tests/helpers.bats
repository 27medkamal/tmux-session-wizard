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

@test "HOME_REPLACER is active for a typical HOME path (regression: BSD grep bracket range)" {
  # On macOS' stock grep, the old pattern [a-zA-Z0-9\-_/.@] exited 2 ("invalid
  # character range"), silently disabling ~ substitution for every user.
  run env HOME="/Users/some-user_1.name@x" bash -c 'source "'"$SRC_DIR"'/helpers.sh"; echo "$HOME_REPLACER"'
  assert_output 's|^/Users/some-user_1.name@x|~|'
}

@test "TILDE_REPLACER expands ~ back to HOME" {
  run env HOME="/Users/some-user" bash -c 'source "'"$SRC_DIR"'/helpers.sh"; echo "~/foo/bar" | sed -e "$TILDE_REPLACER"'
  assert_output "/Users/some-user/foo/bar"
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

# --- create_session ---------------------------------------------------------
@test "create_session creates a new tmux session and echoes its name" {
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_NOT_EXISTS" ;;
    new-session | show-option) ;;
    esac
  }
  run create_session "my-session" "/tmp/my-dir"
  assert_success
  assert_output "my-session"
}

@test "create_session does not create a session that already exists" {
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
  run create_session "existing-session" "/tmp/dir"
  assert_success
  assert_output "existing-session"
}

# Shared stub for the hook tests: hook is configured, captures new-session args
_setup_hook_test() {
  local has_session_result="$1"
  NEW_SESSION_ARGS_FILE="$BATS_TEST_TMPDIR/new_session_args"
  function tmux() {
    case "$1" in
    has-session) return "$HAS_SESSION_RESULT" ;;
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
  export HAS_SESSION_RESULT="$has_session_result"
  export NEW_SESSION_ARGS_FILE
}

@test "create_session runs pre-create-session-hook and uses its output" {
  _setup_hook_test "$SESSION_NOT_EXISTS"
  run create_session "original-session" "/original/dir"
  assert_success
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
  run create_session "my-session" "/my/dir"
  assert_line --index 0 "new-session:my-session:/my/dir"
  assert_line --index 1 "my-session"
}

@test "create_session passes session and dir to the hook as arguments" {
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
  function arg_check_hook() {
    echo "$1" >"$HOOK_ARGS_FILE"
    echo "$2" >>"$HOOK_ARGS_FILE"
  }
  export HOOK_ARGS_FILE="$BATS_TEST_TMPDIR/hook_args"
  run create_session "test-session" "/test/dir"
  assert_equal "$(sed -n '1p' "$HOOK_ARGS_FILE")" "test-session"
  assert_equal "$(sed -n '2p' "$HOOK_ARGS_FILE")" "/test/dir"
}

@test "create_session does not shell-parse hostile session/dir values" {
  # A directory named '$(touch pwned)' etc. must reach the hook verbatim and
  # must never be executed.
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
  function arg_check_hook() {
    echo "$1" >"$HOOK_ARGS_FILE"
    echo "$2" >>"$HOOK_ARGS_FILE"
  }
  export HOOK_ARGS_FILE="$BATS_TEST_TMPDIR/hook_args"
  run create_session 'evil; echo injected' '/tmp/$(touch "$BATS_TEST_TMPDIR/pwned")'
  assert_success
  # the final session name is echoed back verbatim, never executed
  assert_output 'evil; echo injected'
  assert_equal "$(sed -n '1p' "$HOOK_ARGS_FILE")" 'evil; echo injected'
  assert_equal "$(sed -n '2p' "$HOOK_ARGS_FILE")" '/tmp/$(touch "$BATS_TEST_TMPDIR/pwned")'
  [ ! -e "$BATS_TEST_TMPDIR/pwned" ]
}

@test "create_session aborts when the hook fails" {
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_NOT_EXISTS" ;;
    new-session)
      echo "new-session should not be called" >&2
      return 1
      ;;
    show-option)
      if [ "$3" = "@session-wizard-pre-create-session-hook" ]; then
        echo "failing_hook"
      fi
      ;;
    esac
  }
  function failing_hook() { return 1; }
  run create_session "my-session" "/my/dir"
  assert_failure
}

@test "post-create-session-hook receives the values the pre-hook modified" {
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_NOT_EXISTS" ;;
    new-session) ;;
    show-option)
      case "$3" in
      "@session-wizard-pre-create-session-hook") echo "pre_mod_hook" ;;
      "@session-wizard-post-create-session-hook") echo "post_capture_hook" ;;
      esac
      ;;
    esac
  }
  function pre_mod_hook() {
    echo "renamed"
    echo "/re/dir"
  }
  function post_capture_hook() { echo "$1:$2" >"$POST_ARGS_FILE"; }
  export POST_ARGS_FILE="$BATS_TEST_TMPDIR/post_args"
  run create_session "orig" "/orig/dir"
  assert_output "renamed"
  assert_equal "$(cat "$POST_ARGS_FILE")" "renamed:/re/dir"
}

@test "create_session runs post-create-session-hook after creating a session" {
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_NOT_EXISTS" ;;
    new-session) echo "created" >>"$CALL_ORDER_FILE" ;;
    show-option)
      if [ "$3" = "@session-wizard-post-create-session-hook" ]; then
        echo "post_hook"
      fi
      ;;
    esac
  }
  function post_hook() {
    echo "post:$1:$2" >>"$CALL_ORDER_FILE"
  }
  export CALL_ORDER_FILE="$BATS_TEST_TMPDIR/call_order"
  run create_session "my-session" "/my/dir"
  assert_success
  assert_output "my-session"
  assert_equal "$(sed -n '1p' "$CALL_ORDER_FILE")" "created"
  assert_equal "$(sed -n '2p' "$CALL_ORDER_FILE")" "post:my-session:/my/dir"
}

@test "create_session does not run post-create-session-hook when session is reused" {
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_EXISTS" ;;
    show-option)
      if [ "$3" = "@session-wizard-post-create-session-hook" ]; then
        echo "post_hook"
      fi
      ;;
    esac
  }
  function post_hook() {
    touch "$BATS_TEST_TMPDIR/post_ran"
  }
  run create_session "existing-session" "/my/dir"
  assert_success
  assert_output "existing-session"
  [ ! -e "$BATS_TEST_TMPDIR/post_ran" ]
}

@test "create_session continues when post-create-session-hook fails or prints" {
  # The session already exists at that point; its stdout must not leak into
  # the echoed session name, and a failure must not abort the attach.
  function tmux() {
    case "$1" in
    has-session) return "$SESSION_NOT_EXISTS" ;;
    new-session) ;;
    show-option)
      if [ "$3" = "@session-wizard-post-create-session-hook" ]; then
        echo "noisy_failing_post_hook"
      fi
      ;;
    esac
  }
  function noisy_failing_post_hook() {
    echo "layout noise"
    return 1
  }
  run create_session "my-session" "/my/dir"
  assert_success
  assert_output "my-session"
}

# --- kill_session_from_row ------------------------------------------------
@test "kill_session_from_row kills the session named in a picker row" {
  function tmux() { echo "tmux $*"; }
  run kill_session_from_row "alpha:"
  assert_output "tmux kill-session -t alpha"
}

@test "kill_session_from_row ignores directory rows" {
  function tmux() { echo "tmux $*"; }
  run kill_session_from_row "/opt/tool"
  assert_output ""
  run kill_session_from_row "~/projects/wizard"
  assert_output ""
}

@test "kill_session_from_row escapes a session literally named ~" {
  function tmux() { echo "tmux $*"; }
  run kill_session_from_row "~:"
  assert_output 'tmux kill-session -t \~'
}

# --- preview_row ------------------------------------------------------------
@test "preview_row shows pane contents for a session row" {
  function tmux() { echo "tmux $*"; }
  run preview_row "alpha: 3 window(s) (attached)"
  assert_output "tmux capture-pane -ep -t alpha"
}

@test "preview_row targets the window for a window row" {
  function tmux() { echo "tmux $*"; }
  run preview_row "alpha: vim(2) (attached)"
  assert_output "tmux capture-pane -ep -t alpha:2"
}

@test "preview_row shows the most recent pane lines that fit the preview window" {
  # Captures are pane-sized; the preview must show the tail (where the prompt
  # is), not the top, and drop the blank rows below the last output line.
  function tmux() {
    printf 'line1\nline2\nline3\nline4\n\n\n'
  }
  export FZF_PREVIEW_LINES=2
  run preview_row "alpha: 1 window(s)"
  assert_line --index 0 "line3"
  assert_line --index 1 "line4"
  assert_equal "${#lines[@]}" 2
}

@test "preview_row escapes a session literally named ~" {
  function tmux() { echo "tmux $*"; }
  run preview_row "~: 1 window(s)"
  assert_output 'tmux capture-pane -ep -t \~'
}

@test "preview_row lists a directory row, expanding ~" {
  function eza() { echo "eza $*"; }
  run preview_row "~/projects/wizard"
  assert_output "eza --tree --level=1 --color=always $HOME/projects/wizard"
}

# --- __fzf_version_at_least -----------------------------------------------
@test "__fzf_version_at_least compares fzf versions" {
  function fzf() { echo "0.73.1 (ce4bef75)"; }
  run __fzf_version_at_least 0 64
  assert_success
  run __fzf_version_at_least 0 80
  assert_failure
  run __fzf_version_at_least 1 0
  assert_failure
  function fzf() { echo "0.29"; }
  run __fzf_version_at_least 0 64
  assert_failure
  function fzf() { return 127; }
  run __fzf_version_at_least 0 64
  assert_failure
}

# --- build_session_list ---------------------------------------------------
# Stubs shared by the list tests. session_last_attached is a unix timestamp;
# it is EMPTY (or 0) for sessions that were never attached, e.g. ones restored
# by tmux-resurrect.
_stub_list_commands() {
  function tmux() {
    case "$1" in
    list-sessions)
      printf '%s\n' \
        "1700000000 beta: 2 window(s)" \
        "1800000000 alpha: 1 window(s) (attached)" \
        "0 resurrected-a: 1 window(s)" \
        " resurrected-b: 3 window(s)"
      ;;
    list-windows)
      printf '%s\n' \
        "1800000000 alpha: vim(1) (attached)" \
        "1700000000 beta: sh(2)"
      ;;
    display-message) echo "current" ;;
    esac
  }
  function zoxide() {
    [ "$1" = "query" ] && printf '%s\n' "$HOME/projects/wizard" "/opt/tool"
  }
  unset TMUX
}

@test "build_session_list orders sessions by last attach time, never-attached last" {
  _stub_list_commands
  # Force a locale whose collation ignores blanks: with plain 'sort -r' this
  # made never-attached sessions (empty timestamp) pile up at the top.
  export LC_ALL=en_US.UTF-8
  run build_session_list "off"
  assert_line --index 0 "alpha: 1 window(s) (attached)"
  assert_line --index 1 "beta: 2 window(s)"
  assert_line --index 2 "resurrected-a: 1 window(s)"
  assert_line --index 3 "resurrected-b: 3 window(s)"
}

@test "build_session_list appends zoxide results with ~ abbreviation" {
  _stub_list_commands
  run build_session_list "off"
  assert_line --index 4 "~/projects/wizard"
  assert_line --index 5 "/opt/tool"
}

@test "build_session_list filters out the current session when inside tmux" {
  _stub_list_commands
  function tmux() {
    case "$1" in
    list-sessions)
      printf '%s\n' \
        "1800000000 current: 1 window(s) (attached)" \
        "1700000000 other: 2 window(s)"
      ;;
    display-message) echo "current" ;;
    esac
  }
  export TMUX="fake,1234,0"
  run build_session_list "off"
  refute_line --partial "current:"
  assert_line --index 0 "other: 2 window(s)"
}

@test "build_session_list lists windows when select_window is on" {
  _stub_list_commands
  run build_session_list "on"
  assert_line --index 0 "alpha: vim(1) (attached)"
  assert_line --index 1 "beta: sh(2)"
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
