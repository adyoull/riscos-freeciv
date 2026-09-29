# riscos-freeciv

A RISC OS port of [Freeciv](https://www.freeciv.org/) 3.2.6: the SDL2 client
and the server, so you can play against the computer on a RISC OS desktop,
or join a Freeciv server on the network.

Status: **first test build (3.2.6-riscos1test), not yet run on RISC OS.**

## How it works

| Part | What it is |
|---|---|
| Freeciv 3.2.6 | upstream tag `R3_2_6`, built with meson, plus the patches in `patches/freeciv` |
| SDL2 | the riscos-mesa devkit (20.3.5-9): SDL 2.26 with the RISC OS Wimp video driver and the SharedSoundBuffer sound driver |
| SDL2_image 2.6.3 | PNG only, decoded by its bundled stb_image |
| SDL2_ttf 2.20.2 | its bundled FreeType, no HarfBuzz |
| SDL2_mixer 2.6.3 | WAV and Ogg Vorbis (bundled stb_vorbis) |
| libcurl 8.10.1 | plain HTTP only (no TLS yet) |
| SQLite 3.45.1 | Freeciv's meson build links it into the server |
| Lua 5.4, tolua | bundled with Freeciv |
| Toolchain | riscos-crossdev 1.0 (GCCSDK GCC 10.2) with UnixLib 5.0.2 |

**Why not OpenGL/EGL?** Freeciv's SDL2 client draws everything in software
into one surface and then shows it with one texture upload and copy per
frame. On RISC OS the GL would be Mesa running in software too, so routing
that copy through GL would only add work. The devkit's SDL2 has no GL
renderer compiled in, so SDL uses its software renderer and the Wimp
framebuffer path (as OpenTTD does). The SDL library still contains the
riscos-mesa GL code (about 4MB of the client's 13MB of code), because the
devkit's SDL calls into Mesa; an SDL built without GL (like OpenTTD's) would
drop it.

### RISC OS changes (patches/freeciv)

1. **Build without ICU.** ICU is only used for three string functions in
   `utility/support.c`; they get UTF-8 versions of their own
   (`tests/no-icu` checks them against ICU).
2. **Platform.** `FREECIV_RISCOS`, single user, IPv4 only (the RISC OS
   Internet stack has no IPv6).
3. **Server in a TaskWindow; desktop kept running.** No `fork()`/`exec()`
   on RISC OS: "Start new game" runs `freeciv-server` with
   `Wimp_StartTask("TaskWindow ...")` and connects to it over loopback.
   Waits (`fc_usleep`, the main loop's `select`) go through `SDL_Delay`,
   which polls the Wimp, so the desktop and the server keep running. Heaps
   in dynamic areas; stdout/stderr to files named by variables.
4. **1024x768 window** by default.

## Building

See [BUILDING.md](BUILDING.md). In short, on x86-64 Linux:

```sh
build/prepare-toolchain.sh
build/fetch-sources.sh
build/build-deps.sh
build/build-hosttools.sh
build/build-freeciv.sh
build/package.sh          # -> dist/Freeciv-<version>.zip
```

## Licence

Freeciv is GPL version 2 or later, and so are the patches and scripts here.
The package's `docs.licences` has the licences of everything linked in.
`tools/rozip.py`, `tools/png2sprite.py`, `tools/check-stack-probes.py` and
`tools/check-unixlib.sh` come from riscos-warzone2100.

This port was made with the help of an AI assistant (Claude, by Anthropic).
