#!/bin/bash
set -e

BASE_DIR=`dirname "$0"`
BASE_DIR=`cd "$BASE_DIR/.." && pwd`
source lib/bashlib
load_general_config

function cleanup()
{
	if [[ "$WORK_DIR" != "" ]]; then
		rm -rf "$WORK_DIR"
	fi
}


##### Initialization #####

FIRST_ARCH=`echo "$DEBIAN_ARCHS" | awk '{ print $1 }'`

header "Preparing work directory"
export WORK_DIR=`mktemp -d /tmp/passenger_apt_automation.XXXXXXX`
export PKG_DIR="$WORK_DIR/pkg"
export PBUILDFOLDER="$WORK_DIR/pbuilder"
mkdir -p "$PKG_DIR"
mkdir -p "$PBUILDFOLDER"
reset_fake_pbuild_folder "$PBUILDFOLDER"

header "Cloning repositories"
rm -rf /var/cache/passenger_apt_automation/misc_packages
mkdir -p /var/cache/passenger_apt_automation/misc_packages


##### Build source packages #####

if $build_daemon_controller; then
	header "Building daemon_controller source packages"
	run git clone git://github.com/FooBarWidget/daemon_controller.git /var/cache/passenger_apt_automation/misc_packages/daemon_controller
	pushd /var/cache/passenger_apt_automation/misc_packages/daemon_controller >/dev/null
	echo "In /var/cache/passenger_apt_automation/misc_packages/daemon_controller:"
	run rake debian:source_packages
	popd >/dev/null
fi

if $build_crash_watch; then
	header "Building crash-watch source packages"
	run git clone git://github.com/FooBarWidget/crash-watch.git /var/cache/passenger_apt_automation/misc_packages/crash-watch
	pushd /var/cache/passenger_apt_automation/misc_packages/crash-watch >/dev/null
	echo "In /var/cache/passenger_apt_automation/misc_packages/crash-watch:"
	run rake debian:source_packages
	popd >/dev/null
fi


##### Build binary packages #####

if $build_daemon_controller; then
	header "Building daemon_controller binary packages"
	for DIST in $DEBIAN_DISTROS; do
		run pbuilder-dist $DIST $FIRST_ARCH build $PKG_DIR/ruby-daemon-controller_*$DIST*.dsc
	done
fi
if $build_crash_watch; then
	header "Building crash-watch binary packages"
	for DIST in $DEBIAN_DISTROS; do
		run pbuilder-dist $DIST $FIRST_ARCH build $PKG_DIR/crash-watch_*$DIST*.dsc
	done
fi


##### Finalization and import #####

RELEASE_DIRS=()

for PROJECT_NAME in "$@"; do
	header "Importing packages into APT repository $PROJECT_NAME"
	PROJECT_APT_REPO_DIR="$APT_REPO_DIR/$PROJECT_NAME.apt"
	RELEASE_DIR=`bash "$BASE_DIR/internal/new_apt_repo_release.sh" "$PROJECT_NAME" "$PROJECT_APT_REPO_DIR"`
	RELEASE_DIRS+=("$RELEASE_DIR")
	echo "# Created new release dir: $RELEASE_DIR"
	bash "$BASE_DIR/internal/import_packages.sh" "$RELEASE_DIR" "$PBUILDFOLDER" "$DEBIAN_DISTROS" "$DEBIAN_ARCHS"
done

header "Committing transaction:"
for RELEASE_DIR in "${RELEASE_DIRS[@]}"; do
	echo " --> $RELEASE_DIR"
	bash "$BASE_DIR/internal/commit_apt_repo_release.sh" "$RELEASE_DIR"
done
