#!/bin/bash
# Usage: test.sh
# This script is from the "Passenger Debian packaging test" Jenkins job. It builds
# packages for a specific distribution and runs tests on these packages.
#
# Required environment variables:
#
#   WORKSPACE
#   DISTRIBUTION
#
# Optional environment variables:
#
#   PASSENGER_ROOT (defaults to $WORKSPACE)
#   ENTERPRISE
#
# Sample invocation in Vagrant dev environment:
#
#   env WORKSPACE=$HOME DISTRIBUTION=ubuntu10.04 PASSENGER_ROOT=/passenger ./jenkins/test/test.sh

set -e
SELFDIR=`dirname "$0"`
cd "$SELFDIR/../.."
source "./internal/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"
require_envvar DISTRIBUTION "$DISTRIBUTION"

PASSENGER_ROOT="${PASSENGER_ROOT:-$WORKSPACE}"
CONCURRENCY=${CONCURRENCY:-4}

if [[ "$DISTRIBUTION" = ubuntu14.04 ]]; then
	CODENAME=trusty
elif [[ "$DISTRIBUTION" = ubuntu12.04 ]]; then
	CODENAME=precise
elif [[ "$DISTRIBUTION" = ubuntu10.04 ]]; then
	CODENAME=lucid
elif [[ "$DISTRIBUTION" = debian7 ]]; then
	CODENAME=wheezy
elif [[ "$DISTRIBUTION" = debian6 ]]; then
	CODENAME=squeeze
else
	echo "ERROR: unknown distribution name."
	exit 1
fi
if [[ "$DEBUG_CONSOLE" = true ]]; then
	EXTRA_TEST_PARAMS=-D
else
	EXTRA_TEST_PARAMS=
fi
if [[ "$ENTERPRISE" = 1 ]]; then
	EXTRA_TEST_PARAMS="$EXTRA_TEST_PARAMS -e $HOME/passenger-enterprise-license"
fi

# Sleep for a random amount of time in order to work around Docker/AUFS bugs
# that may be triggered if multiple containers are shut down at the same time.
echo 'import random, time; time.sleep(random.random() * 4)' | python

run ./build \
	-w "$WORKSPACE/work" \
	-c "$WORKSPACE/cache" \
	-o "$WORKSPACE/output" \
	-p "$PASSENGER_ROOT" \
	-d "$CODENAME" \
	-a amd64 \
	-j "$CONCURRENCY" \
	-R \
	-O \
	pkg:all
run ./test \
	-p "$PASSENGER_ROOT" \
	-d "$WORKSPACE/output/$CODENAME" \
	-c "$WORKSPACE/cache" \
	-x "$DISTRIBUTION" \
	-j \
	$EXTRA_TEST_PARAMS
