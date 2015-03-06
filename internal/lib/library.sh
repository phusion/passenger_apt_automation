if perl -v >/dev/null 2>/dev/null; then
	RESET=`perl -e 'print("\e[0m")'`
	BOLD=`perl -e 'print("\e[1m")'`
	YELLOW=`perl -e 'print("\e[33m")'`
	BLUE_BG=`perl -e 'print("\e[44m")'`
elif python -V >/dev/null 2>/dev/null; then
	RESET=`echo 'import sys; sys.stdout.write("\033[0m")' | python`
	BOLD=`echo 'import sys; sys.stdout.write("\033[1m")' | python`
	YELLOW=`echo 'import sys; sys.stdout.write("\033[33m")' | python`
	BLUE_BG=`echo 'import sys; sys.stdout.write("\033[44m")' | python`
else
	RESET=
	BOLD=
	YELLOW=
	BLUE_BG=
fi

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
	echo "+ $@"
	"$@"
}

function verbose_run()
{
	if $VERBOSE; then
		echo "+ $@"
	fi
	"$@"
}

function absolute_path()
{
	local dir="`dirname \"$1\"`"
	local name="`basename \"$1\"`"
	dir="`cd \"$dir\" && pwd`"
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
	local pids=`jobs -p`
	if [[ "$pids" != "" ]]; then
		kill $pids 2>/dev/null
	fi
	if [[ `type -t _cleanup` == function ]]; then
		_cleanup
	fi
}

trap cleanup EXIT
