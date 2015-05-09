#!/bin/bash
# Usage: setup-environment.sh <DISTRO> <ARCHITECTURE>
# Setup the build environment for a specific distribution and architecture.

# Note: this script must be idempotent because the user may call it multiple
# times from the shell, through initpbuilder.

set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

require_args_exact 2 "$@"
DISTRO="$1"
ARCH="$2"

if [[ $ARCH == amd64 ]]; then
	BASE_TGZ="$DISTRO-base.tgz"
else
	BASE_TGZ="$DISTRO-$ARCH-base.tgz"
fi

if [[ ! -e /cache/base-$DISTRO-$ARCH.tgz ]]; then
	run pbuilder-dist $DISTRO $ARCH create --updates-only
	run mv ~/pbuilder/$BASE_TGZ /cache/base-$DISTRO-$ARCH.tgz
fi
if [[ ! -e ~/pbuilder/$BASE_TGZ ]]; then
	run ln -s /cache/base-$DISTRO-$ARCH.tgz ~/pbuilder/$BASE_TGZ
fi
