#!/bin/bash
set -e

function header()
{
	echo
	echo "----- $@ -----"
}

function run()
{
	echo "+ $@"
	"$@"
}

function create_user()
{
	local name="$1"
	local full_name="$2"
	local id="$3"
	create_group $name $id
	if ! grep -q "^$name:" /etc/passwd; then
		adduser --uid $id --gid $id --disabled-password --gecos "$full_name" $name
	fi
	usermod -L $name
}

function create_group()
{
	local name="$1"
	local id="$2"
	if ! grep -q "^$name:" /etc/group >/dev/null; then
		addgroup --gid $id $name
	fi
}

export LC_CTYPE=C.UTF-8
export LC_ALL=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export HOME=/root

header "Creating users and directories"
run create_user app "Passenger APT Automation" 2446

header "Installing dependencies"
run apt-get update -q
run apt-get install -y -q build-essential gdebi-core ruby ruby-dev rake \
	libcurl4-openssl-dev zlib1g-dev libssl-dev wget curl python \
	ccache reprepro libsqlite3-dev apt-transport-https ca-certificates
run apt-get install -y -q --no-install-recommends git
run ln -s /usr/bin/python3 /bin/my_init_python
run gem install bundler -v 1.11.2 --no-rdoc --no-ri
run env BUNDLE_GEMFILE=/paa_build/Gemfile bundle install

header "Node.js"
# 18+ uses a too new glibc: https://github.com/nodejs/node/issues/43246
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
run apt-get install -y nodejs --no-install-recommends

header "Miscellaneous"
run mkdir /etc/container_environment
run rm /etc/apt/apt.conf.d/docker-clean
run mkdir /paa
run cp /paa_build/Gemfile* /paa/

header "Finishing up"
run apt-get autoremove -y
run apt-get clean
run rm -rf /tmp/* /var/tmp/*
run rm -rf /var/lib/apt/lists/*
run rm -rf /paa_build
