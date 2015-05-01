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
run cp /paa_build/sudoers.conf /etc/sudoers.d/app
run chown root: /etc/sudoers.d/app
run chmod 440 /etc/sudoers.d/app
run cp /paa_build/pbuilderrc ~app/.pbuilderrc
run chown app: ~app/.pbuilderrc

header "Installing dependencies"
run apt-get update -q
run apt-get install -y -q ubuntu-dev-tools debhelper source-highlight \
	ruby ruby-dev libsqlite3-dev runit git gawk rake realpath debian-keyring \
	zlib1g-dev libxml2-dev libxslt1-dev gdebi-core gnupg dh-systemd
run gem1.9.1 install bundler --no-rdoc --no-ri
run env BUNDLE_GEMFILE=/paa_build/Gemfile bundle install

header "Importing public keys"
run sudo -u app -H gpg --keyserver keyserver.ubuntu.com --recv-keys C324F5BB38EEB5A0
run sudo -u app -H gpg --armor --export C324F5BB38EEB5A0 | apt-key add -
# Fixes pbuilder-dist not being able to debootstrap Debian dists.
run gpg --keyring /usr/share/keyrings/debian-archive-keyring.gpg --keyserver keyserver.ubuntu.com --recv-keys 6FB2A1C265FFB764

header "Fix Docker PAM bug"
# https://github.com/docker/docker/issues/6345
# The Github is closed, but for some reason pbuilder still triggers it.
export CONFIGURE_OPTS=--disable-audit
cd /root
run apt-get -y build-dep pam
run apt-get -y -b source pam
run dpkg -i libpam-doc*.deb libpam-modules*.deb libpam-runtime*.deb libpam0g*.deb
run rm -rf *.deb *.gz *.dsc *.changes pam-*

header "Finishing up"
run cp /paa_build/CONTAINER_VERSION.txt /
# Undo 'apt-get build-dep pam'
run apt-get remove -y autoconf automake autopoint autotools-dev dh-autoreconf docbook-xml \
	docbook-xsl flex libaudit-dev libcrack2 libcrack2-dev libdb-dev libdb5.3-dev \
	libfl-dev libgc1c2 libpcre3-dev libpcrecpp0 libselinux1-dev libsepol1-dev \
	libtool libxml2-utils m4 pkg-config sgml-data w3m xsltproc
run apt-get autoremove -y
run apt-get clean
run rm -rf /tmp/* /var/tmp/*
run rm -rf /var/lib/apt/lists/*
run rm -rf /paa_build
