#!/bin/bash
set -e
if [[ ! -e /work ]]; then
	mkdir /work
	chown app: /work
fi
exec "$@"
