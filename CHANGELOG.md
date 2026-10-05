# Changes

## 3.2.6-riscos13test (2026-10-05)

Rebuilt from clean (toolchain, every library and Freeciv) against the
current libraries. No Freeciv code changes.

- **Toolchain: riscos-crossdev 1.3** (was 1.0 with UnixLib installed over
  it). It includes **UnixLib 5.0.3.2** (built from the same change set as
  the UnixLib release, with the same exported symbols) and PThreadTicker
  0.03, and links static programs only. 5.0.3.2 adds `LLONG_MIN` as a
  `long long`, the `getserv*_r` functions and eventfd fixes; Freeciv
  needs none of them, and nothing else changes for it.
  `build/prepare-toolchain.sh` now only installs a separate UnixLib when
  `UNIXLIB` is set in `build/env.sh`, and !Freeciv's PThrTicker comes
  from the toolchain.
- **SDL: riscos-mesa devkit 12f** (was 10i). Same headers. Its SDL
  includes riscos-mesa's later fixes, among them keys that repeat at the
  keyboard's own rate instead of on every poll.
- The `freeciv-sdl2-10h` comparison client is no longer built or shipped
  (the zip is about 5MB smaller), and !Run no longer looks for it. Set
  `AB_DEVKIT` in `build/env.sh` to build it again.

## 3.2.6-riscos12test (2026-10-02)

- Logging stays off by default (the `Set Freeciv$Log 1` line in
  `!Freeciv.!Run` is commented out). The 10-second statistics used to
  read the timer around every wait, map redraw and screen update even
  without logging; now they only run when logging is on (patch 0012),
  so a normal game does no extra work for them.

## 3.2.6-riscos11test (2026-10-02)

Chris Gransden on riscos10test: the background music comes and goes,
and turning it off in the options had no effect.

- **Music breaking up (patch 0011):** SDL mixes sound on its own thread,
  which on RISC OS only runs while Freeciv's task is running. The client
  asked for a 1024-sample buffer, 23 ms of sound, so another task holding
  the processor for longer than that left the music with nothing to
  play. It now uses 4096 samples (93 ms), as Freeciv already does on
  Windows. The log line naming the sound driver also gives the rate,
  channels and buffer size.
- **Turning music off:** Freeciv has two switches, "Enable menu music"
  and "Enable in-game music", and each only acts on its own music, so
  turning off menu music during a game changes nothing. !Help now says
  so.

## 3.2.6-riscos10test (2026-10-01)

- Rebuilt and relinked (client, server and the 10h test client) with
  the **UnixLib 5.0.3.1** release. New since 5.0.3.1-rc8: threads now get
  time in desktop programs that call Wimp_Poll often. Before, UnixLib's
  thread timer restarted at every Wimp_Poll, so in an SDL program (which
  polls more often than every 2 cs) background threads such as SDL's
  sound mixer only ran while the main thread was busy. That is the
  likely reason sounds never finished while the game waited on quit
  (riscos7test).
- PThreadTicker 0.03 in !Freeciv. Programs built with 5.0.3.1 use only
  0.03; if an older version is already loaded, they use their own copy
  of the same code until the next restart, which works the same. The
  `RMEnsure PThreadTicker 0.01` line stays as it is.
- No Freeciv code changes.

## 3.2.6-riscos9test (2026-10-01)

- Relinked with UnixLib 5.0.3.1-rc8 (a pre-release). For Freeciv this
  brings: heaps that can grow past 128 MB (RISC OS 5 caps each dynamic
  area at 128 MB; Freeciv's heaps live in dynamic areas), sleeps and the
  monotonic clock fixed, `_exit()` and fork fixes, and fixes from a
  review of UnixLib's own changes.
- PThreadTicker 0.02 (counts its users with interrupts off; same
  interface). !Freeciv still loads it with `RMEnsure PThreadTicker 0.01`.
- No Freeciv code changes.

## 3.2.6-riscos8test (2026-09-30)

- Relinked with UnixLib 5.0.3, which fixes `ctime()`/`asctime()`
  returning a bad pointer and `read()` into a stack buffer that the
  program hadn't used yet (a crash, "EMT trap"). Freeciv doesn't use
  `ctime()`, but the client and server both use `read()` (files and
  network). No Freeciv code changes.

## 3.2.6-riscos7test (2026-09-30)

riscos6test on the Pi: quitting works, but took about 10 seconds, and
the log file stayed empty. Patch 0010:

- **Log:** the log file was opened twice (for normal output and for
  errors). RISC OS doesn't allow a file to be open for writing twice, so
  the second open failed and the log, which goes to the error output,
  was lost. It is now opened once and shared. This fixes FreecivSrvLog
  too.
- **Quitting:** sounds still playing are stopped at once instead of
  waited for. SDL mixes sound in its own thread, which on RISC OS doesn't
  get time while the game waits in the desktop, so the sounds never
  finished and each of two waits ran out after 5 seconds. The short quit
  sound is cut.
- The log names the SDL sound driver in use.

## 3.2.6-riscos6test (2026-09-30)

riscos5test on the Pi: during a game the client wouldn't quit (icon bar
Quit, the window's close icon, Escape, Alt-Break or shutting down RISC
OS), while the desktop kept running. Patch 0009:

- On quit the client plays its quit sound and then waits until no sound
  is playing. If the sound output stalls, that wait never ended, and
  since it polls the Wimp the desktop kept running with the game window
  still open, ignoring every request to quit. It now gives up after 5
  seconds.
- A quit request that arrives while a dialog, edit field or scroll bar
  has its own event loop is no longer lost: every loop returns, down to
  the main loop.
- With Freeciv$Log set, the log follows the quit step by step ("Quit
  requested", "Left the main loop", "Client exit: ...", "Audio: ...").

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
