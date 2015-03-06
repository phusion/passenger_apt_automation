#!/bin/bash
# Usage: download-nginx-orig-tarball.sh <OUTPUT>
# Downloads the Nginx source tarball.
#
# Required environment variables:
#
#   NGINX_VERSION

set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

require_args_exact 1 "$@"
require_envvar NGINX_VERSION "$NGINX_VERSION"

run curl --fail -L -o "$1" "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"
