#!/bin/bash
# Usage: build-passenger-orig-tarball.sh <OUTPUT>
# Builds the Passenger orig tarball from a Passenger source directory.
#
# Required environment variables:
#
#   PASSENGER_VERSION
#   PASSENGER_PACKAGE_NAME
#   PASSENGER_DEBIAN_NAME
#   NGINX_DEBIAN_NAME
#   NGINX_VERSION

set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

require_args_exact 1 "$@"
require_envvar PASSENGER_VERSION "$PASSENGER_VERSION"
require_envvar PASSENGER_PACKAGE_NAME "$PASSENGER_PACKAGE_NAME"
require_envvar PASSENGER_DEBIAN_NAME "$PASSENGER_DEBIAN_NAME"
require_envvar NGINX_DEBIAN_NAME "$NGINX_DEBIAN_NAME"
require_envvar NGINX_VERSION "$NGINX_VERSION"


header "Creating Passenger official tarball"
# /passenger is mounted read-only, but 'rake' may have to create files, e.g.
# to generate documentation files. So we copy it to a temporary directory
# which is writable.
run rm -rf /tmp/passenger
if [[ -e /passenger/.git ]]; then
	run mkdir /tmp/passenger
	echo "+ cd /passenger"
	cd /passenger
	echo "+ Git copying to /tmp/passenger"
	(
		set -o pipefail
		git archive --format=tar HEAD | tar -C /tmp/passenger -x
		submodules=`git submodule status | awk '{ print $2 }'`
		for submodule in $submodules; do
			echo "+ Git copying submodule $submodule"
			pushd $submodule >/dev/null
			mkdir -p /tmp/passenger/$submodule
			git archive --format=tar HEAD | tar -C /tmp/passenger/$submodule -x
			popd >/dev/null
		done
	)
	if [[ $? != 0 ]]; then
		exit 1
	fi
else
	run cp -dpR /passenger /tmp/passenger
fi
echo "+ cd /tmp/passenger"
cd /tmp/passenger
run mkdir ~/pkg
run rake package:set_official package:tarball CACHING=false PKG_DIR=~/pkg

header "Extracting Passenger tarball"
echo "+ cd ~/pkg"
cd ~/pkg
run tar xzf $PASSENGER_PACKAGE_NAME-$PASSENGER_VERSION.tar.gz
run rm -f $PASSENGER_PACKAGE_NAME-$PASSENGER_VERSION.tar.gz

header "Extracting Nginx into Passenger directory"
echo "+ cd $PASSENGER_PACKAGE_NAME-$PASSENGER_VERSION"
cd $PASSENGER_PACKAGE_NAME-$PASSENGER_VERSION
run tar xzf /work/${NGINX_DEBIAN_NAME}_$NGINX_VERSION.orig.tar.gz

header "Packaging up"
cd ..
echo "+ Normalizing timestamps"
find $PASSENGER_PACKAGE_NAME-$PASSENGER_VERSION -print0 | xargs -0 touch -d '2013-10-27 00:00:00 UTC'
echo "+ Creating final orig tarball"
tar -c $PASSENGER_PACKAGE_NAME-$PASSENGER_VERSION | gzip --no-name --best > "$1"
run rm -rf ~/pkg
