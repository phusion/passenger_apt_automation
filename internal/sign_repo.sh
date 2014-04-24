set -e

DIR="$1"
if [[ "$DIR" = "" ]]; then
	echo "Usage: ./sign_repo DIR"
	echo "(Re)sign an APT repostory"
	exit 1
fi

BASE_DIR=`dirname "$0"`
BASE_DIR=`cd "$BASE_DIR/.."; pwd`
source "$BASE_DIR/lib/bashlib"

load_general_config
use_dummy_gpg

cd "$DIR"
find . -name Release.gpg -print0 | xargs -0 rm -f
find . -name Release -exec gpg --batch --sign --detach-sign --armor --local-user $SIGNING_KEY --output \{\}.gpg \{\} \;
