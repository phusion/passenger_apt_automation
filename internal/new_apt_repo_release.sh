set -e
set -o pipefail
shopt -s dotglob

PROJECT_NAME="$1"
APT_REPO_DIR="$2"

BASE_DIR=`dirname "$0"`
BASE_DIR=`cd "$BASE_DIR/.." && pwd`

# Create new release directory
release_name=`date +%Y%d%m-%H%M%S`
release_dir="$APT_REPO_DIR/releases/$release_name"
mkdir -p "$APT_REPO_DIR/releases"
# No -p. We want this to fail if someone else is concurrently creating.
mkdir "$release_dir"

# Copy over contents from current release
if [[ -e "$PROJECT_APT_REPO_DIR/current" ]]; then
	cp -dpR "$PROJECT_APT_REPO_DIR"/current/* "$release_dir"/
fi

# Setup APT repo configuration
mkdir -p "$release_dir/conf"
cp "$BASE_DIR/lib/apt_repo_conf/$PROJECT_NAME"/* "$release_dir/conf"

echo "$release_dir"
