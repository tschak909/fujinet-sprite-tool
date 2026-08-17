' sprite.bas -- FujiNet Sprite Tool for the Intellivision, in IntyBASIC.
'
' A port of the Coleco Adam sprite tool (../src) mapped onto STIC
' hardware: eight MOBs, each 8x16 pixels (two GRAM cards + the DOUBLEY
' flag), edited one at a time on an 8x8-card grid where every card shows
' two vertically stacked pixels. All eight MOBs render live in a strip
' below the grid; a 16-entry palette column shows the STIC colors.
'
' Editor:   disc                  move cursor (wraps at the edges)
'           top action button     toggle the pixel under the cursor
'           lower-left button     cycle the current MOB's color
'           lower-right button    cycle preview scale 0/1/2 (8/16/32 px)
'           keypad 1-8            select MOB
'           keypad 9              import MOB.DAT from FujiNet
'           keypad 0              export MOB.DAT to FujiNet
'           keypad CLEAR          clear the current MOB
'           keypad ENTER          repaint the screen
'
' Import/export prompt with the on-screen keyboard from kbd.bas, seeded
' with N:TNFS://TMA-3/MOB.DAT; an edited devicespec persists until the
' console is reset. The file is 136 bytes: eight 16-byte patterns
' (rows top to bottom, bit 7 = left pixel) then eight color bytes.
'
' Build:  make   (intybasic sprite.bas + as1600; see Makefile)
    GOTO main

    INCLUDE "fujinet.bas"
    INCLUDE "kbd.bas"

    ' Open mode for import; fujinet.bas only carries the RW ($0C) name.
    CONST OPEN_MODE_READ = $04

    ' Scratch RAM, ours, above fujinet.bas's buffers (which end at $917F).
    CONST SC_PAT    = $9200   ' 128 bytes: MOB m row r at SC_PAT + m*16 + r
    CONST SC_COLORS = $9280   ' 8 bytes: STIC color 0-15 per MOB
    CONST SC_URL    = $9300   ' devicespec, 256 bytes (255 chars + NUL)

    ' SPRITE attribute bits.
    CONST X_VISIBLE = $0200
    CONST X_ZOOMX2  = $0400

    ' GRAM card map. MOB m owns cards 2m/2m+1 (the even boundary DOUBLEY
    ' requires); 16-29 are the static UI glyphs loaded from gfx_ui.
    CONST CARD_FILL0  = 16    ' +fs, fs = top_pixel_set + 2*bottom_pixel_set
    CONST CARD_CURSOR = 20    ' +cursor_half*4 + fs
    CONST CARD_SWATCH = 28    ' solid block
    CONST CARD_FRAME  = 29    ' hollow frame (palette entry 0)

    CONST STATUS_POS = 200    ' row 10: title / import-export results
    CONST HELP_POS   = 220    ' row 11: key hints

    DIM cursor_x, cursor_y    ' 0-7, 0-15
    DIM cur_mob               ' 0-7
    DIM cur_mag               ' preview scale 0-2
    DIM fn_present            ' 1 = mailbox answered at boot
    DIM ed_pb0, ed_pb1, ed_pb2
    DIM ed_b0, ed_b1, ed_b2   ' fresh per-side action button presses
    DIM m, r, i               ' loop temps (never nested across a GOSUB)
    DIM gx, gyc               ' grid cell coords, input to grid_cell_draw
    DIM fs, gcard, sm, sr
    DIM #cc                   ' color scratch; 16-bit, see fujinet.bas on
                              ' the v1.4.2 "PEEK AND 255 into an 8-bit
                              ' var" codegen bug
    DIM #bt                   ' backtab word / address scratch
    DIM #stage(8)             ' one MOB (2 cards) staged for DEFINE

' The default devicespec (22 bytes): "N:TNFS://TMA-3/MOB.DAT"
lit_spec:
    DATA 78,58,84,78,70,83,58,47,47,84,77,65
    DATA 45,51,47,77,79,66,46,68,65,84
    CONST LEN_SPEC = 22

' Leftmost pixel = bit 7, same as the STIC GRAM row layout.
bit_tbl:
    DATA $80,$40,$20,$10,$08,$04,$02,$01

' GROM card words (no color bits) for hex digits 0-9 A-F: (ascii-32)*8.
hexcard:
    DATA 128,136,144,152,160,168,176,184,192,200
    DATA 264,272,280,288,296,304

' MOB strip Y attribute per mag: y=72 (top of card row 8) + DOUBLEY ($80)
' + Y scale bits 9-8 (0.5x / 1x / 2x -> 8, 16, 32 pixels tall).
spr_y_tbl:
    DATA 200, 456, 712

' Default MOB 0 pattern: a little rocket, in the spirit of the Adam
' tool's default spaceship.
default_mob:
    DATA $18,$18,$3C,$3C,$7E,$7E,$7E,$7E
    DATA $7E,$7E,$FF,$DB,$DB,$18,$24,$42

' ---------------------------------------------------------------------------
' Static UI glyphs, GRAM cards 16-29. Each grid card stacks two sprite
' pixels: rows 0-3 = the even (top) pixel, rows 4-7 = the odd (bottom)
' pixel. Half patterns: unset = centered dot, set = solid, cursor-over-
' unset = box + dot, cursor-over-set = inverted box.
' ---------------------------------------------------------------------------
gfx_ui:
    ' card 16: fs=0 (unset/unset)
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    ' card 17: fs=1 (set/unset)
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    ' card 18: fs=2 (unset/set)
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    ' card 19: fs=3 (set/set)
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    ' card 20: cursor on top half, fs=0
    BITMAP "XXXXXXXX"
    BITMAP "X..XX..X"
    BITMAP "X..XX..X"
    BITMAP "XXXXXXXX"
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    ' card 21: cursor on top half, fs=1
    BITMAP "........"
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "........"
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    ' card 22: cursor on top half, fs=2
    BITMAP "XXXXXXXX"
    BITMAP "X..XX..X"
    BITMAP "X..XX..X"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    ' card 23: cursor on top half, fs=3
    BITMAP "........"
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "........"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    ' card 24: cursor on bottom half, fs=0
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "XXXXXXXX"
    BITMAP "X..XX..X"
    BITMAP "X..XX..X"
    BITMAP "XXXXXXXX"
    ' card 25: cursor on bottom half, fs=1
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "X..XX..X"
    BITMAP "X..XX..X"
    BITMAP "XXXXXXXX"
    ' card 26: cursor on bottom half, fs=2
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "........"
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "........"
    ' card 27: cursor on bottom half, fs=3
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "........"
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "........"
    ' card 28: solid swatch
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    ' card 29: hollow frame (visible "black" for palette entry 0)
    BITMAP "XXXXXXXX"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "XXXXXXXX"

' ---------------------------------------------------------------------------
' seed_url: load the default devicespec into SC_URL. Called once at boot;
' after that the user's edits persist across import/export operations.
' ---------------------------------------------------------------------------
seed_url: PROCEDURE
    FOR i = 0 TO LEN_SPEC - 1
        POKE (SC_URL + i), PEEK(VARPTR lit_spec(0) + i) AND 255
    NEXT i
    POKE (SC_URL + LEN_SPEC), 0
END

' ---------------------------------------------------------------------------
' stage_mob: pack MOB sm's 16 pattern rows into #stage the way DEFINE
' wants them: word w low byte = row 2w, high byte = row 2w+1 (the GRAM
' copy in the epilogue writes low byte first, then SWAPs for the next
' row). Words 0-3 become the first card, 4-7 the second.
' ---------------------------------------------------------------------------
stage_mob: PROCEDURE
    FOR sr = 0 TO 7
        #stage(sr) = (PEEK(SC_PAT + sm*16 + sr + sr) AND 255) + (PEEK(SC_PAT + sm*16 + sr + sr + 1) AND 255) * 256
    NEXT sr
END

' ---------------------------------------------------------------------------
' redefine_all: push all 8 MOB patterns into GRAM, 2 cards per frame. The
' WAIT inside the loop is mandatory -- DEFINE latches the array address
' and the copy happens at the next frame, so #stage must survive until
' then.
' ---------------------------------------------------------------------------
redefine_all: PROCEDURE
    FOR m = 0 TO 7
        sm = m
        GOSUB stage_mob
        DEFINE m*2,2,#stage
        WAIT
    NEXT m
END

' ---------------------------------------------------------------------------
' grid_cell_draw: paint grid cell (gx, gyc) -- the card showing pixels
' (gx, 2*gyc) and (gx, 2*gyc+1) of the current MOB. Draws the cursor
' overlay variant when the cursor sits in this cell. Set pixels take the
' MOB's color (grey when the MOB is black, so they stay visible on the
' black stack); empty cells show a white placement dot.
' ---------------------------------------------------------------------------
grid_cell_draw: PROCEDURE
    fs = 0
    IF PEEK(SC_PAT + cur_mob*16 + gyc + gyc) AND bit_tbl(gx) THEN fs = fs + 1
    IF PEEK(SC_PAT + cur_mob*16 + gyc + gyc + 1) AND bit_tbl(gx) THEN fs = fs + 2
    IF (gx = cursor_x) AND (gyc = cursor_y / 2) THEN
        gcard = CARD_CURSOR + (cursor_y AND 1) * 4 + fs
    ELSE
        gcard = CARD_FILL0 + fs
    END IF
    #cc = PEEK(SC_COLORS + cur_mob) AND 15
    IF #cc = 0 THEN #cc = 8
    IF fs = 0 THEN #cc = 7
    #BACKTAB(gyc*20 + gx) = $0800 + gcard*8 + (#cc AND 7) + (#cc AND 8) * 512
END

redraw_grid: PROCEDURE
    FOR gyc = 0 TO 7
        FOR gx = 0 TO 7
            GOSUB grid_cell_draw
        NEXT gx
    NEXT gyc
END

' ---------------------------------------------------------------------------
' palette_marker: paint all 16 palette index digits, the current MOB's
' color in yellow, the rest in white.
' ---------------------------------------------------------------------------
palette_marker: PROCEDURE
    #cc = PEEK(SC_COLORS + cur_mob) AND 15
    FOR r = 0 TO 7
        IF r = #cc THEN
            #BACKTAB(r*20 + 9) = hexcard(r) + COL_HILIGHT
        ELSE
            #BACKTAB(r*20 + 9) = hexcard(r) + COL_NORMAL
        END IF
        IF r + 8 = #cc THEN
            #BACKTAB(r*20 + 12) = hexcard(r + 8) + COL_HILIGHT
        ELSE
            #BACKTAB(r*20 + 12) = hexcard(r + 8) + COL_NORMAL
        END IF
    NEXT r
END

' ---------------------------------------------------------------------------
' redraw_palette: hex index + color swatch for all 16 STIC colors, split
' 0-7 / 8-15 over two column pairs. Entry 0 gets a hollow white frame (a
' black swatch on the black stack would be invisible); colors 8-15 carry
' the pastel bit ($1000) in the backtab word.
' ---------------------------------------------------------------------------
redraw_palette: PROCEDURE
    FOR r = 0 TO 7
        IF r = 0 THEN
            #BACKTAB(10) = $0800 + CARD_FRAME*8 + CS_WHITE
        ELSE
            #BACKTAB(r*20 + 10) = $0800 + CARD_SWATCH*8 + r
        END IF
        #BACKTAB(r*20 + 13) = $0800 + CARD_SWATCH*8 + r + $1000
    NEXT r
    GOSUB palette_marker
END

' ---------------------------------------------------------------------------
' redraw_strip: digit labels and the highlight cells behind the MOB strip
' (row 8-9). MOB m sits over background column 2+2m; its label goes in
' the gap column beside it, yellow for the current MOB. Two blue swatch
' cards behind the current MOB mark it (and keep a black MOB visible).
' ---------------------------------------------------------------------------
redraw_strip: PROCEDURE
    FOR m = 0 TO 7
        IF m = cur_mob THEN
            #BACKTAB(162 + m + m) = $0800 + CARD_SWATCH*8 + CS_BLUE
            #BACKTAB(182 + m + m) = $0800 + CARD_SWATCH*8 + CS_BLUE
            #BACKTAB(183 + m + m) = hexcard(m + 1) + COL_HILIGHT
        ELSE
            #BACKTAB(162 + m + m) = 0
            #BACKTAB(182 + m + m) = 0
            #BACKTAB(183 + m + m) = hexcard(m + 1) + COL_DIM
        END IF
    NEXT m
END

' ---------------------------------------------------------------------------
' sprite_update_m: (re)issue MOB m's SPRITE attributes: strip position,
' visible, DOUBLEY 8x16 from GRAM cards 2m/2m+1, the MOB's color, and the
' current preview scale (mag 2 also doubles X).
' ---------------------------------------------------------------------------
sprite_update_m: PROCEDURE
    #cc = PEEK(SC_COLORS + m) AND 15
    #bt = 24 + m*16 + X_VISIBLE
    IF cur_mag = 2 THEN #bt = #bt + X_ZOOMX2
    SPRITE m, #bt, spr_y_tbl(cur_mag), $0800 + m*16 + (#cc AND 7) + (#cc AND 8) * 512
END

redraw_sprites: PROCEDURE
    FOR m = 0 TO 7
        GOSUB sprite_update_m
    NEXT m
END

hide_sprites: PROCEDURE
    FOR m = 0 TO 7
        SPRITE m, 0
    NEXT m
END

' ---------------------------------------------------------------------------
' redraw_indicators: right-hand panel, rows 0-5 of columns 15-19.
' ---------------------------------------------------------------------------
redraw_indicators: PROCEDURE
    PRINT AT 15 COLOR COL_NORMAL, "MOB "
    #BACKTAB(19) = hexcard(cur_mob + 1) + COL_HILIGHT
    PRINT AT 35 COLOR COL_NORMAL, "CLR "
    #cc = PEEK(SC_COLORS + cur_mob) AND 15
    #BACKTAB(39) = hexcard(#cc) + COL_HILIGHT
    PRINT AT 55 COLOR COL_NORMAL, "MAG "
    #BACKTAB(59) = hexcard(cur_mag) + COL_HILIGHT
    PRINT AT 95 COLOR COL_DIM, "9 IMP"
    PRINT AT 115 COLOR COL_DIM, "0 EXP"
END

status_blank: PROCEDURE
    PRINT AT STATUS_POS COLOR CS_BLACK, "                    "
END

' ---------------------------------------------------------------------------
' redraw_all: full repaint -- the DRAW state of the Adam original.
' ---------------------------------------------------------------------------
redraw_all: PROCEDURE
    CLS
    GOSUB redraw_grid
    GOSUB redraw_palette
    GOSUB redraw_strip
    GOSUB redraw_sprites
    GOSUB redraw_indicators
    PRINT AT STATUS_POS COLOR COL_NORMAL, "FUJINET SPRITE TOOL "
    PRINT AT HELP_POS COLOR COL_DIM, "TOP PLOT L CLR R MAG"
END

' ---------------------------------------------------------------------------
' ed_poll: per-frame input. in_poll (kbd.bas) supplies the disc with
' auto-repeat and the debounced keypad, but its in_btn ORs the three
' action buttons together -- the editor needs them apart, so each side is
' edge-detected here. While a keypad key is down its row lines alias as
' disc+button patterns, so those are suppressed for the frame.
' ---------------------------------------------------------------------------
ed_poll: PROCEDURE
    GOSUB in_poll
    ed_b0 = 0 : ed_b1 = 0 : ed_b2 = 0
    IF CONT.B0 THEN
        IF ed_pb0 = 0 THEN ed_b0 = 1
        ed_pb0 = 1
    ELSE
        ed_pb0 = 0
    END IF
    IF CONT.B1 THEN
        IF ed_pb1 = 0 THEN ed_b1 = 1
        ed_pb1 = 1
    ELSE
        ed_pb1 = 0
    END IF
    IF CONT.B2 THEN
        IF ed_pb2 = 0 THEN ed_b2 = 1
        ed_pb2 = 1
    ELSE
        ed_pb2 = 0
    END IF
    IF CONT.KEY <> KEYPAD_NONE THEN
        in_disc = 0
        ed_b0 = 0 : ed_b1 = 0 : ed_b2 = 0
    END IF
END

' ---------------------------------------------------------------------------
' Cursor movement, wrapping at the edges like the Adam tool's cursor.c.
' Redraw only the cell left behind and the cell entered.
' ---------------------------------------------------------------------------
cur_up: PROCEDURE
    gx = cursor_x : gyc = cursor_y / 2
    IF cursor_y = 0 THEN cursor_y = 15 ELSE cursor_y = cursor_y - 1
    GOSUB grid_cell_draw
    gyc = cursor_y / 2
    GOSUB grid_cell_draw
END

cur_down: PROCEDURE
    gx = cursor_x : gyc = cursor_y / 2
    IF cursor_y = 15 THEN cursor_y = 0 ELSE cursor_y = cursor_y + 1
    GOSUB grid_cell_draw
    gyc = cursor_y / 2
    GOSUB grid_cell_draw
END

cur_left: PROCEDURE
    gx = cursor_x : gyc = cursor_y / 2
    IF cursor_x = 0 THEN cursor_x = 7 ELSE cursor_x = cursor_x - 1
    GOSUB grid_cell_draw
    gx = cursor_x
    GOSUB grid_cell_draw
END

cur_right: PROCEDURE
    gx = cursor_x : gyc = cursor_y / 2
    IF cursor_x = 7 THEN cursor_x = 0 ELSE cursor_x = cursor_x + 1
    GOSUB grid_cell_draw
    gx = cursor_x
    GOSUB grid_cell_draw
END

' ---------------------------------------------------------------------------
' do_plot: XOR-toggle the pixel under the cursor, repaint its cell, and
' push the current MOB's two GRAM cards (applied at the loop's next WAIT).
' ---------------------------------------------------------------------------
do_plot: PROCEDURE
    #bt = SC_PAT + cur_mob*16 + cursor_y
    POKE #bt, (PEEK(#bt) AND 255) XOR bit_tbl(cursor_x)
    gx = cursor_x : gyc = cursor_y / 2
    GOSUB grid_cell_draw
    sm = cur_mob
    GOSUB stage_mob
    DEFINE cur_mob*2,2,#stage
END

do_color: PROCEDURE
    #cc = (PEEK(SC_COLORS + cur_mob) + 1) AND 15
    POKE (SC_COLORS + cur_mob), #cc
    GOSUB palette_marker
    GOSUB redraw_grid
    m = cur_mob
    GOSUB sprite_update_m
    GOSUB redraw_indicators
END

do_mag: PROCEDURE
    cur_mag = cur_mag + 1
    IF cur_mag > 2 THEN cur_mag = 0
    GOSUB redraw_sprites
    GOSUB redraw_indicators
END

do_select: PROCEDURE
    cur_mob = in_key - 1
    GOSUB redraw_grid
    GOSUB redraw_strip
    GOSUB palette_marker
    GOSUB redraw_indicators
END

do_clear: PROCEDURE
    FOR r = 0 TO 15
        POKE (SC_PAT + cur_mob*16 + r), 0
    NEXT r
    GOSUB redraw_grid
    sm = cur_mob
    GOSUB stage_mob
    DEFINE cur_mob*2,2,#stage
END

' ---------------------------------------------------------------------------
' prompt_url: the on-screen keyboard over the whole screen, editing
' SC_URL in place (seeded once at boot, so edits persist between
' operations). Caller prints the hint row afterward-untouched row 11.
' Returns grid_entry's fn_ok/g_len.
' ---------------------------------------------------------------------------
prompt_url: PROCEDURE
    GOSUB hide_sprites
    CLS
    #ge_dst = SC_URL
    #g_max = 256
    GOSUB grid_entry
    ' An action button still held from picking OK/ESC must not read as a
    ' fresh press (= a spurious plot) back in the editor loop.
    ed_pb0 = 1 : ed_pb1 = 1 : ed_pb2 = 1
END

' ---------------------------------------------------------------------------
' do_import: GET -- mirrors the Adam tool's import.c. Open read-only,
' poll STATUS until the byte count covers the file or settles (the first
' STATUS is also what triggers deferred fetches), read 136 bytes, copy
' them out of the mailbox RX window, close, repaint everything.
' ---------------------------------------------------------------------------
do_import: PROCEDURE
    IF fn_present = 0 THEN
        GOSUB status_blank
        PRINT AT STATUS_POS COLOR COL_ERROR, "NO FUJINET"
        RETURN
    END IF
    PRINT AT HELP_POS COLOR COL_DIM, "OK IMPORTS ESC BACK "
    GOSUB prompt_url
    IF (fn_ok = 0) OR (g_len = 0) THEN
        GOSUB redraw_all
        RETURN
    END IF

    CLS
    PRINT AT 0 COLOR COL_NORMAL, "OPENING..."
    #fn_txlen = 0
    #fn_src = SC_URL : ls_max = 255 : GOSUB fn_strlen : GOSUB fn_putstr
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_OPEN
    mb_nparam = 2
    pm_i = 0 : pm_size = 1 : #pm_val = OPEN_MODE_READ : GOSUB fn_param
    pm_i = 1 : pm_size = 1 : #pm_val = OPEN_TRANS_NONE : GOSUB fn_param
    GOSUB fn_transact
    IF fn_ok = 0 THEN
        GOSUB redraw_all
        GOSUB status_blank
        PRINT AT STATUS_POS COLOR COL_ERROR, "OPEN FAILED"
        RETURN
    END IF

    PRINT AT 20, "READING..."
    #ac_prev = 0
    FOR ac_i = 0 TO 59
        WAIT
        GOSUB net_status
        IF fn_ok = 0 THEN EXIT FOR
        IF #net_avail >= 136 THEN EXIT FOR
        IF (#net_avail > 0) AND (#net_avail = #ac_prev) THEN EXIT FOR
        #ac_prev = #net_avail
    NEXT ac_i
    IF fn_ok = 0 THEN
        GOSUB net_close
        GOSUB redraw_all
        GOSUB status_blank
        PRINT AT STATUS_POS COLOR COL_ERROR, "STATUS FAILED"
        RETURN
    END IF

    #net_readlen = 136
    GOSUB net_read
    IF (fn_ok = 0) OR (#net_gotlen <> 136) THEN
        GOSUB net_close
        GOSUB redraw_all
        GOSUB status_blank
        PRINT AT STATUS_POS COLOR COL_ERROR, "SHORT READ ", <>#net_gotlen
        RETURN
    END IF

    FOR i = 0 TO 127
        POKE (SC_PAT + i), PEEK(FN_RX + i) AND 255
    NEXT i
    FOR i = 0 TO 7
        POKE (SC_COLORS + i), PEEK(FN_RX + 128 + i) AND 15
    NEXT i
    GOSUB net_close
    GOSUB redefine_all
    GOSUB redraw_all
    GOSUB status_blank
    PRINT AT STATUS_POS COLOR COL_HILIGHT, "IMPORTED 136 BYTES"
END

' ---------------------------------------------------------------------------
' do_export: STORE -- mirrors the Adam tool's export.c. Open read-write
' (fujinet.bas's net_open already uses $0C, the mode the Adam tool
' exports with), stage the 136 bytes into the mailbox TX window, write,
' close.
' ---------------------------------------------------------------------------
do_export: PROCEDURE
    IF fn_present = 0 THEN
        GOSUB status_blank
        PRINT AT STATUS_POS COLOR COL_ERROR, "NO FUJINET"
        RETURN
    END IF
    PRINT AT HELP_POS COLOR COL_DIM, "OK EXPORTS ESC BACK "
    GOSUB prompt_url
    IF (fn_ok = 0) OR (g_len = 0) THEN
        GOSUB redraw_all
        RETURN
    END IF

    CLS
    PRINT AT 0 COLOR COL_NORMAL, "OPENING..."
    #fn_txlen = 0
    #fn_src = SC_URL : ls_max = 255 : GOSUB fn_strlen : GOSUB fn_putstr
    GOSUB net_open
    IF fn_ok = 0 THEN
        GOSUB redraw_all
        GOSUB status_blank
        PRINT AT STATUS_POS COLOR COL_ERROR, "OPEN FAILED"
        RETURN
    END IF

    PRINT AT 20, "WRITING..."
    FOR i = 0 TO 127
        POKE (FN_TX + i), PEEK(SC_PAT + i) AND 255
    NEXT i
    FOR i = 0 TO 7
        POKE (FN_TX + 128 + i), PEEK(SC_COLORS + i) AND 255
    NEXT i
    fn_len = 136
    GOSUB net_write
    IF fn_ok = 0 THEN
        GOSUB net_close
        GOSUB redraw_all
        GOSUB status_blank
        PRINT AT STATUS_POS COLOR COL_ERROR, "WRITE FAILED"
        RETURN
    END IF
    GOSUB net_close
    GOSUB redraw_all
    GOSUB status_blank
    PRINT AT STATUS_POS COLOR COL_HILIGHT, "EXPORTED 136 BYTES"
END

' ---------------------------------------------------------------------------
' main
' ---------------------------------------------------------------------------
main:
    MODE 0, 0, 0, 0, 0
    WAIT
    DEFINE 16, 14, gfx_ui
    WAIT
    CLS
    PRINT AT 0 COLOR COL_NORMAL, "FUJINET SPRITE TOOL"
    PRINT AT 40 COLOR COL_DIM, "CONNECTING TO FUJINET"
    GOSUB fn_wait_mailbox
    fn_present = fn_ok
    IF fn_present = 0 THEN
        PRINT AT 40 COLOR COL_ERROR, "NO FUJINET MAILBOX   "
        PRINT AT 60 COLOR COL_DIM, "EDITOR ONLY          "
    END IF

    FOR i = 0 TO 127
        POKE (SC_PAT + i), 0
    NEXT i
    FOR i = 0 TO 15
        POKE (SC_PAT + i), PEEK(VARPTR default_mob(0) + i) AND 255
    NEXT i
    FOR i = 0 TO 7
        POKE (SC_COLORS + i), 7
    NEXT i
    GOSUB seed_url

    cursor_x = 0 : cursor_y = 0
    cur_mob = 0
    cur_mag = 1
    GOSUB redefine_all
    GOSUB redraw_all

loop:
    WAIT
    GOSUB ed_poll

    IF in_disc = DISC_UP THEN GOSUB cur_up
    IF in_disc = DISC_DOWN THEN GOSUB cur_down
    IF in_disc = DISC_LEFT THEN GOSUB cur_left
    IF in_disc = DISC_RIGHT THEN GOSUB cur_right
    IF ed_b0 THEN GOSUB do_plot
    IF ed_b1 THEN GOSUB do_color
    IF ed_b2 THEN GOSUB do_mag
    ' One keypad action per frame: import/export run grid_entry, whose
    ' accepting ENTER lingers in in_key when they return -- a plain IF
    ' chain would see it and let redraw_all wipe their status message.
    IF (in_key >= 1) AND (in_key <= 8) THEN
        GOSUB do_select
    ELSEIF in_key = 9 THEN
        GOSUB do_import
    ELSEIF in_key = KEYPAD_0 THEN
        GOSUB do_export
    ELSEIF in_key = KEYPAD_CLEAR THEN
        GOSUB do_clear
    ELSEIF in_key = KEYPAD_ENTER THEN
        GOSUB redraw_all
    END IF
    GOTO loop
