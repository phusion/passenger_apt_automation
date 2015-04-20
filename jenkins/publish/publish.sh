#!/bin/bash
set -e

SELFDIR=`dirname "$0"`
cd "$SELFDIR/../.."
source "./internal/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"
require_envvar REPOSITORY "$REPOSITORY"

PASSENGER_ROOT="${PASSENGER_ROOT:-$WORKSPACE}"
CONCURRENCY=${CONCURRENCY:-8}

if [[ "$REPOSITORY" =~ -testing$ ]]; then
	YANK=-y
else
	YANK=
fi

if [[ ! -e ~/.packagecloud_token ]]; then
	echo "ERROR: ~/.packagecloud_token required."
	exit 1
fi
if [[ ! -e ~/.oss_packagecloud_proxy_admin_password ]]; then
	echo "ERROR: ~/.oss_packagecloud_proxy_admin_password required."
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

echo "+ https://oss-binaries.phusionpassenger.com/"
ADMIN_PASSWORD=`cat ~/.oss_packagecloud_proxy_admin_password`
curl -X POST -K - --cacert "$SELFDIR/jenkins/publish/oss-binaries.phusionpassenger.com.crt" \
	https://oss-binaries.phusionpassenger.com/packagecloud_proxy/clear_cache \
	<<<"user = \"admin:$ADMIN_PASSWORD\""
echo
