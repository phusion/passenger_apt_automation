#!/bin/bash
# DO NOT EDIT!!
# 
# This file is automatically generated from internal/lib/distro_info.sh.erb,
# using definitions from internal/lib/distro_info.rb and docker_image_info.sh.
# 
# Edit those and regenerate distro_info.sh by running:
# internal/scripts/regen_distro_info_script.sh

# shellcheck disable=SC2034
DEFAULT_DISTROS="focal jammy noble plucky bullseye bookworm"
DEBIAN_DISTROS="11 12"
UBUNTU_DISTROS="20.04 22.04 24.04 25.04"


function to_distro_codename()
{
	if [ $# -ge 1 ] && [ -n "$*" ]; then
	local INPUT="$*"
	INPUT=${INPUT#ubuntu-}
	INPUT=${INPUT#ubuntu}
	INPUT=${INPUT#debian-}
	INPUT=${INPUT#debian}

	local AWK_SCRIPT='
          BEGIN { oRS=RS; RS=FS }
          /^version$/ { version_index = FNR; next }
          /^series$/ { series_index = FNR; next }
          (version_index > 0 && series_index > 0) { RS = oRS }
          FNR>1 && ($version_index ~ PATTERN || $series_index ~ PATTERN) {
            print $series_index
          }
        '

	local CODENAME=$(awk -F, -vPATTERN="^$INPUT(\\\\.0| LTS)?\$" "$AWK_SCRIPT" /usr/share/distro-info/*.csv)

	if [ -n "$CODENAME" ]; then
		echo $CODENAME
		return 0
	fi
	fi
	echo UNKNOWN_DISTRO
	echo "distro $* unknown to buildbox" >&2
	return 1
}

function get_buildbox_image()
{
	echo "phusion/passenger_apt_automation_buildbox:2.2.1"
}

function to_testbox_image()
{
	local INPUT=$(to_distro_codename $1)
	local AWK_SCRIPT='
          BEGIN { oRS=RS; RS=FS }
          /^version$/ { version_index = FNR; next }
          /^series$/ { series_index = FNR; next }
          (version_index > 0 && series_index > 0) { RS = oRS }
          FNR>1 && ($version_index ~ PATTERN || $series_index ~ PATTERN) {
            version = $version_index;
            sub(/\.0$/, "", version);
            sub(/ LTS$/, "", version);
            print version
          }
        '

	local VERSION=$(awk -F, -vPATTERN="^$INPUT( LTS)?\$" "$AWK_SCRIPT" /usr/share/distro-info/ubuntu.csv)
	if [ -n "$VERSION" ]; then
		  echo phusion/passenger_apt_automation_testbox_ubuntu_${VERSION/./_}:2.2.1
		  return
	fi

	VERSION=$(awk -F, -vPATTERN="^$INPUT(\\\\.0)?\$" "$AWK_SCRIPT" /usr/share/distro-info/debian.csv)
	if [ -n "$VERSION" ]; then
		  echo phusion/passenger_apt_automation_testbox_debian_${VERSION/./_}:2.2.1
		  return
	fi

	return 1
}

function ubuntu_gte()
{
	local AWK_SCRIPT='
          BEGIN { oRS=RS; RS=FS }
          /^version$/ { version_index = FNR; next }
          /^series$/ { series_index = FNR; next }
          /^release$/ { release_index = FNR; next }
          (version_index > 0 && series_index > 0 && release_index > 0) { RS = oRS }
          FNR>1 && ($version_index ~ PATTERN || $series_index ~ PATTERN) {
            print $release_index
          }
        '
	local INPUT1=$(to_distro_codename $1)
	local INPUT2=$(to_distro_codename $2)
	local REL_1=$(awk -F, -vPATTERN="^$INPUT1( LTS)?\$" "$AWK_SCRIPT" /usr/share/distro-info/ubuntu.csv)
	local REL_2=$(awk -F, -vPATTERN="^$INPUT2( LTS)?\$" "$AWK_SCRIPT" /usr/share/distro-info/ubuntu.csv)
	echo -e "$REL_1\n$REL_2" | sort -rC
}

function debian_gte()
{
	local AWK_SCRIPT='
          BEGIN { oRS=RS; RS=FS }
          /^version$/ { version_index = FNR; next }
          /^series$/ { series_index = FNR; next }
          /^release$/ { release_index = FNR; next }
          (version_index > 0 && series_index > 0 && release_index > 0) { RS = oRS }
          FNR>1 && ($version_index ~ PATTERN || $series_index ~ PATTERN) {
            print $release_index
          }
        '
	local INPUT1=$(to_distro_codename $1)
	local INPUT2=$(to_distro_codename $2)
	local REL_1=$(awk -F, -vPATTERN="^$INPUT1(\\\\.0)?\$" "$AWK_SCRIPT" /usr/share/distro-info/debian.csv)
	local REL_2=$(awk -F, -vPATTERN="^$INPUT2(\\\\.0)?\$" "$AWK_SCRIPT" /usr/share/distro-info/debian.csv)
	echo -e "$REL_1\n$REL_2" | sort -rC
}

function dynamic_module_supported()
{
	if ubuntu_gte "$1" artful; then
		  echo true
		  return
	fi

	if debian_gte "$1" stretch; then
		  echo true
		  return
	fi

	echo false
}

function known_distro ()
{
	local INPUT=$(to_distro_codename $1)
	local AWK_SCRIPT='
          BEGIN { oRS=RS; RS=FS; err = 1 }
          /^version$/ { version_index = FNR; next }
          /^series$/ { series_index = FNR; next }
          (version_index > 0 && series_index > 0) { RS = oRS }
          FNR>1 && ($version_index ~ PATTERN || $series_index ~ PATTERN) { err = 0 }
          END { exit err }
        '
	awk -F, -vPATTERN="^$INPUT( LTS|\\\\.0)?\$" "$AWK_SCRIPT" /usr/share/distro-info/*.csv
}
