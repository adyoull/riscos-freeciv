#!/bin/bash
# Cross-build Freeciv (SDL2 client + server) with meson.
#   build/build-freeciv.sh            configure (first time) and build
#   build/build-freeciv.sh reconfigure
# Output: $SRC/freeciv-$FREECIV_TAG/build-ro/{freeciv-sdl2,freeciv-server}
set -e
. "$(dirname "$0")/env.sh"

FC=$SRC/freeciv-$FREECIV_TAG
B=$FC/build-ro
[ -x "$HOSTTOOLS/bin/tolua" ] || die "run build/build-hosttools.sh first"
export PATH="$HOSTTOOLS/bin:$PATH"

# zlib comes from the devkit; Freeciv's meson looks for it with
# find_library() in cross_lib_path, so give it a copy in $STAGE.
cp "$DEVKIT/lib/libz.a" "$STAGE/lib/"
cp "$DEVKIT/include/zlib.h" "$DEVKIT/include/zconf.h" "$STAGE/include/"

# meson's dependency('threads') adds -pthread, which GCCSDK's GCC rejects
# (UnixLib's pthreads are always linked in). Small wrappers drop it.
for t in gcc g++; do
  printf '#!/bin/sh\nfor a; do shift; [ "$a" = -pthread ] || set -- "$@" "$a"; done\nexec %s "$@"\n' \
    "$TARGET-$t" > "$HOSTTOOLS/bin/ro-$t"
  chmod +x "$HOSTTOOLS/bin/ro-$t"
done

cross=$STAGE/riscos-cross.ini
flags=$(printf "'%s', " $RO_CFLAGS)
cat > "$cross" <<EOF
[binaries]
c = '$HOSTTOOLS/bin/ro-gcc'
cpp = '$HOSTTOOLS/bin/ro-g++'
ar = '$TARGET-ar'
strip = '$TARGET-strip'
pkg-config = 'pkg-config'

[host_machine]
system = 'riscos'
cpu_family = 'arm'
cpu = 'armv7'
endian = 'little'

[properties]
cross_inc_path = '$STAGE/include'
cross_lib_path = '$STAGE/lib'

[built-in options]
c_args = [${flags}'-I$STAGE/include']
cpp_args = [${flags}'-I$STAGE/include']
c_link_args = ['-static', '-L$STAGE/lib']
cpp_link_args = ['-static', '-L$STAGE/lib']
EOF

if [ "$1" = reconfigure ] || [ ! -f "$B/build.ninja" ]; then
  rm -rf "$B"
  meson setup "$B" "$FC" --cross-file "$cross" \
    --prefix=/freeciv --buildtype=plain --default-library=static \
    -Dclients=sdl2 -Dfcmp=[] -Dtools=[] -Dserver=enabled \
    -Daudio=sdl2 -Dnls=false -Dreadline=false -Dsyslua=false \
    -Dmwand=false -Djson-protocol=false -Dsvgflags=false \
    -Dproject-definition="$RCF_ROOT/build/riscos.fcproj"
fi
ninja -C "$B" -j"$JOBS" freeciv-sdl2 freeciv-server

# A/B test client: the same objects, linked with $AB_DEVKIT's libraries
# (only the SDL library differs), as freeciv-sdl2-10h.
rm -f "$B/freeciv-sdl2-10h"
if [ -n "$AB_DEVKIT" ]; then
  [ -d "$AB_DEVKIT" ] || die "AB_DEVKIT $AB_DEVKIT not unpacked"
  link=$(ninja -C "$B" -t commands freeciv-sdl2 | tail -1)
  case "$link" in *"$DEVKIT/lib"*) ;; *) die "can't find the devkit in the link line" ;; esac
  link=${link//"$DEVKIT"/"$AB_DEVKIT"}
  link=${link//"-o freeciv-sdl2 "/"-o freeciv-sdl2-10h "}
  ( cd "$B" && eval "$link" )
fi
ls -la "$B"/freeciv-sdl2 "$B"/freeciv-sdl2-10h "$B"/freeciv-server 2>/dev/null || true
