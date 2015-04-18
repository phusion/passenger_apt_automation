function distro_name_to_codename()
{
	local DISTRIBUTION="$1"
	if [[ "$DISTRIBUTION" = ubuntu15.04 ]]; then
		echo vivid
	elif [[ "$DISTRIBUTION" = ubuntu14.04 ]]; then
		echo trusty
	elif [[ "$DISTRIBUTION" = ubuntu12.04 ]]; then
		echo precise
	elif [[ "$DISTRIBUTION" = ubuntu10.04 ]]; then
		echo lucid
	elif [[ "$DISTRIBUTION" = debian10 ]]; then
		echo buster
	elif [[ "$DISTRIBUTION" = debian9 ]]; then
		echo stretch
	elif [[ "$DISTRIBUTION" = debian8 ]]; then
		echo jessie
	elif [[ "$DISTRIBUTION" = debian7 ]]; then
		echo wheezy
	elif [[ "$DISTRIBUTION" = debian6 ]]; then
		echo squeeze
	else
		echo "ERROR: unknown distribution name." >&2
		return 1
	fi
}

function distro_name_to_testbox_image()
{
	local DISTRIBUTION="$1"
	if [[ "$DISTRIBUTION" = ubuntu15.04 ]]; then
		echo phusion/passenger_apt_automation_testbox_ubuntu_15_04
	elif [[ "$DISTRIBUTION" = ubuntu14.04 ]]; then
		echo phusion/passenger_apt_automation_testbox_ubuntu_14_04
	elif [[ "$DISTRIBUTION" = ubuntu12.04 ]]; then
		echo phusion/passenger_apt_automation_testbox_ubuntu_12_04
	elif [[ "$DISTRIBUTION" = ubuntu10.04 ]]; then
		echo phusion/passenger_apt_automation_testbox_ubuntu_10_04
	elif [[ "$DISTRIBUTION" = debian10 ]]; then
		echo phusion/passenger_apt_automation_testbox_debian_10
	elif [[ "$DISTRIBUTION" = debian9 ]]; then
		echo phusion/passenger_apt_automation_testbox_debian_9
	elif [[ "$DISTRIBUTION" = debian8 ]]; then
		echo phusion/passenger_apt_automation_testbox_debian_8
	elif [[ "$DISTRIBUTION" = debian7 ]]; then
		echo phusion/passenger_apt_automation_testbox_debian_7
	elif [[ "$DISTRIBUTION" = debian6 ]]; then
		echo phusion/passenger_apt_automation_testbox_debian_6
	else
		echo "ERROR: unknown distribution name." >&2
		return 1
	fi
}
