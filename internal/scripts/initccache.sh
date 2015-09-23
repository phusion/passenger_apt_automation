#!/bin/bash
# Initializes the pbuilder ccache directory with the proper permissions
# (owned by '1234', which is probably some internal pbuilder user)
# so that ccache doesn't create them with the wrong permissions (owned by root).

set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"
source "$ROOTDIR/internal/lib/distro_info.sh"

SUBDIRS="0 1 2 3 4 5 6 7 8 9 a b c d e f tmp"

for DISTRO in $DISTRIBUTIONS; do
	DISTRO=`to_distro_codename "$DISTRO"`
	for ARCH in $ARCHITECTURES; do
		dir="/cache/pbuilder/ccache/$DISTRO-$ARCH"
		verbose_run mkdir -p "$dir"
		verbose_run chown 1234:1234 "$dir"

		if $VERBOSE; then
			echo "+ Initializing $CCACHE_DIR"
		fi
		pushd "$dir" >/dev/null
		verbose_run mkdir -p $SUBDIRS
		verbose_run chown 1234:1234 $SUBDIRS
		for dir2 in 0 1 2 3 4 5 6 7 8 9 a b c d e f tmp; do
			pushd "$dir2" >/dev/null
			verbose_run mkdir -p $SUBDIRS
			verbose_run chown 1234:1234 $SUBDIRS
			popd >/dev/null
		done
		popd >/dev/null
	done
done
