# bats file_tags=integration
setup() {
  load ./lib/bats.bash
  _common_setup
}

teardown() {
  _common_teardown
}

@test "pre-create-session-hook modifies the session name" {
  local hook_script="$TEST_DIR/hook.sh"
  cat >"$hook_script" <<'HOOK'
#!/bin/bash
echo "custom-session"
echo "$2"
HOOK
  chmod +x "$hook_script"
  echo "set -g @session-wizard-pre-create-session-hook '$hook_script'" >>"$TMUX_CONFIG"

  mkdir -p "$TEST_DIR/dir"
  t "$TEST_DIR/dir"
  assert_tmux_session_attached "custom-session"
  assert_tmux_session_exists "custom-session"
}

@test "pre-create-session-hook modifies the target directory" {
  local alt_dir="$TEST_DIR/alt-dir"
  mkdir -p "$alt_dir"
  mkdir -p "$TEST_DIR/dir"

  local hook_script="$TEST_DIR/hook.sh"
  cat >"$hook_script" <<HOOK
#!/bin/bash
echo "\$1"
echo "$alt_dir"
HOOK
  chmod +x "$hook_script"
  echo "set -g @session-wizard-pre-create-session-hook '$hook_script'" >>"$TMUX_CONFIG"

  t "$TEST_DIR/dir"
  assert_tmux_session_attached "dir"
  assert_tmux_sessions_number 1
  local session_dir
  session_dir=$(tmux display-message -t "dir" -p "#{session_path}")
  assert_equal "$session_dir" "$alt_dir"
}

@test "pre-create-session-hook with no output keeps original values" {
  local hook_script="$TEST_DIR/hook.sh"
  cat >"$hook_script" <<'HOOK'
#!/bin/bash
# outputs nothing
HOOK
  chmod +x "$hook_script"
  echo "set -g @session-wizard-pre-create-session-hook '$hook_script'" >>"$TMUX_CONFIG"

  mkdir -p "$TEST_DIR/dir"
  t "$TEST_DIR/dir"
  assert_tmux_session_attached "dir"
  assert_tmux_session_exists "dir"
}

@test "post-create-session-hook runs on creation only, not on reuse" {
  local hook_script="$TEST_DIR/post-hook.sh"
  cat >"$hook_script" <<'HOOK'
#!/bin/bash
tmux new-window -t "$1" -n scratch
HOOK
  chmod +x "$hook_script"
  echo "set -g @session-wizard-post-create-session-hook '$hook_script'" >>"$TMUX_CONFIG"

  mkdir -p "$TEST_DIR/dir"
  t "$TEST_DIR/dir"
  assert_tmux_session_attached "dir"
  run tmux list-windows -t "dir" -F "#{window_name}"
  assert_line "scratch"
  # Second run reuses the session: the hook must not add another window
  t "$TEST_DIR/dir"
  windows=$(tmux list-windows -t "dir" | wc -l | tr -d '[:space:]')
  assert_equal "$windows" "2"
}

@test "failing post-create-session-hook still creates and attaches" {
  local hook_script="$TEST_DIR/post-hook.sh"
  cat >"$hook_script" <<'HOOK'
#!/bin/bash
exit 1
HOOK
  chmod +x "$hook_script"
  echo "set -g @session-wizard-post-create-session-hook '$hook_script'" >>"$TMUX_CONFIG"

  mkdir -p "$TEST_DIR/dir"
  run t "$TEST_DIR/dir"
  assert_success
  assert_tmux_session_attached "dir"
  assert_tmux_session_exists "dir"
}

@test "failing pre-create-session-hook aborts: no session created, nothing attached" {
  local hook_script="$TEST_DIR/hook.sh"
  cat >"$hook_script" <<'HOOK'
#!/bin/bash
exit 1
HOOK
  chmod +x "$hook_script"
  echo "set -g @session-wizard-pre-create-session-hook '$hook_script'" >>"$TMUX_CONFIG"

  mkdir -p "$TEST_DIR/dir"
  run t "$TEST_DIR/dir"
  assert_failure
  [ ! -e "$BATS_TEST_TMPDIR/attached_session" ]
  run tmux has-session -t "dir"
  assert_failure
}
