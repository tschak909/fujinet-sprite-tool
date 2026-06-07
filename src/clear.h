/**
 * @brief Function to clear drawing canvas
 */

#include <string.h>
#include "global.h"
#include "state.h"

State clear(void)
{
    memset(sprite_data,0,sizeof(sprite_data));
    return DRAW;
}
