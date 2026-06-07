/**
 * @brief Global program state, e.g. sprite data, cursor position, etc.
 */

#ifdef BUILD_ADAM
#include "adam/vars.h"
#endif /* BUILD_ADAM */

/**
 * @brief the current cursor position relative to sprite position
 */
unsigned char cursor_x, cursor_y;

/**
 * @brief sprite data array
 */
unsigned char sprite_data[SPRITE_SIZE_H*4] = {3, 3, 3, 7, 7, 0xc7, 0xc7, 0xe7, 0xee, 0xee, 0xfe, 0xff, 0xe7, 0xc3, 0xf0, 0x90,0xc0, 0xc0, 0xc0, 0xe0, 0xe0, 0xe3, 0xe3, 0xe7, 0x77, 0x77, 0x7f, 0xff, 0xe7, 0xc3, 0x0f, 9};

/**
 * @brief the Network URL
 */
char network_url[256];

/**
 * @brief current magnification size
 */
unsigned char current_mag_size=2;

/**
 * @brief current sprite color
 */
unsigned char current_color=1;
