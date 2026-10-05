#!/bin/bash
# Check the source tarballs in $DL against build/SHA256SUMS.txt, then unpack
# Freeciv as a git work tree with patches/freeciv applied
# (tools/fc-patches.sh checkout). The dependencies are unpacked by
# build/build-deps.sh as it builds them.
#
# Where to get the files (the build machine may not reach all of these):
#   freeciv-R3_2_6.tar.gz   https://codeload.github.com/freeciv/freeciv/tar.gz/refs/tags/R3_2_6
#   SDL2_image/ttf/mixer    https://github.com/libsdl-org/SDL_{image,ttf,mixer}/releases
#   curl-8.10.1.tar.xz      https://github.com/curl/curl/releases
#   sqlite3_3.45.1.orig     https://archive.ubuntu.com/ubuntu/pool/main/s/sqlite3/
#   riscos-mesa devkit      https://github.com/adyoull/riscos-mesa/releases (riscos-mesa-devkit-12f.tgz)
#   toolchain               https://github.com/adyoull/riscos-crossdev/releases (1.3: UnixLib 5.0.3.2)
#   only with UNIXLIB set (env.sh): gccsdk-64c6f81.tar.gz from
#     https://github.com/jhamby/riscos-gccsdk (commit 64c6f81), and the
#     release directory from https://github.com/adyoull/riscos-unixlib/releases
#   dejavu-fonts-ttf-2.37   (not used yet)
set -e
. "$(dirname "$0")/env.sh"
( cd "$DL" && sha256sum -c --quiet "$RCF_ROOT/build/SHA256SUMS.txt" ) || die "checksum mismatch in $DL"
echo "sources OK"
mkdir -p "$(dirname "$DEVKIT")"
[ -d "$DEVKIT" ] || tar xzf "$DL/$(basename "$DEVKIT").tgz" -C "$(dirname "$DEVKIT")"
[ -z "$AB_DEVKIT" ] || [ -d "$AB_DEVKIT" ] || tar xzf "$DL/$(basename "$AB_DEVKIT").tgz" -C "$(dirname "$AB_DEVKIT")"
"$RCF_ROOT/tools/fc-patches.sh" checkout
