#!/bin/bash
set -e
set -o pipefail
set -x

if [[ ! -e /usr/bin/docker ]]; then
	apt-get update
	apt-get install -y apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	apt-get update
	apt-get install -y docker-ce
fi
usermod -aG docker vagrant
if ! grep -q 'cd /vagrant' ~vagrant/.profile; then
	echo 'if tty -s; then cd /vagrant; fi' >> ~vagrant/.profile
fi
