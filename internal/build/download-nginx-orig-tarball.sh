#!/bin/bash
# Usage: download-nginx-orig-tarball.sh <NGINX_VERSION> <OUTPUT>
# Downloads the Nginx source tarball.
#
# Required environment variables:
#
#   NGINX_VERSION

set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

require_args_exact 2 "$@"
NGINX_VERSION="$1"
NGINX_TARBALL="$2"

run curl --fail -L -o "$NGINX_TARBALL" "https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"
