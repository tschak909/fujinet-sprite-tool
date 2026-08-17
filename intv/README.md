# FujiNet Sprite Tool — Intellivision

An IntyBASIC port of the FujiNet Sprite Tool, mapped onto STIC hardware:
eight MOBs, each 8×16 pixels (two GRAM cards + the DOUBLEY flag), edited
one at a time on an 8×8-card grid where every card shows two vertically
stacked pixels. All eight MOBs render live as real hardware sprites in a
strip below the grid; a 16-entry palette column shows the STIC colors.

## Controls

| Control            | Action                                      |
|--------------------|---------------------------------------------|
| Disc               | Move cursor (wraps at the edges)            |
| Top action button  | Toggle the pixel under the cursor           |
| Lower-left button  | Cycle the current MOB's color (0-15)        |
| Lower-right button | Cycle preview scale 0/1/2 (8/16/32 px tall) |
| Keypad 1-8         | Select MOB 1-8                              |
| Keypad 9           | Import MOB.DAT from FujiNet                 |
| Keypad 0           | Export MOB.DAT to FujiNet                   |
| Keypad CLEAR       | Clear the current MOB                       |
| Keypad ENTER       | Repaint the screen                          |

Import and export prompt for a devicespec on an on-screen keyboard
(disc + action button pick characters; keypad 0 = space, CLEAR =
backspace, ENTER = accept). The prompt is seeded with

    N:TNFS://TMA-3/MOB.DAT

and any edit persists until the console is reset.

## MOB.DAT format (136 bytes)

| Offset | Size | Contents                                          |
|--------|------|---------------------------------------------------|
| 0      | 16   | MOB 0 pattern, rows top to bottom, bit 7 = left   |
| 16     | 16   | MOB 1 pattern                                     |
| ...    |      | 16-byte stride per MOB                            |
| 112    | 16   | MOB 7 pattern                                     |
| 128    | 8    | One STIC color (0-15) per MOB                     |

Each pattern's first 8 rows are the MOB's upper GRAM card, the last 8
rows the lower card, exactly as the STIC consumes them with DOUBLEY set.

## Building

Needs IntyBASIC and as1600 (jzIntv SDK-1600):

    make            # produces sprite.rom (jzIntv) and sprite.bin/.cfg (SD cart)

Override tool locations if they're not on PATH:

    make INTYBASIC=/path/to/intybasic LIBDIR=/path/to/IntyBASIC/intybasic

## Running

On a FujiNet-patched jzIntv against a fujinet-firmware instance over
BoIP:

    ./run.sh                                  # defaults to localhost:9995
    FUJINET_TARGET=host:port ./run.sh
    ./run.sh --fujinet-debug                  # extra flags pass through

On real hardware, load `sprite.bin`/`sprite.cfg` (or `sprite.rom`) from
the cartridge menu of a FujiNet cart (PiRTO II / Minty bridge).

Without a FujiNet present the editor still runs; import/export report
the failure on the status row.

## Files

- `sprite.bas` — the tool
- `fujinet.bas` — FujiNet mailbox transport (shared with netcat et al.;
  copied verbatim, do not edit here)
- `kbd.bas` — edge-detected input + on-screen keyboard (ditto)
