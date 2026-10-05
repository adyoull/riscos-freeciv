# Building riscos-freeciv

Host: x86-64 Linux (tested on Ubuntu 24.04). About 10 minutes on 2 cores.

## Packages

```sh
apt-get install autoconf automake libtool pkg-config gettext autopoint \
  meson ninja-build python3 python3-pil tcl gawk zip unzip
```

`tests/no-icu` also needs `gcc` and `libicu-dev`.

## Sources

Put these in `dl/` (checked against `build/SHA256SUMS.txt`); where to get
each is listed at the top of `build/fetch-sources.sh`:

- `freeciv-R3_2_6.tar.gz` (GitHub tag archive), `SDL2_image-2.6.3.tar.gz`,
  `SDL2_ttf-2.20.2.tar.gz`, `SDL2_mixer-2.6.3.tar.gz`, `curl-8.10.1.tar.xz`,
  `sqlite3_3.45.1.orig.tar.xz`
- `riscos-mesa-devkit-12f.tgz` (`DEVKIT` in build/env.sh)
- `riscos-crossdev-toolchain-1.3-x86_64-linux.tar.xz` (`CROSSDEV`): GCC 10.2
  with UnixLib 5.0.3.2 and PThreadTicker 0.03; it links static programs only
- only to try another UnixLib release (`UNIXLIB` in build/env.sh):
  `gccsdk-64c6f81.tar.gz` and the release's files in `dl/<UNIXLIB>/`

## Steps

| Script | Does |
|---|---|
| `build/prepare-toolchain.sh` | unpacks the toolchain into `/opt/riscos` (`GCCSDK_ENV`), installs `UNIXLIB` over the toolchain's UnixLib if set, deletes `.la` and `.so` files (they carry the build machine's paths / make meson link shared) |
| `build/fetch-sources.sh` | checks checksums, unpacks the devkit into `devkit/`, and Freeciv into `src/freeciv-R3_2_6` as a git work tree with the patches applied |
| `build/build-deps.sh [image ttf mixer curl sqlite]` | cross-builds the static libraries into `stage/` (logs `stage/build-*.log`) |
| `build/build-hosttools.sh` | builds `tolua` for the build machine (meson needs a native one in cross builds) |
| `build/build-freeciv.sh [reconfigure]` | meson cross build (`build-ro/`), cross file in `stage/riscos-cross.ini`; with `AB_DEVKIT` set, also links the same client with that devkit's libraries as `freeciv-sdl2-10h`, for speed comparisons (off by default) |
| `build/package.sh` | `dist/!Freeciv` and `dist/Freeciv-<VERSION>.zip` (RISC OS filetypes in the zip's extra fields) |
| `build/package-update.sh <from> <files>` | a small zip with only the `!Freeciv` files changed since an earlier build (plus Version and the patches), for testers who already have it; the full zip is too big to email |

Settings are in `build/env.sh` (paths, `RO_CFLAGS`). Compiler flags:
`-O2 -mfpu=vfpv3 -mfloat-abi=hard -mtune=cortex-a72 -fstack-clash-protection`
(runs on any ARMv7 RISC OS machine, as riscos-mesa 20.3.5-8+).

`build/riscos.fcproj` is Freeciv's project definition: it puts user files
in `/<Choices$Write>/Freeciv` (a UnixLib path; UnixLib expands the
variable when a file is opened).

## Editing the Freeciv patches

```sh
tools/fc-patches.sh checkout   # work tree = pristine + patches, one commit each
# edit, git commit (or commit --fixup + rebase -i --autosquash pristine)
tools/fc-patches.sh export     # commits -> patches/freeciv (format-patch --zero-commit)
tools/fc-patches.sh check      # the series reproduces the work tree exactly
```

Guard RISC OS code with `#ifdef FREECIV_RISCOS` (from `freeciv_config.h`).

## Checks

- `tools/check-stack-probes.py <elf>`: every function with a frame of 4 KB
  or more must probe the stack (Freeciv has ~430 such functions; 0 unprobed).
- `tools/check-unixlib.sh <elf>`: UnixLib's pthread ticker block is
  consistent (640 bytes from UnixLib 5.0.3.1; 472 before).
- `tests/no-icu/run.sh`: the ICU-free string functions agree with ICU.
- Unaligned access: Freeciv builds with `-Wcast-align`, which on this
  target (no unaligned access) warns about every risky cast; the only
  warnings are Lua's GC object casts (malloc'd, aligned).

## RISC OS rules for this port

- No `fork`/`exec`/`system`/`popen`: UnixLib runs children inside the
  program's own memory. Start other programs with `Wimp_StartTask`.
- Never wait without polling the Wimp in a desktop program: use
  `fc_usleep()` (hooked to `SDL_Delay`) or `SDL_Delay()`. UnixLib's
  `nanosleep()` and `select()` with a timeout busy-wait.
- Nothing may print to stdout/stderr in the desktop (it opens a command
  window): output goes to the files named by `Freeciv$Output` and
  `FreecivServer$Output`.
- Full screen: with riscos-mesa devkit 10h, SDL's
  `SDL_WINDOW_FULLSCREEN_DESKTOP` is a borderless, screen-size Wimp window
  that keeps polling, so the server's TaskWindow keeps running. With
  devkit 9 and earlier, full screen stopped the desktop. Patch 0007
  makes the client follow `SDL_WINDOWEVENT_RESIZED` (sent after a mode
  change) and take the full-screen size from the window.
- Blits: from devkit 10i, SDL's ARM NEON/SIMD routines blend images
  with alpha, but only onto surfaces **without** alpha, and only when the
  image has the same colour order. Patch 0008 makes the map's backing
  store alpha-free and converts every loaded image to the screen buffer's
  format. The log line "RISC OS: program ...; pixel formats: ..." shows
  the formats in use.
- A/B builds (`AB_DEVKIT`, off by default) add a `freeciv-sdl2-10h` client
  linked with another devkit's SDL. To run it, set `Freeciv$Prog` to its
  name in !Run, and compare the "busy" and "map drawing" log figures.
