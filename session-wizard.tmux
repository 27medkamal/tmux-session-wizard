#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

default_key_bindings_session_wizard="T"
tmux_option_session_wizard="@session-wizard"

# Multiple bindings can be set. Default binding is "T".
set_session_wizard_bindings() {
	local key_bindings=$(get_tmux_option "$tmux_option_session_wizard" "$default_key_bindings_session_wizard")
	local key
	for key in $key_bindings; do
		tmux bind "$key" display-popup -w 80% -E "$CURRENT_DIR/session-wizard.sh"
	done
}

get_tmux_option() {
	local option=$1
	local default_value=$2
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

function main {
  set_session_wizard_bindings
}
main
