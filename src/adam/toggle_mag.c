/**
 * @brief Toggle magnification size
 */

#include <video/tms99x8.h>
#include "../state.h"
#include "../global.h"

State toggle_mag(void)
{
    if (current_mag_size == 2)
        current_mag_size = 0;
    else
        current_mag_size++;

    // Current mag size gets shown in DRAW.

    return DRAW;
}
