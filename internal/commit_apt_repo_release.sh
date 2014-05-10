set -e
set -o pipefail

RELEASE_DIR="$1"
PROJECT_APT_REPO_DIR=`cd "$RELEASE_DIR/../.."; pwd`

BASE_DIR=`dirname "$0"`
BASE_DIR=`cd "$BASE_DIR/.." && pwd`

bash "$BASE_DIR/internal/sign_repo.sh" "$RELEASE_DIR"

# Update 'current' symlink atomically
rm -rf "$PROJECT_APT_REPO_DIR/current.new"
ln -sf "$RELEASE_DIR" "$PROJECT_APT_REPO_DIR/current.new"
if ! [[ -h "$PROJECT_APT_REPO_DIR/current" ]]; then
	rm -rf "$PROJECT_APT_REPO_DIR/current"
fi
mv -Tf "$PROJECT_APT_REPO_DIR/current.new" "$PROJECT_APT_REPO_DIR/current"

# Remove old releases: only keep most recent 3
releases=`ls -1d "$PROJECT_APT_REPO_DIR/releases"/* | sort`
releasecount=`wc -l <<<"$releases"`
to_keep=3
if [[ $releasecount -gt $to_keep ]]; then
	(( to_remove = $releasecount - $to_keep ))
	keep_releases=`head -n $to_remove <<<"$releases"`
	echo "$keep_releases" | tr '\n' '\0' | xargs -0 rm -rf
fi
