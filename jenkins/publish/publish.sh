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

header "Clearing proxy caches"
exec docker run $TTY_ARGS --rm \
	-v "$SELFDIR:/system:ro" \
	-e "REPO_SERVER_API_USERNAME=$(cat "$REPO_SERVER_API_USERNAME_FILE")" \
	-v "$REPO_SERVER_API_TOKEN_FILE:/repo_server_api_token.txt:ro" \
	-e "REPOSITORY=$REPOSITORY" \
	-e "APP_UID=$(/usr/bin/id -u)" \
	-e "APP_GID=$(/usr/bin/id -g)" \
	-e "LC_CTYPE=en_US.UTF-8" \
	phusion/passenger_apt_automation_buildbox \
	/sbin/my_init --quiet --skip-runit --skip-startup-files -- \
	/system/internal/scripts/inituidgid.sh \
	/sbin/setuser app \
	/system/jenkins/publish/clear_caches.rb
