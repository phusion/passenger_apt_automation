#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

COMPILE_CONCURRENCY=${COMPILE_CONCURRENCY:-2}
export DEBIAN_FRONTEND=noninteractive
if [[ "$DISTRIBUTION" = ubuntu10.04 ]]; then
	export LC_ALL=POSIX
	export LC_CTYPE=POSIX
else
	export LC_ALL=C.UTF-8
	export LC_CTYPE=C.UTF-8
fi

echo
header "Installing packages..."
run apt-get update -q
if ls /output/*enterprise* >/dev/null 2>/dev/null; then
	run gdebi -n -q /output/passenger-enterprise_*_amd64.deb
	run gdebi -n -q /output/passenger-enterprise-dev_*_amd64.deb
	run gdebi -n -q /output/passenger-enterprise-doc_*_all.deb
	run gdebi -n -q /output/libapache2-mod-passenger-enterprise_*_amd64.deb
else
	run gdebi -n -q /output/passenger_*_amd64.deb
	run gdebi -n -q /output/passenger-dev_*_amd64.deb
	run gdebi -n -q /output/passenger-doc_*_all.deb
	run gdebi -n -q /output/libapache2-mod-passenger_*_amd64.deb
fi
run gdebi -n -q /output/nginx-common_*_all.deb
run gdebi -n -q /output/nginx-extras_*_amd64.deb
run apt-get install -y -q apache2-dev

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
	)
	[[ $? = 0 ]]
else
	run setuser app cp -R /passenger /tmp/passenger
fi
echo "+ cd /tmp/passenger"
cd /tmp/passenger

echo
header "Preparing system..."
echo "+ Updating /etc/hosts"
cat >> /etc/hosts <<EOF
127.0.0.1 passenger.test
127.0.0.1 1.passenger.test 2.passenger.test 3.passenger.test
127.0.0.1 4.passenger.test 5.passenger.test 6.passenger.test
127.0.0.1 7.passenger.test 8.passenger.test 9.passenger.test
EOF
run setuser app mkdir -p /cache/test/bundle
run setuser app rake test:install_deps DOCTOOLS=no DEPS_TARGET=/cache/test/bundle BUNDLE_ARGS="-j 4"
run setuser app cp /system/internal/test/config.json test/config.json
run chmod -R o+rw /var/log/nginx
run chmod -R o+rw /var/lib/nginx
run chmod o+x /var/log/nginx
run chmod o+x /var/lib/nginx

echo
header "Running tests..."
run setuser app bundle exec drake -j$COMPILE_CONCURRENCY \
	test:integration:native_packaging PRINT_FAILED_COMMAND_OUTPUT=1
run setuser app env PASSENGER_LOCATION_CONFIGURATION_FILE=/usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini \
	bundle exec drake -j$COMPILE_CONCURRENCY test:integration:apache2
run setuser app env PASSENGER_LOCATION_CONFIGURATION_FILE=/usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini \
	bundle exec drake -j$COMPILE_CONCURRENCY test:integration:nginx
