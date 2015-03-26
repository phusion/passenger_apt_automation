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

header "Creating users and directories"
run create_user app "Passenger APT Automation" 2446

header "Installing dependencies"
echo "+ Adding Node.js 0.12 repository"
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
run apt-get install -y -q build-essential gdebi-core ruby ruby-dev rake \
	libcurl4-openssl-dev zlib1g-dev libssl-dev python git
run gem1.9.1 install bundler -v 1.9.1 --no-rdoc --no-ri
run apt-get install -y nodejs

header "Allow APT caching"
run rm /etc/apt/apt.conf.d/docker-clean

header "Finishing up"
run apt-get autoremove -y
run apt-get clean
run rm -rf /tmp/* /var/tmp/*
run rm -rf /var/lib/apt/lists/*
