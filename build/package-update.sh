#!/bin/bash
# Make a small update zip: only the files in !Freeciv that changed since
# an earlier build, so a tester who has that build can be sent an update
# by email (the full zip is about 28MB).
#   build/package-update.sh <from-version> <file>...
#   e.g. build/package-update.sh riscos10test freeciv-sdl2,ff8 '!Run,feb' '!Help,fff'
# The files are taken from dist/!Freeciv (run build/package.sh first). The
# new version file and the patch files are always included.
set -e
. "$(dirname "$0")/env.sh"

FROM=$1; shift
[ -n "$FROM" ] && [ $# -gt 0 ] || die "usage: $0 <from-version> <file in !Freeciv>..."
DIST=${DIST:-$RCF_ROOT/dist}
APP=$DIST/'!Freeciv'
VERSION=$(cat "$APP/docs/Version,fff")
OUT=$DIST/Freeciv-$VERSION-update-from-$FROM.zip
TMP=$(mktemp -d)
U=$TMP/'!Freeciv'

mkdir -p "$U/docs/patches"
for f in "$@"; do
  [ -e "$APP/$f" ] || die "no $APP/$f"
  mkdir -p "$(dirname "$U/$f")"
  cp -p "$APP/$f" "$U/$f"
done
cp -p "$APP/docs/Version,fff" "$U/docs/"
cp -p "$APP"/docs/patches/* "$U/docs/patches/"

cat > "$TMP/ReadMe,fff" <<EOF
Freeciv $VERSION: update for Freeciv $FROM
$(printf '%s' "Freeciv $VERSION: update for Freeciv $FROM" | tr -c '' '=')

This zip only holds the files that changed since $FROM. It isn't a
complete copy of the game.

1. Quit Freeciv, and the "Freeciv server" TaskWindow if it's running.
2. Open your existing !Freeciv (Shift+double-click it).
3. Copy the contents of the !Freeciv directory in this zip into it,
   replacing the files that are already there.

Files in this update:
$(cd "$U" && find . -type f | sed 's|^\./|  !Freeciv.|; s|,[0-9a-f]\{3\}$||; s|/|.|g' | sort)
EOF

( cd "$TMP" && python3 "$RCF_ROOT/tools/rozip.py" "$OUT" 'ReadMe,fff' '!Freeciv' )
rm -rf "$TMP"
ls -la "$OUT"
md5sum "$OUT"
