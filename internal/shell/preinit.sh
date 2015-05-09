#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

if [[ -e /work ]]; then
	rm -rf /work/*
else
	run mkdir /work
	run chown app: /work
fi
run setuser app "$ROOTDIR/internal/build/setup-environment-essentials.sh"
run cp "$ROOTDIR/internal/shell/sudoers.conf" /etc/sudoers.d/app
run chown root: /etc/sudoers.d/app
run chmod 400 /etc/sudoers.d/app
run ln -s "$ROOTDIR/internal/shell/initpbuilder.sh" /bin/initpbuilder

echo ---------------------------------------------------------------
echo
echo Welcome to the buildbox shell. To login to a pbuilder chroot,
echo run this:
echo
echo "  initpbuilder <CODENAME> <ARCH>"
echo "  pbuilder-dist <CODENAME> <ARCH> login"
echo

exec "$@"
