# Import built Debian packages from the given pbuilder directory into the given
# repository.
# 
# Unlike the ../import-packages script, this script does not create a new release
# within the APT repo. Instead, it accepts an existing release directory.
# ../import-packages uses this script internally. This script also does not sign
# the repository after importing.

set -e
shopt -s nullglob

function usage()
{
	echo "Usage: bash internal/import_packages.sh REPO_RELEASE_DIR PBUILDER_DIR DISTS ARCHS"
	echo "Import built Debian packages from the given pbuilder directory into the given"
	echo "repository."
}

REPO_RELEASE_DIR="$1"
PKG_DIR="$2"
DISTS="$3"
ARCHS="$4"

if [[ "$REPO_RELEASE_DIR" = "" || "$PKG_DIR" = "" || "$DISTS" = "" || "$ARCHS" = "" ]]; then
	usage
	exit 1
fi


BASE_DIR=`dirname "$0"`
BASE_DIR=`cd "$BASE_DIR/.."; pwd`
source "$BASE_DIR/lib/bashlib"

load_general_config
require_running_as_psg_apt_automation_user


for DIST in $DISTS; do
	# Import architecture-specific packages.
	for ARCH in $ARCHS; do
		if [[ $ARCH == amd64 ]]; then
			pbase_name="$DIST"
		else
			pbase_name="$DIST-$ARCH"
		fi
		result_dir="$PKG_DIR/${pbase_name}_result"
		files=("$result_dir"/*_$ARCH.deb)
		if [[ ${#files[@]} -gt 0 ]]; then
			echo "# Importing $ARCH packages:"
			for F in "${files[@]}"; do
				echo " --> $F"
			done
			reprepro --keepunusednewfiles --keepunreferencedfiles -Vb "$REPO_RELEASE_DIR" \
				includedeb $DIST "${files[@]}"
		fi
	done

	# Import architecture-independent packages.
	files=("$PKG_DIR"/${DIST}*_result/*_all.deb)
	if [[ ${#files[@]} -gt 0 ]]; then
		firstfile="${files[0]}"
		dir=`dirname "$firstfile"`
		echo "# Importing architecture-independent packages:"
		for F in "$dir"/*_all.deb; do
			echo " --> $F"
		done
		reprepro --keepunusednewfiles --keepunreferencedfiles -Vb "$REPO_RELEASE_DIR" \
			includedeb $DIST "$dir"/*_all.deb
	fi

	# Import source packages.
	files=("$PKG_DIR"/${DIST}*_result/*.dsc)
	if [[ ${#files[@]} -gt 0 ]]; then
		firstfile="${files[0]}"
		dir=`dirname "$firstfile"`
		echo "# Importing source packages:"
		for F in "$dir"/*.dsc; do
			echo " --> $F"
			reprepro --keepunusednewfiles --keepunreferencedfiles -Vb "$REPO_RELEASE_DIR" \
				includedsc $DIST "$F"
		done
	fi
done
