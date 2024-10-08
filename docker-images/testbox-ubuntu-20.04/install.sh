#!/bin/bash
set -e

function header()
{
	echo
	echo "----- $* -----"
}

function run()
{
	echo "+ $*"
	"$@"
}

function create_user()
{
	local name="$1"
	local full_name="$2"
	local id="$3"
	create_group "$name" "$id"
	if ! grep -q "^$name:" /etc/passwd; then
		adduser --uid "$id" --gid "$id" --disabled-password --gecos "$full_name" "$name"
	fi
	usermod -L "$name"
	chmod o+rx "/home/$name"
}

function create_group()
{
	local name="$1"
	local id="$2"
	if ! grep -q "^$name:" /etc/group >/dev/null; then
		addgroup --gid "$id" "$name"
	fi
}

export LC_CTYPE=C.UTF-8
export LC_ALL=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export HOME=/root

header "Creating users and directories"
run apt-get update -q
run apt-get install -y -q adduser
run create_user app "Passenger APT Automation" 2446

header "Installing dependencies"
run apt-get install -y -q gdebi-core ruby ruby-dev rake \
	wget curl python3 libcurl4-openssl-dev libssl-dev \
	ccache reprepro apt-transport-https ca-certificates \
	fakeroot libalgorithm-merge-perl less libfile-fcntllock-perl \
	liblocale-gettext-perl python-is-python3 systemd ruby-nokogiri distro-info-data
run apt-get install -y -q --no-install-recommends git \
	build-essential libsqlite3-dev zlib1g-dev ssh-client

header "Node.js"
# Define the desired Node.js major version
NODE_MAJOR=20
# Create a directory for the new repository's keyring, if it doesn't exist
run mkdir -p /etc/apt/keyrings
# Download the new repository's GPG key and save it in the keyring directory
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
# Add the new repository's source list with its GPG key for package verification
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
run apt-get install -y nodejs npm --no-install-recommends
run apt remove -y fonts-lato

run ln -s /usr/bin/python3 /bin/my_init_python
run gem install bundler -v '~>1.0' --no-document
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
