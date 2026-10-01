# riscos-freeciv

A RISC OS port of [Freeciv](https://www.freeciv.org/) 3.2.6: the SDL2 client
and the server, so you can play against the computer on a RISC OS desktop,
or join a Freeciv server on the network.

Status: **test builds.** riscos1test ran on a Pi but couldn't start its
server; riscos2test adds !CivServer (start the server by hand, as in the
earlier RISC OS ports) and a simpler automatic start; riscos3test makes
screen updates faster; riscos4test makes full screen a "full window" that
keeps the desktop running; riscos5test draws the map so that SDL's ARM
(NEON) blitters can be used; riscos6test stops the client hanging on quit;
riscos7test makes the log files work and quitting quick;
riscos8test is relinked with UnixLib 5.0.3, riscos9test with
UnixLib 5.0.3.1-rc8.

## How it works

| Part | What it is |
|---|---|
| Freeciv 3.2.6 | upstream tag `R3_2_6`, built with meson, plus the patches in `patches/freeciv` |
| SDL2 | the riscos-mesa devkit (10i): SDL 2.26 with the RISC OS Wimp video driver and the SharedSoundBuffer sound driver |
| SDL2_image 2.6.3 | PNG only, decoded by its bundled stb_image |
| SDL2_ttf 2.20.2 | its bundled FreeType, no HarfBuzz |
| SDL2_mixer 2.6.3 | WAV and Ogg Vorbis (bundled stb_vorbis) |
| libcurl 8.10.1 | plain HTTP only (no TLS yet) |
| SQLite 3.45.1 | Freeciv's meson build links it into the server |
| Lua 5.4, tolua | bundled with Freeciv |
| Toolchain | riscos-crossdev 1.0 (GCCSDK GCC 10.2) with UnixLib 5.0.3.1-rc8 |

**Why not OpenGL/EGL?** Freeciv's SDL2 client draws everything in software
into one surface. On RISC OS any GL is Mesa running in software too, so
drawing through GL would only add work. riscos-mesa's EGL speed-ups (a
scaled render size, hardware overlays; SDL's opt-in EGL path from devkit
10a) apply to GL windows, and would at best replace the final plot. What
costs most is how much is copied and plotted per update, so on RISC OS the
client copies only the changed parts into SDL's window framebuffer (patch
0006), which the riscos-mesa SDL driver plots with a Wimp_UpdateWindow per
area. The SDL library still contains the riscos-mesa GL code (about 4MB of
the client's 13MB of code), because the devkit's SDL calls into Mesa; an
SDL built without GL (like OpenTTD's) would drop it.

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
5. **Server started by hand.** If a server answers on 127.0.0.1:5556
   (started with `!CivServer`), "Start new game" plays on it. The automatic
   start finds the program through `Freeciv$Path` and binds to 127.0.0.1.
6. **SDL2 client:** only the changed parts of the screen are copied and
   plotted (no texture/renderer), mouse wheel for the map and dialog
   lists, resolution changes at once.
7. **Window size changes.** The client follows size changes from outside
   (a mode change in full screen) and takes the full-screen size from the
   window, which the riscos-mesa driver makes a borderless, screen-size
   Wimp window.
8. **Map without alpha.** The map is drawn onto a surface without alpha,
   and all images get the screen buffer's pixel format, so SDL can blend
   the tiles and units with its ARM NEON/SIMD routines (riscos-mesa
   devkit 10i). The log also times the map drawing.
9. **Quitting.** The wait for the quit sound gives up after 5 seconds
   (a stalled sound output kept the client from exiting), and a quit
   request is never lost in a dialog's own event loop. On RISC OS,
   sounds still playing at quit are stopped rather than waited for.
10. **Log files.** Output goes to one shared file handle (RISC OS allows
   a file to be open for writing only once).

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

Parts of this port were written with the help of an AI assistant.
