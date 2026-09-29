#!/bin/bash
# Edit the Freeciv patch series as git commits.
#   tools/fc-patches.sh checkout   $SRC/freeciv-<tag>: pristine source as a git
#                                  repo (tag "pristine") + patches/freeciv applied
#                                  with git am, one commit per patch
#   tools/fc-patches.sh export     commits since "pristine" -> patches/freeciv
#   tools/fc-patches.sh check      the series applied to pristine source
#                                  reproduces the work tree's HEAD exactly
# Edit with ordinary git (commit, rebase -i, commit --fixup + autosquash),
# then export. Build directories (build-ro) are ignored by git (.git/info/exclude).
set -e
. "$(dirname "$0")/../build/env.sh"
FC=$SRC/freeciv-$FREECIV_TAG
P=$RCF_ROOT/patches/freeciv

pristine_tree() {   # $1 = dir
  rm -rf "$1"; mkdir -p "$(dirname "$1")"
  tar xzf "$DL/freeciv-$FREECIV_TAG.tar.gz" -C "$(dirname "$1")"
  [ "$(dirname "$1")/freeciv-$FREECIV_TAG" = "$1" ] || mv "$(dirname "$1")/freeciv-$FREECIV_TAG" "$1"
  ( cd "$1"; git init -q; echo "build-*/" >> .git/info/exclude
    git add -A; git -c user.name="Andrew Youll" -c user.email=adyoull@users.noreply.github.com \
      commit -qm "Freeciv $FREECIV_VERSION (tag $FREECIV_TAG, pristine)"; git tag pristine )
}

case $1 in
  checkout)
    [ -d "$FC/.git" ] && [ -n "$(cd "$FC" && git status --porcelain)" ] && die "$FC has uncommitted changes"
    keep=""; [ -d "$FC/build-ro" ] && { keep=$(mktemp -d); mv "$FC/build-ro" "$keep/"; }
    pristine_tree "$FC"
    [ -n "$keep" ] && mv "$keep/build-ro" "$FC/" && rmdir "$keep"
    ls "$P"/*.patch >/dev/null 2>&1 && ( cd "$FC"; git -c user.name="Andrew Youll" \
      -c user.email=adyoull@users.noreply.github.com am -q --committer-date-is-author-date "$P"/*.patch )
    ( cd "$FC"; git log --oneline pristine..HEAD )
    ;;
  export)
    mkdir -p "$P"; rm -f "$P"/*.patch
    ( cd "$FC"; git format-patch -q --zero-commit --no-numbered --no-signature -o "$P" pristine..HEAD )
    ls "$P"
    ;;
  check)
    t=$(mktemp -d); pristine_tree "$t/fc"
    ( cd "$t/fc"; git -c user.name=x -c user.email=x am -q "$P"/*.patch )
    a=$(cd "$t/fc" && git rev-parse HEAD^{tree}); b=$(cd "$FC" && git rev-parse HEAD^{tree})
    rm -rf "$t"
    [ "$a" = "$b" ] && echo "OK: patches/freeciv reproduces the work tree ($a)" \
      || die "patches/freeciv gives tree $a, work tree HEAD is $b"
    ;;
  *) echo "usage: $0 checkout|export|check" >&2; exit 2 ;;
esac
