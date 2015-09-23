#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

COMPILE_CONCURRENCY=${COMPILE_CONCURRENCY:-2}
export DEBIAN_FRONTEND=noninteractive
if [[ "$DISTRIBUTION" = debian6 ]]; then
	export LC_ALL=POSIX
	export LC_CTYPE=POSIX
else
	export LC_ALL=C.UTF-8
	export LC_CTYPE=C.UTF-8
fi
if [[ "$DISTRIBUTION" = debian7 ]]; then
	APACHE2_DEV_PACKAGES="apache2 apache2-threaded-dev"
else
	APACHE2_DEV_PACKAGES="apache2 apache2-dev"
fi

if ls /output/*enterprise* >/dev/null 2>/dev/null; then
	if [[ ! -e /etc/passenger-enterprise-license ]]; then
		echo "ERROR: please set a Passenger Enterprise license key with -e."
		exit 1
	fi
fi

echo
header "Installing packages..."
run apt-get update -q
if ls /output/*enterprise* >/dev/null 2>/dev/null; then
	run gdebi -n -q /output/passenger-enterprise_*_amd64.deb
	run gdebi -n -q /output/passenger-enterprise-dbg_*_amd64.deb
	run gdebi -n -q /output/passenger-enterprise-dev_*_amd64.deb
	run gdebi -n -q /output/passenger-enterprise-doc_*_all.deb
	run gdebi -n -q /output/libapache2-mod-passenger-enterprise_*_amd64.deb
else
	run gdebi -n -q /output/passenger_*_amd64.deb
	run gdebi -n -q /output/passenger-dbg_*_amd64.deb
	run gdebi -n -q /output/passenger-dev_*_amd64.deb
	run gdebi -n -q /output/passenger-doc_*_all.deb
	run gdebi -n -q /output/libapache2-mod-passenger_*_amd64.deb
fi
run gdebi -n -q /output/nginx-common_*_all.deb
run gdebi -n -q /output/nginx-extras_*_amd64.deb
run apt-get install -y -q $APACHE2_DEV_PACKAGES

echo
header "Preparing Passenger source code..."
# /passenger is mounted read-only, but 'rake' may have to create files, e.g.
# to generate documentation files. So we copy it to a temporary directory
# which is writable.
run rm -rf /tmp/passenger
if [[ -e /passenger/.git ]]; then
	run setuser app mkdir /tmp/passenger
	echo "+ cd /passenger"
	cd /passenger
	echo "+ Git copying to /tmp/passenger"
	(
		set -o pipefail
		git archive --format=tar HEAD | setuser app tar -C /tmp/passenger -x
		submodules=`git submodule status | awk '{ print $2 }'`
		for submodule in $submodules; do
			echo "+ Git copying submodule $submodule"
			pushd $submodule >/dev/null
			mkdir -p /tmp/passenger/$submodule
			git archive --format=tar HEAD | setuser app tar -C /tmp/passenger/$submodule -x
			popd >/dev/null
		done
	)
	if [[ $? != 0 ]]; then
		exit 1
	fi
else
	run setuser app cp -R /passenger /tmp/passenger
fi
echo "+ cd /tmp/passenger"
cd /tmp/passenger

echo
header "Preparing system..."
export PATH=/usr/lib64/ccache:$PATH
export CCACHE_DIR=/cache/test-$DISTRIBUTION/ccache
export CCACHE_COMPRESS=1
export CCACHE_COMPRESS_LEVEL=3
run setuser app mkdir -p $CCACHE_DIR
echo "+ Updating /etc/hosts"
cat /system/internal/test/misc/hosts.conf >> /etc/hosts
APACHE_INFO=`apache2ctl -V 2>/dev/null`
APACHE_VERSION=`echo "$APACHE_INFO" | grep 'Server version' | sed 's/.*\///; s/ .*//'`
if [[ -e /etc/apache2/conf-enabled ]]; then
	APACHE_CONF_D_DIR=/etc/apache2/conf-enabled
else
	APACHE_CONF_D_DIR=/etc/apache2/conf.d
fi
if ruby -e 'exit(ARGV[0] >= ARGV[1])' "$APACHE_VERSION" 2.4; then
	run cp /system/internal/test/apache/apache-24.conf $APACHE_CONF_D_DIR
	run chmod 644 $APACHE_CONF_D_DIR/apache-24.conf
else
	run cp /system/internal/test/apache/apache-pre-24.conf $APACHE_CONF_D_DIR
	run chmod 644 $APACHE_CONF_D_DIR/apache-pre-24.conf
fi
run a2enmod passenger
run setuser app mkdir -p /cache/test-$DISTRIBUTION/bundle
run setuser app mkdir -p /cache/test-$DISTRIBUTION/node_modules
run setuser app ln -s /cache/test-$DISTRIBUTION/node_modules node_modules
run setuser app rake test:install_deps DOCTOOLS=no DEPS_TARGET=/cache/test-$DISTRIBUTION/bundle BUNDLE_ARGS="-j 4"
run setuser app cp /system/internal/test/misc/config.json test/config.json
find /var/{log,lib}/nginx -type d | xargs --no-run-if-empty chmod o+rwx
find /var/{log,lib}/nginx -type f | xargs --no-run-if-empty chmod o+rw

if $DEBUG_CONSOLE; then
	echo
	echo "---------------------------------------------"
	echo "A debugging console will now be opened for you."
	echo
	# Do not trigger the debugging console that will be called on failure.
	bash -l || true
	exit 0
fi

echo
header "Running tests..."

run env BUNDLE_GEMFILE=/paa/Gemfile bundle exec \
	rspec -f d -c --tty /system/internal/test/system_web_server_test.rb
# The Nginx instance launched by system_web_server_test.rb may have created subdirectories
# in /var/lib/nginx. We relax their permissions here because subsequent tests run Nginx
# as the 'app' user.
echo "+ Relaxing permissions in /var/lib/nginx"
find /var/lib/nginx -type d | xargs --no-run-if-empty chmod o+rwx
find /var/lib/nginx -type f | xargs --no-run-if-empty chmod o+rw

run passenger-config validate-install --auto --validate-apache2
run setuser app bundle exec drake -j$COMPILE_CONCURRENCY \
	test:integration:native_packaging PRINT_FAILED_COMMAND_OUTPUT=1
run setuser app env PASSENGER_LOCATION_CONFIGURATION_FILE=`passenger-config --root` \
	bundle exec drake -j$COMPILE_CONCURRENCY test:integration:apache2
run setuser app env PASSENGER_LOCATION_CONFIGURATION_FILE=`passenger-config --root` \
	bundle exec drake -j$COMPILE_CONCURRENCY test:integration:nginx
