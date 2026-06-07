/**
 * @brief   Adam specific global variables and constants
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 * @verbose {verbose}
 */

#ifdef BUILD_ADAM

/**
 * @brief The sprite width and height in pixels
 */
#define SPRITE_SIZE_W 16
#define SPRITE_SIZE_H 16
#define SPRITE_DATA_LEN 32 // Length in bytes

/**
 * @brief key codes mapped to commands
 */
// Cursor keys
#define KEY_LEFT         0xA3
#define KEY_RIGHT        0xA1
#define KEY_UP           0xA0
#define KEY_DOWN         0xA2

// Command keys
#define KEY_PLOT         0x20 // spacebar
#define KEY_SET_COLOR    0x85 // V  Smartkey
#define KEY_TOGGLE_MAG   0x86 // VI Smartkey
#define KEY_CLEAR        0x96
#define KEY_IMPORT       0x93 // GET
#define KEY_EXPORT       0x9B // STORE

#endif /* BUILD_ADAM */
