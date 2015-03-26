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

header "Preparation"
export LC_CTYPE=C.UTF-8
export LC_ALL=C.UTF-8
export DEBIAN_FRONTEND=noninteractive

header "Creating users and directories"
run create_user app "Passenger APT Automation" 2446

header "Installing dependencies"
run apt-get update -q
run apt-get install -y -q build-essential gdebi-core ruby rubygems ruby-dev rake \
	libopenssl-ruby libcurl4-openssl-dev zlib1g-dev libssl-dev wget curl \
	python python2.6-dev python-pip git-core

run wget http://production.cf.rubygems.org/rubygems/rubygems-update-2.4.6.gem -O /tmp/rubygems.gem
run gem install /tmp/rubygems.gem --no-rdoc --no-ri
run /var/lib/gems/1.8/bin/update_rubygems --no-rdoc --no-ri
run gem install bundler -v 1.9.1 --no-rdoc --no-ri

run cp /build/argparse.py /usr/lib/python2.6/
run pip install initgroups

run wget http://nodejs.org/dist/v0.12.1/node-v0.12.1-linux-x64.tar.gz -O /tmp/node.tar.gz
run tar -xzf /tmp/node.tar.gz -C /usr/local
run ln -s /usr/local/node-*/bin/* /usr/local/bin/

header "Miscellaneous"
run cp /build/my_init /build/setuser /sbin/
run mkdir /etc/container_environment
run rm /etc/apt/apt.conf.d/no-cache

header "Finishing up"
run apt-get autoremove -y
run apt-get clean
run rm -rf /tmp/* /var/tmp/*
run rm -rf /var/lib/apt/lists/*
