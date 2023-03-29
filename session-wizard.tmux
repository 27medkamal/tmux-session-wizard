#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

default_key_bindings_session_wizard="T"
tmux_option_session_wizard="@session-wizard"
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
    for key in "${key_bindings[@]}"; do
        tmux bind "$key" display-popup -w "$width"% -h "$height"% -E "$CURRENT_DIR/session-wizard.sh"
    done
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
