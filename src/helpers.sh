_normalize() {
  # Replace dots with underline, replace all "special" chars with dashes and convert everything to lowercase.
  cat | tr '_' - | tr ' ' - | tr ':' - | tr . _ | tr '[:upper:]' '[:lower:]'
}

# helper functions
get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value
  option_value=$(tmux show-option -gqv "$option")
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

session_name() {
  if [ "$1" = "--folder" ]; then
    shift
    basename "$@" | _normalize
  elif [ "$1" = "--full-path" ]; then
    shift
    echo "$@" | tr '/' '\n' | _normalize | tr '\n' '/' | sed 's/\/$//'
  elif [ "$1" = "--short-path" ]; then
    shift
    echo "$(echo "${@%/*}" | sed -r 's;/([^/]{,2})[^/]*;/\1;g' | _normalize)/$(basename "$@" | _normalize)"
  else
    echo "Wrong argument, you can use --last-normalized, --full or --shortened, got $1"
    return 1
  fi
}

fold_home() {
  local symbol="$1"
  shift
  # shellcheck disable=SC2001
  echo "$@" | sed "s;^$HOME;$symbol;"
}
