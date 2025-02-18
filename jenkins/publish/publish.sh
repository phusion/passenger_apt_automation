#!/bin/bash
set -e

SELFDIR=$(dirname "$0")
cd "$SELFDIR/../.."
SELFDIR=$(pwd)
# shellcheck source=../../internal/lib/library.sh
source "./internal/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"
require_envvar REPOSITORY "$REPOSITORY"
require_envvar HOME "$HOME"

PASSENGER_ROOT="${PASSENGER_ROOT:-$WORKSPACE}"
CONCURRENCY=${CONCURRENCY:-8}

if [[ "$REPOSITORY" =~ \.staging$ ]]; then
	YANK=-Y
	REPO_SERVER_API_USERNAME_FILE="$HOME/.repo_server_api_username_staging"
	REPO_SERVER_API_TOKEN_FILE="$HOME/.repo_server_api_token_staging"
else
	REPO_SERVER_API_USERNAME_FILE="$HOME/.repo_server_api_username_production"
	REPO_SERVER_API_TOKEN_FILE="$HOME/.repo_server_api_token_production"
fi
if tty -s; then
	TTY_ARGS="-t -i"
else
	TTY_ARGS=
fi

if [[ ! -e "$REPO_SERVER_API_USERNAME_FILE" ]]; then
	echo "ERROR: $REPO_SERVER_API_USERNAME_FILE required."
	exit 1
fi
if [[ ! -e "$REPO_SERVER_API_TOKEN_FILE" ]]; then
	echo "ERROR: $REPO_SERVER_API_TOKEN_FILE required."
	exit 1
fi

run ./build \
	-w "$WORKSPACE/work" \
	-c "$WORKSPACE/cache" \
	-o "$WORKSPACE/output" \
	-p "$PASSENGER_ROOT" \
	-j "$CONCURRENCY" \
	-R \
	-O \
	pkg:all
run ./publish \
	-d "$WORKSPACE/output" \
	-u "$(cat "$REPO_SERVER_API_USERNAME_FILE")" \
	-c "$REPO_SERVER_API_TOKEN_FILE" \
	-r "$REPOSITORY" \
	-l "$WORKSPACE/publish-log" \
	$YANK \
	publish:all
