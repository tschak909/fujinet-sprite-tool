/**
 * @brief Adam implementation of screen routines
 */

#include <smartkeys.h>
#include <stdio.h>
#include <conio.h>
#include <string.h>
#include <video/tms99x8.h>
#include "../screen.h"

// Draw color palette down upper right portion of screen
void screen_draw_palette(void)
{
    for (unsigned char i=0;i<16;i++)
    {
        gotoxy(28,i);
        vdp_color(1,7,7);
        cprintf("%2u ",i);
        vdp_color(1,i,7);
        cputs(" ");
    }
}

void screen_init(void)
{
    smartkeys_set_mode();
    screen_draw_palette();
}

void screen_command(void)
{
    smartkeys_display(NULL,NULL,NULL,NULL,"  COLOR","   MAG");
    smartkeys_status("  FUJINET SPRITE TOOL\n  ARROWS MOVE CURSOR [CLEAR]\n  [GET] IMPORTS, [STORE] EXPORTS");
}

void screen_import_prompt(void)
{
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status("ENTER NETWORK URL, e.g. N:TCP://1.2.3.4/");
}

void screen_import_open(void)
{
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status("OPENING...");
}

void screen_import_reading(void)
{
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status("READING...");
}

void screen_import_open_error(void)
{
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status("COULD NOT OPEN FOR IMPORT.");
}

void screen_import_read_error(unsigned short len)
{
    char errStr[64];

    snprintf(errStr,"READ ERROR. ONLY READ %u BYTES.",len);
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status(errStr);
}

void screen_export_prompt(void)
{
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status("ENTER NETWORK URL, e.g. N:TCP://1.2.3.4/");
}

void screen_export_open(void)
{
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status("OPENING...");
}

void screen_export_writing(void)
{
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status("WRITING...");
}

void screen_export_open_error(void)
{
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status("COULD NOT OPEN FOR EXPORT.");
}

void screen_export_write_error(unsigned short len)
{
    char errStr[64];

    snprintf(errStr,"WRITE ERROR. ONLY WROTE %u BYTES.",len);
    smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
    smartkeys_status(errStr);
}


void screen_done(void)
{
    // Currently not needed.
}
