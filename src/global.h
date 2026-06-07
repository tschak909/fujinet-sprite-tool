/**
 * @brief Global program state, e.g. sprite data, cursor position, etc.
 */

#ifndef GLOBAL_H

#ifdef BUILD_ADAM
#include "adam/vars.h"
#endif /* BUILD_ADAM */

/**
 * @brief the current cursor position relative to sprite position
 */
extern unsigned char cursor_x, cursor_y;

/**
 * @brief sprite data array
 */
extern unsigned char sprite_data[SPRITE_SIZE_H*4]; // Four bytes

/**
 * @brief the Network URL
 */
extern char network_url[256];

/**
 * @brief current magnification size
 */
extern unsigned char current_mag_size;

#endif /* GLOBAL_H */

/**
 * @brief current sprite color
 */
extern unsigned char current_color;
