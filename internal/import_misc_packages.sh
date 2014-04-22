#!/bin/bash
set -e

source lib/bashlib
load_general_config

header "Preparing build directory"
export PKG_DIR=/tmp/passenger_apt_build
run rm -rf $PKG_DIR
run mkdir -p $PKG_DIR

header "Clearing previous build results"
run rm -rf ~/pbuilder/*_result/*

header "Cloning repositories"
rm -rf misc_packages
mkdir -p misc_packages
if $build_daemon_controller; then
	git clone git://github.com/FooBarWidget/daemon_controller.git misc_packages/daemon_controller
fi
if $build_crash_watch; then
	git clone git://github.com/FooBarWidget/crash-watch.git misc_packages/crash-watch
fi

if $build_daemon_controller; then
	header "Building daemon_controller"
	cd $BASE_DIR/misc_packages/daemon_controller
	echo "In $BASE_DIR/misc_packages/daemon_controller:"
	run rake debian:source_packages
	for DIST in $DEBIAN_DISTROS; do
		run pbuilder-dist $DIST i386 build $PKG_DIR/ruby-daemon-controller_*$DIST*.dsc
	done
fi

if $build_crash_watch; then
	header "Building crash-watch"
	cd $BASE_DIR/misc_packages/crash-watch
	echo "In $BASE_DIR/misc_packages/crash-watch:"
	run rake debian:source_packages
	for DIST in $DEBIAN_DISTROS; do
		run pbuilder-dist $DIST i386 build $PKG_DIR/crash-watch_*$DIST*.dsc
	done
fi

header "Signing packages"
debsign -k$SIGNING_KEY $PKG_DIR/*.changes

header "Importing built packages into APT repositories"
for REPO in passenger.apt passenger-enterprise.apt; do
	rm -rf $REPO.tmp $REPO.old
	cp -dpR $REPO $REPO.tmp
	pushd $REPO.tmp

	for DIST in $DEBIAN_DISTROS; do
		reprepro --keepunusednewfiles -Vb . includedeb $DIST $HOME/pbuilder/$DIST-i386_result/*.deb
		for F in $HOME/pbuilder/$DIST-i386_result/*.dsc; do
			reprepro --keepunusednewfiles -Vb . includedsc $DIST $F
		done
	done

	popd
	mv $REPO $REPO.old
	mv $REPO.tmp $REPO
	rm -rf $REPO.old
done

./sign_repo passenger.apt
./sign_repo passenger-enterprise.apt
