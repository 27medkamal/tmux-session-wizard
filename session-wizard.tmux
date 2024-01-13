#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

declare -A default_config
declare -A tmux_options

default_config=(
    [key_bindings_session_wizard]="T"
    [height]=40
    [width]=80
    [keybind_split]=","
)

tmux_options=(
    [session_wizard]="@session-wizard"
    [session_wizard_height]="@session-wizard-height"
    [session_wizard_width]="@session-wizard-width"
    [keybind_split]="@session-wizard-keybind-split"
)

# # Multiple bindings can be set. Default binding is "T".
set_session_wizard_options() {
    local key_bindings
    key_bindings=$(get_tmux_option "${tmux_options[session_wizard]}" "${default_config[key_bindings_session_wizard]}")
    local height
    height=$(get_tmux_option "${tmux_options[session_wizard_height]}" "${default_config[height]}")
    local width
    width=$(get_tmux_option "${tmux_options[session_wizard_width]}" "${default_config[width]}")
    local split
    split=$(get_tmux_option "${tmux_options[keybind_split]}" "${default_config[keybind_split]}")

    local key
    IFS="$split" read -ra bindings <<< "$key_bindings"
    for key in "${bindings[@]}"; do
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
