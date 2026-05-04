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
    base='http://ports.ubuntu.com/ubuntu-ports'
elif grep -q "$distro" /usr/share/distro-info/debian.csv; then
    base='http://deb.debian.org/debian'
else
    echo "ERROR: $distro not found in /usr/share/distro-info/{debian,ubuntu}.csv" >&2
    exit 1
fi

version=$(curl "$base/dists/$distro/main/source/Sources.gz" | gunzip | grep -e '^Package: nginx$' -A 20 | grep -e '^Version:' | tr ' ' '-' | cut -d- -f2)

curl -sSLo "$2" "$base/pool/main/n/nginx/nginx_$version.orig.tar.gz"
