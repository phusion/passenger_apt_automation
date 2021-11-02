#!/bin/bash
# Changes the 'app' user's UID and GID to the values specified
# in $APP_UID and $APP_GID.
set -e
set -o pipefail

# Hack to make the Passenger Apt packaging tests on our Jenkins infrastructure work. Jenkins has UID 999 and GID 998.

# There is a user runit-log and group _runit-log in the impish container with these UID/GID, but we don't need them so we just delete them.
if grep -q 'DISTRIB_RELEASE=21.10' /etc/lsb-release; then
	userdel runit-log
	groupdel _runit-log
fi

if [[ "$APP_UID" -lt 1024 ]]; then
	if awk -F: '{ print $3 }' < /etc/passwd | grep -q "^${APP_UID}$"; then
		echo "ERROR: you can only run this script with a user whose UID is at least 1024, or whose UID does not already exist in the Docker container. Current UID: $APP_UID"
		exit 1
	fi
fi
if [[ "$APP_GID" -lt 1024 ]]; then
	if awk -F: '{ print $3 }' < /etc/group | grep -q "^${APP_GID}$"; then
		echo "ERROR: you can only run this script with a user whose GID is at least 1024, or whose GID does not already exist in the Docker container. Current GID: $APP_GID"
		exit 1
	fi
fi

chown -R "$APP_UID:$APP_GID" /home/app
groupmod -g "$APP_GID" app
usermod -u "$APP_UID" -g "$APP_GID" app

# There's something strange with either Docker or the kernel, so that
# the 'app' user cannot access its home directory even after a proper
# chown/chmod. We work around it like this.
mv /home/app /home/app2
cp -dpR /home/app2 /home/app
rm -rf /home/app2

if [[ $# -gt 0 ]]; then
	exec "$@"
fi
