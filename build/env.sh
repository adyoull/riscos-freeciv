# Shared settings for the riscos-freeciv build scripts. Source it:
#   . build/env.sh
#
# Everything can be overridden from the environment before sourcing.
#   GCCSDK_ENV  cross toolchain (riscos-crossdev 1.0 + UnixLib 5.0.2 headers/lib)
#   DEVKIT      unpacked riscos-mesa devkit (SDL2 with the RISC OS driver, zlib)
#   DL          source tarballs (see build/SHA256SUMS.txt)
#   SRC         where sources are unpacked and patched
#   STAGE       cross-built libraries and headers (--prefix for the deps)
#   HOSTTOOLS   programs built for the build machine (tolua)
#   JOBS        make/ninja parallelism

RCF_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

: "${GCCSDK_ENV:=/opt/riscos/env}"
: "${DEVKIT:=$RCF_ROOT/devkit/riscos-mesa-devkit-10i}"
# Test builds only: a second client linked with this devkit's SDL, to
# compare speeds (freeciv-sdl2-10h). Set AB_DEVKIT= (empty) to skip it.
: "${AB_DEVKIT=$RCF_ROOT/devkit/riscos-mesa-devkit-20.3.5-10h}"
: "${DL:=$RCF_ROOT/dl}"
: "${SRC:=$RCF_ROOT/src}"
: "${STAGE:=$RCF_ROOT/stage}"
: "${HOSTTOOLS:=$RCF_ROOT/hosttools}"
: "${JOBS:=$(nproc)}"

FREECIV_VERSION=3.2.6
FREECIV_TAG=R3_2_6

TARGET=arm-riscos-gnueabihf
BUILD=$(gcc -dumpmachine)

# Autotools/libtool/meson cannot cope with spaces in these paths.
for v in GCCSDK_ENV DEVKIT SRC STAGE HOSTTOOLS; do
  case ${!v} in *" "*) echo "env.sh: $v contains a space: ${!v}" >&2; return 1 2>/dev/null || exit 1 ;; esac
done

export PATH="$GCCSDK_ENV/bin:$PATH"

# VFPv3 without NEON: runs on every ARMv7 RISC OS machine (Cortex-A8 upwards),
# the same choice riscos-mesa made for 20.3.5-8. Tuned for the Pi 4.
# -fstack-clash-protection: ARMEABISupport maps the stack a page at a time;
# frames over 4 KB must probe it (see tools/check-stack-probes.py).
RO_CFLAGS="-O2 -mfpu=vfpv3 -mfloat-abi=hard -mtune=cortex-a72 -fstack-clash-protection"

export PKG_CONFIG_LIBDIR="$STAGE/lib/pkgconfig:$DEVKIT/lib/pkgconfig"
export PKG_CONFIG_PATH=
export PKG_CONFIG_SYSROOT_DIR=

die() { echo "error: $*" >&2; exit 1; }

# Cross-compiler environment for autotools builds. Call it in a subshell.
cross_env() {
  export CC=$TARGET-gcc CXX=$TARGET-g++ AR=$TARGET-ar RANLIB=$TARGET-ranlib \
         STRIP=$TARGET-strip NM=$TARGET-nm LD=$TARGET-ld
  export CFLAGS="$RO_CFLAGS -I$STAGE/include"
  export CXXFLAGS="$RO_CFLAGS -I$STAGE/include"
  export CPPFLAGS="-I$STAGE/include"
  export LDFLAGS="-L$STAGE/lib -static"
}

# Standard configure line for a static library dependency.
ro_configure() {
  ./configure --host=$TARGET --build=$BUILD --prefix="$STAGE" \
    --disable-shared --enable-static "$@"
}
