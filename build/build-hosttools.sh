#!/bin/bash
# Build tolua for the build machine. Freeciv's meson build runs tolua to
# generate Lua bindings, and in a cross build it looks for a native "tolua"
# on PATH instead of building one. We build it from Freeciv's own bundled
# Lua 5.4 + tolua 5.2 sources, so the generated code matches exactly.
set -e
. "$(dirname "$0")/env.sh"

FC=$SRC/freeciv-$FREECIV_TAG
[ -d "$FC" ] || die "unpack Freeciv first (build/fetch-sources.sh)"
out=$HOSTTOOLS/obj
rm -rf "$HOSTTOOLS"; mkdir -p "$out" "$HOSTTOOLS/bin"

L=$FC/dependencies/lua-5.4/src
T=$FC/dependencies/tolua-5.2
objs=()
for c in "$L"/*.c "$T"/src/lib/*.c "$T"/src/bin/tolua.c "$T"/src/bin/toluabind.c; do
  case $(basename "$c") in lua.c|luac.c) continue ;; esac
  o=$out/$(basename "$(dirname "$c")")_$(basename "$c" .c).o
  gcc -O2 -w -DLUA_USE_POSIX -I"$L" -I"$T/include" -I"$FC/dependencies" -c "$c" -o "$o"
  objs+=("$o")
done
gcc -o "$HOSTTOOLS/bin/tolua" "${objs[@]}" -lm
"$HOSTTOOLS/bin/tolua" -v 2>&1 | head -1
