/**
 * @brief Adam's draw functions
 */

#include <stdbool.h>
#include <conio.h>
#include <video/tms99x8.h>
#include "../draw.h"
#include "../state.h"
#include "../global.h"
#include "../vars.h"

enum _displayQuadrant
{
    UPPER_LEFT,
    LOWER_LEFT,
    UPPER_RIGHT,
    LOWER_RIGHT
} displayQuadrant;

static void print_active_pixel(bool isActive)
{
    if (isActive)
    {
        vdp_color(current_color,current_color,7);
        cputc(' ');
    }
    else
    {
        vdp_color(1,0,7);
        cputc('.');
    }
}

static void update_display_quadrant(enum _displayQuadrant dq)
{
    int _x,_y,_offset;

    switch(dq)
    {
    case UPPER_LEFT:
        _x = _y = 0;
        _offset=0;
        break;
    case LOWER_LEFT:
        _x = 0;
        _y = 8;
        _offset=8;
        break;
    case UPPER_RIGHT:
        _x = 8;
        _y = 0;
        _offset=16;
        break;
    case LOWER_RIGHT:
        _x = _y = 8;
        _offset=24;
        break;
    }

    for (unsigned char iy=0; iy<8; iy++)
    {
        unsigned char b = sprite_data[iy+_offset];

        gotoxy(_x,_y++);

        for (unsigned char ix=0; ix<8; ix++)
        {
            if (b & 0x80) // is leftmost bit set?
            {
                print_active_pixel(true);
            }
            else
            {
                print_active_pixel(false);
            }

            b <<= 1; // Shift next bit into leftmost spot.
        }
    }
}

static void update_sprite(void)
{
    vdp_set_sprite_mode((enum sprite_mode)current_mag_size);
    vdp_set_sprite_16(1,sprite_data);
    vdp_put_sprite_16(1,
                      128,
                      128,
                      1,
                      current_color);
}

State draw_sprite(void)
{
    update_display_quadrant(UPPER_LEFT);
    update_display_quadrant(LOWER_LEFT);
    update_display_quadrant(UPPER_RIGHT);
    update_display_quadrant(LOWER_RIGHT);
    update_sprite();

    return COMMAND;
}

State draw_plot(void)
{
    enum _displayQuadrant currentQuadrant;
    int offset = 0;
    int _x = cursor_x;
    int _y = cursor_y;
    unsigned char x_xor_table[8]={0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x01};

    if (_x<8 && _y<8)
    {
        currentQuadrant = UPPER_LEFT;
        // No coordinate adjustments needed.
    }
    else if (_x>7 && _y<8)
    {
        currentQuadrant = UPPER_RIGHT;
        offset = 16;
        _x -= 8;
    }
    else if (_x<8 && _y>7)
    {
        currentQuadrant = LOWER_LEFT;
        offset = 8;
        _y -= 8;
    }
    else if (_x>7 && _y>7)
    {
        currentQuadrant = LOWER_RIGHT;
        offset = 24;
        _x -= 8;
        _y -= 8;
    }

    sprite_data[_y+offset] ^= x_xor_table[_x];
    update_display_quadrant(currentQuadrant); // so it's faster.
    update_sprite();

    return COMMAND;
}
