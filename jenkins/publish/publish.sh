#!/bin/bash
set -e

SELFDIR="`dirname \"$0\"`"
cd "$SELFDIR/../.."
SELFDIR="`pwd`"
source "./internal/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"
require_envvar REPOSITORY "$REPOSITORY"
require_envvar HOME "$HOME"

PASSENGER_ROOT="${PASSENGER_ROOT:-$WORKSPACE}"
CONCURRENCY=${CONCURRENCY:-8}

if [[ "$REPOSITORY" =~ -testing$ ]]; then
	YANK=-Y
else
	YANK=
fi
if tty -s; then
	TTY_ARGS="-t -i"
else
	TTY_ARGS=
fi

if [[ ! -e ~/.packagecloud_token ]]; then
	echo "ERROR: ~/.packagecloud_token required."
	exit 1
fi
if [[ ! -e ~/.oss_packagecloud_proxy_admin_password ]]; then
	echo "ERROR: ~/.oss_packagecloud_proxy_admin_password required."
	exit 1
fi
if [[ ! -e ~/.enterprise_packagecloud_proxy_admin_password ]]; then
	echo "ERROR: ~/.enterprise_packagecloud_proxy_admin_password required."
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
	-c ~/.packagecloud_token \
	-r "$REPOSITORY" \
	-l "$WORKSPACE/publish-log" \
	$YANK \
	publish:all

header "Clearing proxy caches"
exec docker run $TTY_ARGS --rm \
	-v "$SELFDIR:/system:ro" \
	-v "$HOME/.oss_packagecloud_proxy_admin_password:/oss_packagecloud_proxy_admin_password.txt:ro" \
	-v "$HOME/.enterprise_packagecloud_proxy_admin_password:/enterprise_packagecloud_proxy_admin_password.txt:ro" \
	-e "APP_UID=`/usr/bin/id -u`" \
	-e "APP_GID=`/usr/bin/id -g`" \
	-e "LC_CTYPE=en_US.UTF-8" \
	phusion/passenger_apt_automation_buildbox \
	/sbin/my_init --quiet --skip-runit --skip-startup-files -- \
	/system/internal/scripts/inituidgid.sh \
	/sbin/setuser app \
	/system/jenkins/publish/clear_caches.rb
