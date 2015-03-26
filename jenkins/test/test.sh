#!/bin/bash
set -e
SELFDIR=`dirname "$0"`
cd "$SELFDIR/../.."
source "./internal/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"
require_envvar DISTRIBUTION "$DISTRIBUTION"

CONCURRENCY=${CONCURRENCY:-8}

if [[ "$DEBUG_CONSOLE" = true ]]; then
	EXTRA_TEST_PARAMS=-D
else
	EXTRA_TEST_PARAMS=
fi

run ./build \
	-w "$WORKSPACE/work" \
	-c "$WORKSPACE/cache" \
	-o "$WORKSPACE/output" \
	-p "$WORKSPACE" \
	-j "$CONCURRENCY" \
	pkg:all
run ./test \
	-p "$WORKSPACE" \
	-d "$WORKSPACE/output" \
	-x "$DISTRIBUTION" \
	$EXTRA_TEST_PARAMS
