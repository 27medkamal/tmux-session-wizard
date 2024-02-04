#
# Duplicate a session and crete group with it
#
# Usage: duplicate-session [-g|--group-with-last-active] [-s|--switch]
# -a, --group-with-last-active: Group with last active session, work also if you
#         are not in Tmux (default: false)
# -s, --switch: Switch to the new created session (default: false)
#
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

main() {
  local session new_session

  local group_with_last_active=false
  local switch=false
  while [ "$#" -gt 0 ]; do
    case "$1" in
    -a | --group-with-last-active)
      shift
      group_with_last_active=true
      ;;
    -s | --switch)
      shift
      switch=true
      ;;
    *)
      echo "Unknown argument: $1"
      return 1
      ;;
    esac
  done

  if [ "$group_with_last_active" = "true" ]; then
    session=$(tmux display-message -p '#S')
  else
    # shellcheck disable=SC2119
    session=$(session_list | show_fzf | cut -d':' -f1)
  fi

  local session_folder
  session_folder=$(tmux display-message -p -t "$session" "#{session_path}")
  new_session=$(tmux new-session -P -d -c "$session_folder" -t "$session")
  if [ "$switch" = "true" ]; then
    switch_client "$new_session"
  fi
}

main "$@"
