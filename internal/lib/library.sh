#!/usr/bin/env bash

RESET=$(echo -e "\\033[0m")
BOLD=$(echo -e "\\033[1m")
YELLOW=$(echo -e "\\033[33m")
BLUE_BG=$(echo -e "\\033[44m")

if [[ "$VERBOSE" = "" ]]; then
	VERBOSE=false
fi

function header()
{
	local title="$1"
	echo "${BLUE_BG}${YELLOW}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}

function run()
{
	echo "+ $*"
	"$@"
}

function verbose_run()
{
	if $VERBOSE; then
		echo "+ $*"
	fi
	"$@"
}

function absolute_path()
{
	local dir
	local name

	dir=$(dirname "$1")
	name=$(basename "$1")
	dir=$(cd "$dir" && pwd)
	echo "$dir/$name"
}

function require_args_exact()
{
	local count="$1"
	shift
	if [[ $# -ne $count ]]; then
		echo "ERROR: $count arguments expected, but got $#."
		exit 1
	fi
}

function require_envvar()
{
	local name="$1"
	local value="$2"
	if [[ "$value" = "" ]]; then
		echo "ERROR: the environment variable '$name' is required."
		exit 1
	fi
}

function cleanup()
{
	set +e
	local pids
	pids=$(jobs -p)
	if [[ "$pids" != "" ]]; then
		# shellcheck disable=SC2086
		kill $pids 2>/dev/null
	fi
	if [[ $(type -t _cleanup) == function ]]; then
		_cleanup
	fi
}

trap cleanup EXIT
