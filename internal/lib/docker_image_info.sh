#!/bin/bash

# This is the main place to control the names and versions of the Docker build / test images
# to be used by various scripts.

USAGE="argument 1 should be one of: buildbox_name, buildbox_version, testbox_base_name or testbox_version"

if [ -z "$1" ]; then
	echo "$USAGE"
	exit 1
fi

if [ $1 == "buildbox_name" ]; then
	echo -n "phusion/passenger_apt_automation_buildbox"
elif [ $1 == "buildbox_version" ]; then
	echo -n "1.0.0"
elif [ $1 == "testbox_base_name" ]; then
	echo -n "phusion/passenger_apt_automation_testbox"
elif [ $1 == "testbox_version" ]; then
	echo -n "1.0.0"
else
	echo "$USAGE"
	exit 1
fi
