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
	zlib1g-dev wget curl python git \
	ccache reprepro libsqlite3-dev nodejs npm apt-transport-https ca-certificates
run apt-get install -y -q libcurl4-openssl-dev libssl-dev
run curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
run apt-get update -q && apt-get install -y -q yarn
run ln -s /usr/bin/python3 /bin/my_init_python
run gem install bundler -v 1.17.3 --no-document
run env BUNDLE_GEMFILE=/paa_build/Gemfile bundle install

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
