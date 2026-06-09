#!/bin/bash
# Usage: download-nginx-distro-tarball.sh <DISTRO> <OUTPUT>
# Downloads the Nginx source tarball.

set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

require_args_exact 2 "$@"

distro="$1"

if grep -q "$distro" /usr/share/distro-info/ubuntu.csv; then
    prefix="deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy"
    suffixes=(" main restricted" "-updates main restricted" " universe" "-updates universe" " multiverse" "-updates multiverse" "-backports main restricted universe multiverse" "-security main restricted" "-security universe" "-security multiverse")
elif grep -q "$distro" /usr/share/distro-info/debian.csv; then
    prefix="deb-src http://deb.debian.org/debian"
    suffixes=(" bullseye main" "-security bullseye-security main" " bullseye-updates main")
else
    echo "ERROR: $distro not found in /usr/share/distro-info/{debian,ubuntu}.csv" >&2
    exit 1
fi
pushd "$(mktemp -d -p /work)"
mkdir -p "/work/lists/partial"
chown -R "$USER" "/work/lists"
printf "${prefix}%s\n" "${suffixes[@]}" > "/work/sources.list"
apt -o "Dir::Etc::sourcelist=/work/sources.list" -o "Dir::State::Lists=/work/lists" -o "Dir::Cache=/work/cache" -o "APT::Default-Release=n=$distro" update
apt -o "Dir::Etc::sourcelist=/work/sources.list" -o "Dir::State::Lists=/work/lists" -o "Dir::Cache=/work/cache" -o "APT::Default-Release=n=$distro" source nginx
mv ./nginx-* "./nginx-distro"
tar -cf "$2" ./nginx-distro
