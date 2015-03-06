#!/bin/bash
# Usage: setup-environment-essentials.sh
# Setup things that are needed before build environment initialization can begin.

set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

run mkdir -p /work/pkg
run ln -s /work/pkg ~/pbuilder
run mkdir -p /var/cache/pbuilder/build
run mkdir -p /var/cache/pbuilder/ccache
run mkdir -p /var/cache/pbuilder/aptcache
run ln -s /var/cache/pbuilder/aptcache ~/pbuilder/aptcache
