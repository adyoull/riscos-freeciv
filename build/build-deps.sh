#!/bin/bash
# Cross-build Freeciv's library dependencies as static libraries into $STAGE.
#   build/build-deps.sh [step...]      steps: image ttf mixer curl sqlite (default: all)
#
# SDL2 itself and zlib come from the riscos-mesa devkit (pkg-config finds
# them through $DEVKIT/lib/pkgconfig). Each library is unpacked fresh from
# $DL, so a step can be re-run on its own.
set -e
. "$(dirname "$0")/env.sh"

mkdir -p "$SRC" "$STAGE/lib/pkgconfig" "$STAGE/include"

# unpack <tarball> <dir>: fresh copy in $SRC, plus patches/<dir-without-version>/*
unpack() {
  local tarball=$1 dir=$2 name=${3:-}
  rm -rf "$SRC/$dir"
  tar xf "$DL/$tarball" -C "$SRC"
  if [ -n "$name" ] && [ -d "$RCF_ROOT/patches/$name" ]; then
    for p in "$RCF_ROOT"/patches/$name/*.patch; do
      [ -e "$p" ] || continue
      echo "  patch $(basename "$p")"
      patch -d "$SRC/$dir" -p1 -s < "$p"
    done
  fi
}

# SDL2_image: PNG only (what Freeciv's tilesets and themes use), decoded by
# the bundled stb_image, so no libpng is needed.
step_image() {
  unpack SDL2_image-2.6.3.tar.gz SDL2_image-2.6.3 sdl2_image
  ( cd "$SRC/SDL2_image-2.6.3"; cross_env
    ro_configure --disable-sdltest --enable-stb-image \
      --disable-avif --disable-jpg --disable-jxl --disable-tif --disable-webp \
      --disable-bmp --disable-gif --disable-lbm --disable-pcx --disable-pnm \
      --disable-qoi --disable-svg --disable-tga --disable-xcf --disable-xpm \
      --disable-xv --enable-png --disable-png-shared
    make -j"$JOBS" && make install )
}

# SDL2_ttf: its bundled FreeType, no HarfBuzz (Freeciv only renders simple
# left-to-right text through TTF_RenderUTF8_*).
step_ttf() {
  unpack SDL2_ttf-2.20.2.tar.gz SDL2_ttf-2.20.2 sdl2_ttf
  ( cd "$SRC/SDL2_ttf-2.20.2"; cross_env
    # FreeType's gzip support would otherwise compile its own copy of zlib,
    # which clashes with the devkit's libz.a at link time.
    CFLAGS="$CFLAGS -DFT_CONFIG_OPTION_SYSTEM_ZLIB"
    ro_configure --disable-sdltest --enable-freetype-builtin --disable-harfbuzz
    make -j"$JOBS" && make install )
}

# SDL2_mixer: WAV and Ogg Vorbis (bundled stb_vorbis), which is what
# Freeciv's stdsounds and music packs use. Everything else off.
step_mixer() {
  unpack SDL2_mixer-2.6.3.tar.gz SDL2_mixer-2.6.3 sdl2_mixer
  ( cd "$SRC/SDL2_mixer-2.6.3"; cross_env
    ro_configure --disable-sdltest --enable-music-wave --enable-music-ogg \
      --enable-music-ogg-stb --disable-music-ogg-shared \
      --disable-music-cmd --disable-music-mod --disable-music-midi \
      --disable-music-flac --disable-music-mp3 --disable-music-opus
    make -j"$JOBS" && make install )
}

# libcurl: plain HTTP only (metaserver list, modpack index). No TLS yet, so
# https:// URLs fail with an error message rather than crash.
step_curl() {
  unpack curl-8.10.1.tar.xz curl-8.10.1 curl
  ( cd "$SRC/curl-8.10.1"; cross_env
    ro_configure --without-ssl --without-zlib --without-brotli --without-zstd \
      --without-libpsl --without-libidn2 --without-nghttp2 --without-libssh2 \
      --without-librtmp --disable-ldap --disable-ldaps --disable-rtsp \
      --disable-dict --disable-telnet --disable-tftp --disable-pop3 \
      --disable-imap --disable-smb --disable-smtp --disable-gopher --disable-mqtt \
      --disable-ftp --disable-file --disable-ipv6 --disable-threaded-resolver \
      --disable-unix-sockets --disable-ntlm --disable-docs --disable-manual \
      --disable-libcurl-option --disable-verbose --without-ca-bundle \
      --without-ca-path --disable-alt-svc --disable-hsts \
      --disable-websockets --enable-mime
    make -C lib -j"$JOBS" && make -C lib install && make -C include install \
      && make install-pkgconfigDATA )
}

# SQLite: only needed because Freeciv's meson build links LuaSQL/fcdb into
# the server unconditionally. Built from the amalgamation, single-threaded,
# no WAL (needs shared memory) and no dynamic extensions.
step_sqlite() {
  unpack sqlite3_3.45.1.orig.tar.xz sqlite3-3.45.1 sqlite
  ( cd "$SRC/sqlite3-3.45.1"
    mkdir -p bld && cd bld
    ../configure --disable-tcl >/dev/null   # host configure, only to make sqlite3.c
    make sqlite3.c >/dev/null
    cross_env
    $CC $CFLAGS -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_WAL -DSQLITE_OMIT_LOAD_EXTENSION \
        -DSQLITE_OMIT_SHARED_CACHE -DSQLITE_DEFAULT_MEMSTATUS=0 \
        -c sqlite3.c -o sqlite3.o
    $AR rcs "$STAGE/lib/libsqlite3.a" sqlite3.o
    cp sqlite3.h sqlite3ext.h "$STAGE/include/"
    cat > "$STAGE/lib/pkgconfig/sqlite3.pc" <<EOF
prefix=$STAGE
libdir=\${prefix}/lib
includedir=\${prefix}/include
Name: SQLite
Description: SQL database engine
Version: 3.45.1
Libs: -L\${libdir} -lsqlite3
Cflags: -I\${includedir}
EOF
  )
}

steps=${*:-image ttf mixer curl sqlite}
for s in $steps; do
  echo "=== $s"
  step_$s > "$STAGE/build-$s.log" 2>&1 || { tail -40 "$STAGE/build-$s.log"; die "step $s failed (log: $STAGE/build-$s.log)"; }
done
echo "deps done: $(ls "$STAGE"/lib/*.a | xargs -n1 basename | tr '\n' ' ')"
