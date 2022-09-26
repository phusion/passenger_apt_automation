#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
ARCH=$(dpkg --print-architecture)
# shellcheck source=../lib/library.sh
source "$ROOTDIR/internal/lib/library.sh"

COMPILE_CONCURRENCY=${COMPILE_CONCURRENCY:-2}
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8
export LC_CTYPE=C.UTF-8
export PASSENGER_TEST_NODE_MODULES_DIR=/tmp/passenger/node_modules

if [[ "$DISTRIBUTION" = wheezy ]]; then
	APACHE2_DEV_PACKAGES=(apache2 apache2-threaded-dev)
else
	APACHE2_DEV_PACKAGES=(apache2 apache2-dev)
	NGINX_DEV_PACKAGES=(nginx)
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
	run gdebi -n -q /output/passenger-enterprise_*_$ARCH.deb
	run gdebi -n -q /output/passenger-enterprise-dbg_*_$ARCH.deb
	run gdebi -n -q /output/passenger-enterprise-dev_*_$ARCH.deb
	run gdebi -n -q /output/passenger-enterprise-doc_*_all.deb
	run gdebi -n -q /output/libapache2-mod-passenger-enterprise_*_$ARCH.deb
else
	run gdebi -n -q /output/passenger_*_$ARCH.deb
	run gdebi -n -q /output/passenger-dbg_*_$ARCH.deb
	run gdebi -n -q /output/passenger-dev_*_$ARCH.deb
	run gdebi -n -q /output/passenger-doc_*_all.deb
	run gdebi -n -q /output/libapache2-mod-passenger_*_$ARCH.deb
fi
if ! ls /output/libnginx-mod-http-passenger* >/dev/null 2>/dev/null; then
	run gdebi -n -q /output/nginx-common_*_all.deb
	run gdebi -n -q /output/nginx-extras_*_$ARCH.deb
elif ls /output/*enterprise* >/dev/null 2>/dev/null; then
	run gdebi -n -q /output/libnginx-mod-http-passenger-enterprise_*_$ARCH.deb
	run apt-get install -y -q "${NGINX_DEV_PACKAGES[@]}"
else
	run gdebi -n -q /output/libnginx-mod-http-passenger_*_$ARCH.deb
	run apt-get install -y -q "${NGINX_DEV_PACKAGES[@]}"
fi
run apt-get install -y -q "${APACHE2_DEV_PACKAGES[@]}"

echo
header "Preparing Passenger source code..."
# /passenger is mounted read-only, but 'rake' may have to create files, e.g.
# to generate documentation files. So we copy it to a temporary directory
# which is writable.
run rm -rf /tmp/passenger
if [[ -e /passenger/.git ]]; then
	run setuser app mkdir /tmp/passenger
	echo "+ cd /passenger (expecting local git repo to copy from)"
	cd /passenger
	echo "+ adding /passenger to git config safe.directory"
	git config --global --add safe.directory /passenger
	echo "+ Getting list of submodules"
	submodules=$(git submodule status | awk '{ print $2 }')
	for submodule in $submodules; do
		echo "+ adding /passenger/$submodule to git config safe.directory"
		git config --global --add safe.directory "/passenger/$submodule"
	done
	echo "+ Copying all git committed files to /tmp/passenger"
	(
		set -o pipefail
		echo "+ Creating tar archive of repo, and extracting at /tmp/passenger"
		git archive --format=tar HEAD | setuser app tar -C /tmp/passenger -x
		for submodule in $submodules; do
			echo "+ Copying all git committed files from submodule $submodule"
			pushd "$submodule" >/dev/null
			mkdir -p "/tmp/passenger/$submodule"
			git archive --format=tar HEAD | setuser app tar -C "/tmp/passenger/$submodule" -x
			popd >/dev/null
		done
	)
	# shellcheck disable=SC2181
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
run setuser app mkdir -p "$CCACHE_DIR"
echo "+ Updating /etc/hosts"
cat /system/internal/test/misc/hosts.conf >> /etc/hosts
APACHE_INFO=$(apache2ctl -V 2>/dev/null)
APACHE_VERSION=$(echo "$APACHE_INFO" | grep 'Server version' | sed 's/.*\///; s/ .*//')
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
run setuser app mkdir -p "/cache/test-$DISTRIBUTION/bundle"
run setuser app mkdir -p "/cache/test-$DISTRIBUTION/node_modules"
run setuser app ln -s "/cache/test-$DISTRIBUTION/node_modules" node_modules
run setuser app rake test:install_deps DOCTOOLS=no DEPS_TARGET="/cache/test-$DISTRIBUTION/bundle" BUNDLE_ARGS="-j 4"
if [[ $DYNAMIC_MODULE_SUPPORTED == true ]]; then
	CONFIG_SUFFIX="-dynamic"
else
	CONFIG_SUFFIX=""
fi
if ! ls /output/*enterprise* >/dev/null 2>/dev/null; then
	run setuser app cp "/system/internal/test/misc/config-oss$CONFIG_SUFFIX.json" test/config.json
else
	run setuser app cp "/system/internal/test/misc/config-enterprise$CONFIG_SUFFIX.json" test/config.json
fi
find . -print0 /var/{log,lib}/nginx -type d | xargs -0 --no-run-if-empty chmod o+rwx
find . -print0 /var/{log,lib}/nginx -type f | xargs -0 --no-run-if-empty chmod o+rw

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
find . -print0 /var/lib/nginx -type d | xargs -0 --no-run-if-empty chmod o+rwx
find . -print0 /var/lib/nginx -type f | xargs -0 --no-run-if-empty chmod o+rw

run passenger-config validate-install --auto --validate-apache2
run setuser app bundle exec rake "-j$COMPILE_CONCURRENCY" \
	test:integration:native_packaging PRINT_FAILED_COMMAND_OUTPUT=1
run setuser app env "PASSENGER_LOCATION_CONFIGURATION_FILE=$(passenger-config --root)" \
	bundle exec rake "-j$COMPILE_CONCURRENCY" test:integration:apache2
run setuser app env "PASSENGER_LOCATION_CONFIGURATION_FILE=$(passenger-config --root)" \
	bundle exec rake "-j$COMPILE_CONCURRENCY" test:integration:nginx
