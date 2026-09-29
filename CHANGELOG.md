# Changes

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
