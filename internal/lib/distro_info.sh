#!/bin/bash
# DO NOT EDIT!!
# 
# This file is automatically generated from internal/lib/distro_info.sh.erb,
# using definitions from internal/lib/distro_info.rb and docker_image_info.sh.
# 
# Edit those and regenerate distro_info.sh by running:
# internal/scripts/regen_distro_info_script.sh

# shellcheck disable=SC2034
DEFAULT_DISTROS="xenial bionic focal hirsute stretch buster"


function to_distro_codename()
{
	local INPUT="$1"

	
		if [[ "$INPUT" = "lucid"
			|| "$INPUT" = "ubuntu10.04"
			|| "$INPUT" = "ubuntu-10.04" ]]
		then
			echo "lucid"
			return
		fi
	
		if [[ "$INPUT" = "maverick"
			|| "$INPUT" = "ubuntu10.10"
			|| "$INPUT" = "ubuntu-10.10" ]]
		then
			echo "maverick"
			return
		fi
	
		if [[ "$INPUT" = "natty"
			|| "$INPUT" = "ubuntu11.04"
			|| "$INPUT" = "ubuntu-11.04" ]]
		then
			echo "natty"
			return
		fi
	
		if [[ "$INPUT" = "oneiric"
			|| "$INPUT" = "ubuntu11.10"
			|| "$INPUT" = "ubuntu-11.10" ]]
		then
			echo "oneiric"
			return
		fi
	
		if [[ "$INPUT" = "precise"
			|| "$INPUT" = "ubuntu12.04"
			|| "$INPUT" = "ubuntu-12.04" ]]
		then
			echo "precise"
			return
		fi
	
		if [[ "$INPUT" = "quantal"
			|| "$INPUT" = "ubuntu12.10"
			|| "$INPUT" = "ubuntu-12.10" ]]
		then
			echo "quantal"
			return
		fi
	
		if [[ "$INPUT" = "raring"
			|| "$INPUT" = "ubuntu13.04"
			|| "$INPUT" = "ubuntu-13.04" ]]
		then
			echo "raring"
			return
		fi
	
		if [[ "$INPUT" = "saucy"
			|| "$INPUT" = "ubuntu13.10"
			|| "$INPUT" = "ubuntu-13.10" ]]
		then
			echo "saucy"
			return
		fi
	
		if [[ "$INPUT" = "trusty"
			|| "$INPUT" = "ubuntu14.04"
			|| "$INPUT" = "ubuntu-14.04" ]]
		then
			echo "trusty"
			return
		fi
	
		if [[ "$INPUT" = "utopic"
			|| "$INPUT" = "ubuntu14.10"
			|| "$INPUT" = "ubuntu-14.10" ]]
		then
			echo "utopic"
			return
		fi
	
		if [[ "$INPUT" = "vivid"
			|| "$INPUT" = "ubuntu15.04"
			|| "$INPUT" = "ubuntu-15.04" ]]
		then
			echo "vivid"
			return
		fi
	
		if [[ "$INPUT" = "wily"
			|| "$INPUT" = "ubuntu15.10"
			|| "$INPUT" = "ubuntu-15.10" ]]
		then
			echo "wily"
			return
		fi
	
		if [[ "$INPUT" = "xenial"
			|| "$INPUT" = "ubuntu16.04"
			|| "$INPUT" = "ubuntu-16.04" ]]
		then
			echo "xenial"
			return
		fi
	
		if [[ "$INPUT" = "yakkety"
			|| "$INPUT" = "ubuntu16.10"
			|| "$INPUT" = "ubuntu-16.10" ]]
		then
			echo "yakkety"
			return
		fi
	
		if [[ "$INPUT" = "zesty"
			|| "$INPUT" = "ubuntu17.04"
			|| "$INPUT" = "ubuntu-17.04" ]]
		then
			echo "zesty"
			return
		fi
	
		if [[ "$INPUT" = "artful"
			|| "$INPUT" = "ubuntu17.10"
			|| "$INPUT" = "ubuntu-17.10" ]]
		then
			echo "artful"
			return
		fi
	
		if [[ "$INPUT" = "bionic"
			|| "$INPUT" = "ubuntu18.04"
			|| "$INPUT" = "ubuntu-18.04" ]]
		then
			echo "bionic"
			return
		fi
	
		if [[ "$INPUT" = "cosmic"
			|| "$INPUT" = "ubuntu18.10"
			|| "$INPUT" = "ubuntu-18.10" ]]
		then
			echo "cosmic"
			return
		fi
	
		if [[ "$INPUT" = "disco"
			|| "$INPUT" = "ubuntu19.04"
			|| "$INPUT" = "ubuntu-19.04" ]]
		then
			echo "disco"
			return
		fi
	
		if [[ "$INPUT" = "eoan"
			|| "$INPUT" = "ubuntu19.10"
			|| "$INPUT" = "ubuntu-19.10" ]]
		then
			echo "eoan"
			return
		fi
	
		if [[ "$INPUT" = "focal"
			|| "$INPUT" = "ubuntu20.04"
			|| "$INPUT" = "ubuntu-20.04" ]]
		then
			echo "focal"
			return
		fi
	
		if [[ "$INPUT" = "groovy"
			|| "$INPUT" = "ubuntu20.10"
			|| "$INPUT" = "ubuntu-20.10" ]]
		then
			echo "groovy"
			return
		fi
	
		if [[ "$INPUT" = "hirsute"
			|| "$INPUT" = "ubuntu21.04"
			|| "$INPUT" = "ubuntu-21.04" ]]
		then
			echo "hirsute"
			return
		fi
	
	
		if [[ "$INPUT" = "squeeze"
			|| "$INPUT" = "debian6"
			|| "$INPUT" = "debian-6" ]]
		then
			echo "squeeze"
			return
		fi
	
		if [[ "$INPUT" = "wheezy"
			|| "$INPUT" = "debian7"
			|| "$INPUT" = "debian-7" ]]
		then
			echo "wheezy"
			return
		fi
	
		if [[ "$INPUT" = "jessie"
			|| "$INPUT" = "debian8"
			|| "$INPUT" = "debian-8" ]]
		then
			echo "jessie"
			return
		fi
	
		if [[ "$INPUT" = "stretch"
			|| "$INPUT" = "debian9"
			|| "$INPUT" = "debian-9" ]]
		then
			echo "stretch"
			return
		fi
	
		if [[ "$INPUT" = "buster"
			|| "$INPUT" = "debian10"
			|| "$INPUT" = "debian-10" ]]
		then
			echo "buster"
			return
		fi
	

	return 1
}

function get_buildbox_image()
{
	echo "phusion/passenger_apt_automation_buildbox:1.1.8"
}

function to_testbox_image()
{
	local INPUT="$1"

	
		if [[ "$INPUT" = "lucid"
			|| "$INPUT" = "ubuntu10.04"
			|| "$INPUT" = "ubuntu-10.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_10_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "maverick"
			|| "$INPUT" = "ubuntu10.10"
			|| "$INPUT" = "ubuntu-10.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_10_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "natty"
			|| "$INPUT" = "ubuntu11.04"
			|| "$INPUT" = "ubuntu-11.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_11_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "oneiric"
			|| "$INPUT" = "ubuntu11.10"
			|| "$INPUT" = "ubuntu-11.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_11_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "precise"
			|| "$INPUT" = "ubuntu12.04"
			|| "$INPUT" = "ubuntu-12.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_12_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "quantal"
			|| "$INPUT" = "ubuntu12.10"
			|| "$INPUT" = "ubuntu-12.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_12_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "raring"
			|| "$INPUT" = "ubuntu13.04"
			|| "$INPUT" = "ubuntu-13.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_13_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "saucy"
			|| "$INPUT" = "ubuntu13.10"
			|| "$INPUT" = "ubuntu-13.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_13_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "trusty"
			|| "$INPUT" = "ubuntu14.04"
			|| "$INPUT" = "ubuntu-14.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_14_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "utopic"
			|| "$INPUT" = "ubuntu14.10"
			|| "$INPUT" = "ubuntu-14.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_14_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "vivid"
			|| "$INPUT" = "ubuntu15.04"
			|| "$INPUT" = "ubuntu-15.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_15_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "wily"
			|| "$INPUT" = "ubuntu15.10"
			|| "$INPUT" = "ubuntu-15.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_15_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "xenial"
			|| "$INPUT" = "ubuntu16.04"
			|| "$INPUT" = "ubuntu-16.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_16_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "yakkety"
			|| "$INPUT" = "ubuntu16.10"
			|| "$INPUT" = "ubuntu-16.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_16_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "zesty"
			|| "$INPUT" = "ubuntu17.04"
			|| "$INPUT" = "ubuntu-17.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_17_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "artful"
			|| "$INPUT" = "ubuntu17.10"
			|| "$INPUT" = "ubuntu-17.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_17_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "bionic"
			|| "$INPUT" = "ubuntu18.04"
			|| "$INPUT" = "ubuntu-18.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_18_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "cosmic"
			|| "$INPUT" = "ubuntu18.10"
			|| "$INPUT" = "ubuntu-18.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_18_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "disco"
			|| "$INPUT" = "ubuntu19.04"
			|| "$INPUT" = "ubuntu-19.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_19_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "eoan"
			|| "$INPUT" = "ubuntu19.10"
			|| "$INPUT" = "ubuntu-19.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_19_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "focal"
			|| "$INPUT" = "ubuntu20.04"
			|| "$INPUT" = "ubuntu-20.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_20_04:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "groovy"
			|| "$INPUT" = "ubuntu20.10"
			|| "$INPUT" = "ubuntu-20.10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_20_10:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "hirsute"
			|| "$INPUT" = "ubuntu21.04"
			|| "$INPUT" = "ubuntu-21.04" ]]
		then
			echo phusion/passenger_apt_automation_testbox_ubuntu_21_04:1.0.7
			return
		fi
	
	
		if [[ "$INPUT" = "squeeze"
			|| "$INPUT" = "debian6"
			|| "$INPUT" = "debian-6" ]]
		then
			echo phusion/passenger_apt_automation_testbox_debian_6:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "wheezy"
			|| "$INPUT" = "debian7"
			|| "$INPUT" = "debian-7" ]]
		then
			echo phusion/passenger_apt_automation_testbox_debian_7:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "jessie"
			|| "$INPUT" = "debian8"
			|| "$INPUT" = "debian-8" ]]
		then
			echo phusion/passenger_apt_automation_testbox_debian_8:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "stretch"
			|| "$INPUT" = "debian9"
			|| "$INPUT" = "debian-9" ]]
		then
			echo phusion/passenger_apt_automation_testbox_debian_9:1.0.7
			return
		fi
	
		if [[ "$INPUT" = "buster"
			|| "$INPUT" = "debian10"
			|| "$INPUT" = "debian-10" ]]
		then
			echo phusion/passenger_apt_automation_testbox_debian_10:1.0.7
			return
		fi
	

	return 1
}

function dynamic_module_supported()
{
	local CODENAME="$1"

	
		if [[ "$CODENAME" = "artful" ]]; then
			echo true
			return
		fi
	
		if [[ "$CODENAME" = "bionic" ]]; then
			echo true
			return
		fi
	
		if [[ "$CODENAME" = "cosmic" ]]; then
			echo true
			return
		fi
	
		if [[ "$CODENAME" = "disco" ]]; then
			echo true
			return
		fi
	
		if [[ "$CODENAME" = "eoan" ]]; then
			echo true
			return
		fi
	
		if [[ "$CODENAME" = "focal" ]]; then
			echo true
			return
		fi
	
		if [[ "$CODENAME" = "groovy" ]]; then
			echo true
			return
		fi
	
		if [[ "$CODENAME" = "hirsute" ]]; then
			echo true
			return
		fi
	
	
		if [[ "$CODENAME" = "stretch" ]]; then
			echo true
			return
		fi
	
		if [[ "$CODENAME" = "buster" ]]; then
			echo true
			return
		fi
	

	echo false
}
