# Changes

## 3.2.6-riscos5test (2026-09-30)

riscos-mesa devkit 10i switches on SDL's ARM NEON/SIMD blitters. On a
Pi 4 they blend Freeciv-style tiles about 1.6 times faster, but only
onto surfaces without alpha. Freeciv drew its map onto a surface with
alpha, so it wouldn't have gained anything. Patch 0008:

- The map is drawn onto a surface without alpha (it is always covered,
  and copied rather than blended, so the alpha wasn't used).
- Every loaded image is converted to the screen buffer's pixel format, so
  the fast routines apply and no blit converts pixels.
- With Freeciv$Log set, the 10-second line also gives the time spent
  drawing the map ("map drawing N ms"). The screen-update time (the last
  figure) doesn't include that. A line at the start gives the program and
  the pixel formats.

Test builds also contain `freeciv-sdl2-10h`: the same game linked with
the previous SDL (devkit 10h, without the ARM routines). `*Set
Freeciv$SDL 10h` before running !Freeciv to use it, to compare the speed.

## 3.2.6-riscos4test (2026-09-30)

- Full screen is now a "full window", as in RDPClient: a borderless
  window that covers the screen while the desktop keeps running, so a
  game against the computer can start in full screen. This comes from
  the riscos-mesa SDL driver (devkit 10h, which the build now uses).
- Patch 0007: the client follows window size changes from outside (for
  example a screen mode change while in full screen) and takes the
  full-screen size from the window.
- !Help: full screen described; the "play in a window" warning removed.

## 3.2.6-riscos3test (2026-09-29)

riscos2test on the Pi: runs (with !CivServer), but slow; the wheel and
resolution changes did nothing. Patch 0006:

- Screen updates: only the parts that changed are copied into the window
  and plotted, instead of the whole window through a texture and SDL's
  software renderer for every update (a button, the mouse pointer, a
  blinking unit).
- Mouse wheel: scrolls the map (Shift: sideways) and lists in dialogs.
- Screen resolution: changes the window size at once; on RISC OS the list
  offers window sizes up to the desktop's.
- With Freeciv$Log set, the log says every 10 s how busy the client was
  and what drawing cost.

## 3.2.6-riscos2test (2026-09-29)

riscos1test on the Pi: "Start new game" didn't get a server going.

- New **!CivServer** application (as in Freeciv's earlier RISC OS ports):
  runs the server in a TaskWindow that shows its messages and takes server
  commands. While it runs, "Start new game" in !Freeciv plays on it.
- The client's own server start uses a shorter command (the program is
  found through `Freeciv$Path`), `127.0.0.1` instead of `localhost`, and
  `--riscos-quiet` for the output. If it fails, the client says so and
  suggests !CivServer. (Patch 0005.)
- `!Freeciv.Setup` holds what both applications need (modules, paths);
  `!Freeciv.!Boot` sets `Freeciv$Dir` and `Freeciv$Path`.

## 3.2.6-riscos1test (2026-09-29, not yet tested on RISC OS)

First test build of Freeciv 3.2.6 for RISC OS: SDL2 client (in a desktop
window) and server (started in a TaskWindow for games against the
computer). Patches 0001-0004; see README.md.
