/**
 * @brief toggle between all possible 16 sprite colors
 */

#include <video/tms99x8.h>
#include "../set_color.h"
#include "../global.h"
#include "../vars.h"
#include "../state.h"

State set_color(void)
{
    if (current_color == 15)
        current_color = 0;
    else
        current_color++;

    // Color changing happens in DRAW.

    return DRAW;
}
