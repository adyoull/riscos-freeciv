#!/bin/bash
# Set up the cross toolchain in $GCCSDK_ENV:
#   1. unpack riscos-crossdev's prebuilt toolchain 1.0 (GCC 10.2, UnixLib 5.0.1)
#   2. upgrade UnixLib to the 5.0.2 release (library + the three headers that
#      changed: sys/stat.h, sys/mman.h, unistd.h - large-file support)
#   3. delete libtool .la files (and the shared libraries, see 4): they hold the build machine's absolute paths,
#      which break libtool links once the toolchain has moved.
#
# Needs in $DL: riscos-crossdev-toolchain-1.0-x86_64-linux.tar.xz,
# gccsdk-64c6f81.tar.gz, unixlib-5.0.2/{libunixlib.a,unixlib-riscos.diff}.
set -e
. "$(dirname "$0")/env.sh"

TC=riscos-crossdev-toolchain-1.0-x86_64-linux
parent=$(dirname "$GCCSDK_ENV")
mkdir -p "$parent"
rm -rf "$parent/$TC"
tar xJf "$DL/$TC.tar.xz" -C "$parent"
ln -sfn "$parent/$TC" "$GCCSDK_ENV"

T=$GCCSDK_ENV/arm-riscos-gnueabihf
tmp=$(mktemp -d)
tar xzf "$DL/gccsdk-64c6f81.tar.gz" -C "$tmp"
patch -d "$tmp"/riscos-gccsdk-64c6f81 -p1 -s < "$DL/unixlib-5.0.2/unixlib-riscos.diff"
inc=$tmp/riscos-gccsdk-64c6f81/gcc4/recipe/files/gcc/libunixlib/include
( cd "$inc" && find . -type f ) | while read -r f; do
  if ! cmp -s "$inc/$f" "$T/include/$f"; then
    echo "  UnixLib 5.0.2 header: $f"
    cp "$inc/$f" "$T/include/$f"
  fi
done
cp "$DL/unixlib-5.0.2/libunixlib.a" "$T/lib/libunixlib.a"
rm -rf "$tmp"

find -L "$GCCSDK_ENV/" -name '*.la' -delete
# 4. static only: meson resolves -lstdc++ to a full path and would pick the
#    .so, which a -static link rejects. Nothing here links shared.
find -L "$T/lib" -maxdepth 1 -name '*.so*' -delete
echo "toolchain ready: $($TARGET-gcc --version | head -1)"
