#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux_option_session_wizard="@session-wizard"
default_key_bindings_session_wizard="T"
tmux_option_session_wizard_height="@session-wizard-height"
default_height=40
tmux_option_session_wizard_width="@session-wizard-width"
default_width=80

# Multiple bindings can be set. Default binding is "T".
set_session_wizard_options() {
  local key_bindings
  key_bindings=$(get_tmux_option "$tmux_option_session_wizard" "$default_key_bindings_session_wizard")
  local height
  height=$(get_tmux_option "$tmux_option_session_wizard_height" "$default_height")
  local width
  width=$(get_tmux_option "$tmux_option_session_wizard_width" "$default_width")
  local key
  for key in $(echo "${key_bindings}" | sed 's/ /\n/g'); do
    tmux bind "$key" display-popup -w "$width"% -h "$height"% -E "$CURRENT_DIR/session-wizard.sh"
  done

  # TODO: Is it worth to have a variable for this? For now it's used without a variables.
  local duplicate_key_bindings
  duplicate_key_bindings=$(get_tmux_option "@session-wizard-duplicate" "C-t")
  tmux bind "$duplicate_key_bindings" display-popup -w "$width"% -h "$height"% -E "$CURRENT_DIR/src/duplicate-session.sh --switch"
}

get_tmux_option() {
  local option=$1
  local default_value=$2
  local option_value
  option_value="$(tmux show-option -gqv "$option")"
  if [ "$option_value" = "" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

function main {
  set_session_wizard_options
}
main
