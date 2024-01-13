#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

declare -A default_config=(
    [key_bindings_session_wizard]="T"
    [height]=40
    [width]=80
    [keybind_split]=","
)

declare -A tmux_options=(
    [session_wizard]="@session-wizard"
    [session_wizard_height]="@session-wizard-height"
    [session_wizard_width]="@session-wizard-width"
    [keybind_split]="@session-wizard-keybind-split"
)

get_tmux_option() {
    local option=$1
    local default_value=$2
    tmux show-option -gqv "$option" || echo "$default_value"
}

get_config_value() {
    local key=$1
    get_tmux_option "${tmux_options[$key]}" "${default_config[$key]}"
}

set_session_wizard_options() {
    declare -A config_values

    config_values[key_bindings]=$(get_config_value "session_wizard")
    config_values[height]=$(get_config_value "session_wizard_height")
    config_values[width]=$(get_config_value "session_wizard_width")
    config_values[split]=$(get_config_value "keybind_split")

    IFS="${config_values[split]}" read -ra bindings <<< "${config_values[key_bindings]}"
    for key in "${bindings[@]}"; do
        tmux bind "$key" display-popup -w "${config_values[width]}"% -h "${config_values[height]}"% -E "$CURRENT_DIR/session-wizard.sh"
    done
}

main() {
    set_session_wizard_options
}

main
