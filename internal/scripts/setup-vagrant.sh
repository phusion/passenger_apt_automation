#!/bin/bash
set -e
set -o pipefail
set -x

if [[ ! -e /usr/bin/docker ]]; then
	curl -sSL https://get.docker.com/ | bash
fi
usermod -aG docker vagrant
if ! grep -q 'cd /vagrant' ~vagrant/.profile; then
	echo 'if tty -s; then cd /vagrant; fi' >> ~vagrant/.profile
fi
