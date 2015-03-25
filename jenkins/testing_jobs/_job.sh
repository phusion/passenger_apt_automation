#!/bin/bash
set -e
SELFDIR=`dirname "$0"`
cd "$SELFDIR/../.."
source "./internal/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"
