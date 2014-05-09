set -e


##### Preparation #####

source lib/bashlib
load_general_config

shopt -s dotglob
set -x

mkdir -p "$PKG_DIR"
reset_fake_pbuild_folder "$PBUILDFOLDER"

export PASSENGER_DIR="$PROJECT_GIT_REPO_DIR"


##### Update repository #####

if [[ -e "$PROJECT_GIT_REPO_DIR" ]]; then
	stage "Updating repository..." updating_repo
	cd "$PROJECT_GIT_REPO_DIR"
	if [[ "`git config remote.origin.url`" != "$GIT_URL" ]]; then
		echo "Git repository URL does not match!"
		exit 1
	fi
	git fetch
	(
		shopt -u dotglob
		rm -rf *
	)
else
	stage "Cloning repository..."
	git clone "$GIT_URL" "$PROJECT_GIT_REPO_DIR"
	cd "$PROJECT_GIT_REPO_DIR"
fi
git reset --hard "$REF"


##### Build packages #####

stage "Building Phusion Passenger source packages..." building_passenger_source_packages
drake debian:source_packages

stage "Building Phusion Passenger binary packages..." building_passenger_binary_packages
drake debian:binary_packages -j$CONCURRENCY_LEVEL

stage "Building Nginx source packages..." building_nginx_source_packages
cd "$BASE_DIR"
./create-nginx-packages source_packages
stage "Building Nginx binary packages..." building_nginx_binary_packages
./create-nginx-packages binary_packages -j$CONCURRENCY_LEVEL


##### Sign packages #####

stage "Signing packages..." signing_packages
cd "$BASE_DIR"
debsign -k"$SIGNING_KEY" "$PKG_DIR"/nginx*.changes
debsign -k"$SIGNING_KEY" "$PKG_DIR"/official/*.changes
debsign -k"$SIGNING_KEY" "$PBUILDFOLDER"/*_result/*.changes


##### Import built packages into APT repository #####

stage "Importing packages into APT repository..." importing_packages

RELEASE_DIR=`bash "$BASE_DIR/internal/new_apt_repo_release.sh" "$PROJECT_NAME" "$PROJECT_APT_REPO_DIR"`
cd "$RELEASE_DIR"

for DIST in $DEBIAN_DISTROS; do
	for ARCH in $DEBIAN_ARCHS; do
		if [[ $ARCH == amd64 ]]; then
			pbase_name="$DIST"
		else
			pbase_name="$DIST-$ARCH"
		fi
		result_dir="$PBUILDFOLDER/${pbase_name}_result"
		reprepro --keepunusednewfiles --keepunreferencedfiles -Vb . includedeb $DIST $result_dir/*_$ARCH.deb
	done
	if ls $PBUILDFOLDER/${DIST}_result/*_all.deb &>/dev/null; then
		reprepro --keepunusednewfiles --keepunreferencedfiles -Vb . includedeb $DIST $PBUILDFOLDER/${DIST}_result/*_all.deb
		for F in $PBUILDFOLDER/${DIST}_result/*.dsc; do
			reprepro --keepunusednewfiles --keepunreferencedfiles -Vb . includedsc $DIST $F
		done
	elif ls $PBUILDFOLDER/${DIST}-i386_result/*_all.deb &>/dev/null; then
		reprepro --keepunusednewfiles --keepunreferencedfiles -Vb . includedeb $DIST $PBUILDFOLDER/${DIST}-i386_result/*_all.deb
		for F in $PBUILDFOLDER/${DIST}-i386_result/*.dsc; do
			reprepro --keepunusednewfiles --keepunreferencedfiles -Vb . includedsc $DIST $F
		done
	fi
done

bash "$BASE_DIR/internal/commit_apt_repo_release.sh" "$RELEASE_DIR"
