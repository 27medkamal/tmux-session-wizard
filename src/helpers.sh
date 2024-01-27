
_normalize() {
  # Replace dots with underline, replace all "special" chars with dashes and all convert to lowercase.
  cat | tr '_' - |tr ' ' - | tr ':' - | tr . _ | tr '[:upper:]' '[:lower:]'
}

TEST_PATH="/MOO/.foo BAR/.moo FOO_bar.baz"

session_name() {
  if [ "$1" = "--folder" ]; then
    shift
    basename "$@" | _normalize
  elif [ "$1" = "--full-path" ]; then
    shift
    echo "$@" | tr '/' '\n'| _normalize | tr '\n' '/' | sed 's/\/$//'
  elif [ "$1" = "--short-path" ]; then
    shift
    FOLDER=$(echo "$@" | tr '/' '\n' | tail -n 1 | _normalize)
    PREFIX=$(echo "$@" | tr '/' '\n' | head -n -1 |  sed -r 's|/([^/]{,2})[^/]*|/\1|mpg' | _normalize |  tr '\n' '/' | sed 's/\/$//')
    echo "$@" | sed -r 's|/([^/]{,2})[^/]*|/\1|g' | _normalize

  else
    echo "Wrong argument, you can use --last-normalized, --full or --shortened, got $1"
    return 1
  fi
}
