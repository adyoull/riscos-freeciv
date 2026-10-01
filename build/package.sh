#!/bin/bash
# Make the !Freeciv application and its zip.
#   build/package.sh            -> dist/!Freeciv, dist/Freeciv-$VERSION.zip
# Needs a finished build (build/build-freeciv.sh), then installs Freeciv's
# data with meson into a staging directory and copies what the SDL2 client
# and the server use.
set -e
. "$(dirname "$0")/env.sh"

VERSION=${VERSION:-$FREECIV_VERSION-riscos10test}
FC=$SRC/freeciv-$FREECIV_TAG
B=$FC/build-ro
DIST=${DIST:-$RCF_ROOT/dist}
APP=$DIST/'!Freeciv'
SRVAPP=$DIST/'!CivServer'
INST=$STAGE/install

export PATH="$HOSTTOOLS/bin:$PATH"
[ -x "$B/freeciv-sdl2" ] || die "build first (build/build-freeciv.sh)"

# Everything meson would install (data, docs); needs the full build.
ninja -C "$B" >/dev/null
rm -rf "$INST"
DESTDIR=$INST meson install -C "$B" --no-rebuild >/dev/null
share=$INST/freeciv/share

rm -rf "$APP" "$SRVAPP"
mkdir -p "$APP/docs" "$DIST" "$SRVAPP"
cp "$RCF_ROOT"/app/'!Freeciv'/* "$APP/"
# !CivServer: starts the server (inside !Freeciv) in a TaskWindow by hand.
cp "$RCF_ROOT"/app/'!CivServer'/* "$SRVAPP/"

# Programs: ELF -> AIF (Absolute), stripped. -e: EABI (arm-riscos-gnueabihf) ELF.
# freeciv-sdl2-10h (test builds only): the A/B client from build-freeciv.sh.
progs="freeciv-sdl2 freeciv-server"
[ -x "$B/freeciv-sdl2-10h" ] && progs="$progs freeciv-sdl2-10h"
for p in $progs; do
  $TARGET-strip -o "$STAGE/$p.stripped" "$B/$p"
  elf2aif -e "$STAGE/$p.stripped" "$APP/$p,ff8" >/dev/null
done

# PThreadTicker module (riscos-unixlib release, $UNIXLIB).
ticker=$(ls "$DL/$UNIXLIB"/PThreadTicker-*.zip | tail -1)
unzip -p "$ticker" 'PThreadTicker/!System/310/Modules/PThrTicker' > "$APP/PThrTicker,ffa" 2>/dev/null \
  || die "PThrTicker not found in $ticker"
[ -s "$APP/PThrTicker,ffa" ] || die "empty PThrTicker"

# Data. Left out: the CJK fonts (only used with Chinese, Japanese or
# Korean translations, which this build doesn't have; 25MB) and the
# gui-sdl3/other clients' files, which meson doesn't install anyway.
cp -r "$share/freeciv" "$APP/data"
( cd "$APP/data/themes/gui-sdl2/human"
  rm -f fireflysung.ttf sazanami-gothic.ttf UnDotum.ttf \
        COPYING.fireflysung COPYING.sazanami COPYING.UnDotum )

# Docs and licences.
cp "$FC/COPYING" "$APP/docs/COPYING,fff"
cp "$FC/AUTHORS" "$APP/docs/AUTHORS,fff"
cp "$FC/NEWS-3.2" "$APP/docs/NEWS,fff"
cp "$FC/doc/README.sound" "$APP/docs/README-sound,fff" 2>/dev/null || true
mkdir -p "$APP/docs/licences"
lic=$APP/docs/licences
cp "$DEVKIT/LICENCES.txt" "$lic/riscos-mesa-devkit,fff"      # SDL2, Mesa, zlib, UnixLib
cp "$SRC/SDL2_image-2.6.3/LICENSE.txt" "$lic/SDL2_image,fff"
cp "$SRC/SDL2_ttf-2.20.2/LICENSE.txt" "$lic/SDL2_ttf,fff"
cp "$SRC/SDL2_ttf-2.20.2/external/freetype/docs/FTL.TXT" "$lic/FreeType,fff"
cp "$SRC/SDL2_mixer-2.6.3/LICENSE.txt" "$lic/SDL2_mixer,fff"
cp "$SRC/curl-8.10.1/COPYING" "$lic/curl,fff"
printf 'SQLite 3.45.1 is in the public domain: https://www.sqlite.org/copyright.html\n' > "$lic/SQLite,fff"
cp "$FC/dependencies/lua-5.4/COPYRIGHT" "$lic/Lua,fff" 2>/dev/null \
  || sed -n '/Copyright (C) 1994/,/SOFTWARE\./p' "$FC/dependencies/lua-5.4/src/lua.h" > "$lic/Lua,fff"
cp "$FC/dependencies/tolua-5.2/COPYRIGHT" "$lic/tolua,fff" 2>/dev/null || true
cp "$RCF_ROOT/riscos/PThreadTicker-Licence" "$lic/PThreadTicker,fff"

# GPL corresponding source: the patches applied to Freeciv 3.2.6.
mkdir -p "$APP/docs/patches"
for p in "$RCF_ROOT"/patches/freeciv/*.patch; do
  cp "$p" "$APP/docs/patches/$(basename "$p" .patch | cut -c1-40),fff"
done

# Icon sprites from Freeciv's own client icon.
python3 "$RCF_ROOT/tools/png2sprite.py" "$FC/data/freeciv-client.png" "$APP/!Sprites,ff9" \
  '!freeciv:34x34' 'sm!freeciv:17x17'
python3 "$RCF_ROOT/tools/png2sprite.py" "$FC/data/freeciv-server.png" "$SRVAPP/!Sprites,ff9" \
  '!civserver:34x34' 'sm!civserver:17x17'

echo "$VERSION" > "$APP/docs/Version,fff"

( cd "$DIST" && rm -f "Freeciv-$VERSION.zip" && python3 "$RCF_ROOT/tools/rozip.py" "Freeciv-$VERSION.zip" '!Freeciv' '!CivServer' )
ls -la "$DIST/Freeciv-$VERSION.zip"
md5sum "$DIST/Freeciv-$VERSION.zip" "$APP"/*,ff8
