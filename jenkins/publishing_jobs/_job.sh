#!/bin/bash
set -e

SELFDIR=`dirname "$0"`
cd "$SELFDIR/../.."
source "./internal/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"
require_envvar REPOSITORY "$REPOSITORY"

CONCURRENCY=${CONCURRENCY:-8}

run ./build \
	-w "$WORKSPACE/work" \
	-c "$WORKSPACE/cache" \
	-o "$WORKSPACE/output" \
	-p "$WORKSPACE" \
	-j "$CONCURRENCY" \
	pkg:all
run ./publish \
	-d "$WORKSPACE/output" \
	-c ~/.packagecloud_token \
	-r "$REPOSITORY" \
	-l "$WORKSPACE/publish-log" \
	publish:all
