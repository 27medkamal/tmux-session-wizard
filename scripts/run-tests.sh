#!/usr/bin/env bash
# For debugging purposes
# set -x

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
IMAGE="tmux-session-wizard:dev"

while getopts "crwh" opt; do
  case $opt in
    c) CONTAINER=true
      ;;
    r) REBUILD=true
      ;;
    w) WATCH=true
      ;;
    h)
      echo "Usage: run-tests.sh"
      echo "Run tests for the project"
      echo "  -c  Run tests inside a container (image: ${IMAGE})"
      echo "  -r  Rebuild the container image before running tests, set also -c opiton by default"
      echo "  -w  Watch changes in project and then run tests"
      echo "  -h  Display this help message"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Basic command to run tests
CMD=(bats "$PROJECT_ROOT/tests")

# Run tests in watch mode
if [ "$WATCH" = true ]; then
  CMD=(watchexec "${CMD[@]}")
fi

# Run tests inside a container
if [ "$CONTAINER" = true ] || [ "$REBUILD" = true ]; then
  CMD=(docker run --rm -it --user "$(id -u):$(id -g)" -v "$PROJECT_ROOT:$PROJECT_ROOT" -w "$PROJECT_ROOT" "$IMAGE" "${CMD[@]}")
  IS_IMAGE_EXISTS=$(docker images -q ${IMAGE})
fi

if [ -z "$IS_IMAGE_EXISTS" ] &&  [ "$CONTAINER" = true ] || [ "$REBUILD" = true ] ; then
  docker build -t ${IMAGE} -f "$PROJECT_ROOT/Dockerfile" "$PROJECT_ROOT"
fi

echo "----------------------------------------------------------------------------"
echo "Running tests with command: ${CMD[*]}"
echo "----------------------------------------------------------------------------"
"${CMD[@]}"


