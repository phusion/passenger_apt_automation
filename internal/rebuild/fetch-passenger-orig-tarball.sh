#!/bin/bash
# Usage: fetch-passenger-orig-tarball.sh <OUTPUT> <DISTRO>
# Fetches the Passenger source packages from a Passenger source repo.
#
# Required environment variables:
#
#   PASSENGER_VERSION
#   PASSENGER_PACKAGE_NAME
#   PASSENGER_DEBIAN_NAME
#   PASSENGER_DEBIAN_EPOCH
#   PASSENGER_DEBIAN_VENDOR_VERSION
#   PASSENGER_DEBIAN_HOTFIX_VERSION

set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/internal/lib/library.sh"
source "$ROOTDIR/internal/lib/distro_info.sh"

require_args_exact 2 "$@"
require_envvar PASSENGER_VERSION "$PASSENGER_VERSION"
require_envvar PASSENGER_PACKAGE_NAME "$PASSENGER_PACKAGE_NAME"
require_envvar PASSENGER_DEBIAN_NAME "$PASSENGER_DEBIAN_NAME"
require_envvar PASSENGER_DEBIAN_EPOCH "$PASSENGER_DEBIAN_EPOCH"
require_envvar PASSENGER_DEBIAN_VENDOR_VERSION "$PASSENGER_DEBIAN_VENDOR_VERSION"
require_envvar PASSENGER_DEBIAN_HOTFIX_VERSION "$PASSENGER_DEBIAN_HOTFIX_VERSION"
distro="$2"

header "Fetching Passenger official tarball"
export workdir=/work
export list_prefix="$workdir/lists-$distro"
export list_path="$workdir/passenger.$distro.list"
export netrc_path="$workdir/auth.conf"
export nginx_package="libnginx-mod-http-${PASSENGER_DEBIAN_NAME}"
export trusted_prefix="$workdir/trusted.gpg.d"

mkdir -p "$trusted_prefix"
mkdir -p "$list_prefix/partial"
chown -R "$USER" "$list_prefix"
mkdir -p "$workdir/sources-${distro}"
pushd "$(mktemp -d -p "$workdir/sources-${distro}")"

if [ "$PASSENGER_DEBIAN_NAME" != "passenger-enterprise" ]; then
    echo "deb-src https://oss-binaries.phusionpassenger.com/apt/passenger $distro main" > "$list_path"
    echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger $distro main" >> "$list_path"
else
    if [ -z "$PASSENGER_ENTERPRISE_DOWNLOAD_TOKEN" ]; then
	echo "Please set PASSENGER_ENTERPRISE_DOWNLOAD_TOKEN env var when rebuilding enterprise packages" >&2
	exit 1
    fi
    echo "machine www.phusionpassenger.com/enterprise_apt login download password $PASSENGER_ENTERPRISE_DOWNLOAD_TOKEN" > "$netrc_path"
    echo "deb-src https://www.phusionpassenger.com/enterprise_apt $distro main" > "$list_path"
    echo "deb https://www.phusionpassenger.com/enterprise_apt $distro main" >> "$list_path"
fi

curl https://oss-binaries.phusionpassenger.com/auto-software-signing-gpg-key-2025.txt | gpg --dearmor > "$trusted_prefix/phusion.gpg"

overrides=(
 -o "Dir::Etc::netrc=$netrc_path"
 -o "Dir::Etc::TrustedParts=$trusted_prefix"
 -o "Dir::Etc::sourcelist=$list_path"
 -o "Dir::State::Lists=$list_prefix"
 -o "Dir::Cache=$workdir/cache"
 -o "APT::Default-Release=n=$distro"
)

run apt "${overrides[@]}" update

NGINX_BASE="${PASSENGER_DEBIAN_EPOCH}:${PASSENGER_VERSION}-${PASSENGER_DEBIAN_VENDOR_VERSION}~${distro}${PASSENGER_DEBIAN_HOTFIX_VERSION}"
# Get latest version that matches the base version but allows rebuilds so the rebuild # gets incremented
NGINX_VERSION="$(apt-cache "${overrides[@]}" madison "$nginx_package" | awk -F' \\| ' '{print $2}' | grep -e "$NGINX_BASE" | head -1)"

run apt "${overrides[@]}" source --download-only "$nginx_package"="$NGINX_VERSION"

echo "+ Putting sources in place"
mv ${PASSENGER_DEBIAN_NAME}_${PASSENGER_VERSION}-*${distro}*.debian.tar.xz "$1"
mv ${PASSENGER_DEBIAN_NAME}_${PASSENGER_VERSION}.orig.tar.gz "$1"
