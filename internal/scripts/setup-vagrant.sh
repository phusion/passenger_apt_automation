#!/bin/bash
set -e
set -o pipefail
set -x

if [[ ! -e /usr/bin/docker ]]; then
	wget -qO- https://get.docker.com/ | bash
fi
usermod -aG docker vagrant
