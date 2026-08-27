# bats file_tags=unit
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
