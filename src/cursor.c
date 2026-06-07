/**
 * @brief Cursor management functions
 */

#include "cursor.h"
#include "vars.h"
#include "global.h"
#include "state.h"

State cursor_move(void)
{
    cursor_update(cursor_x,cursor_y);
    return COMMAND;
}

State cursor_up(void)
{
    if (cursor_y == 0)
        cursor_y = SPRITE_SIZE_H - 1;
    else
        cursor_y--;

    return MOVE;
}

State cursor_down(void)
{
    if (cursor_y == SPRITE_SIZE_H - 1)
        cursor_y = 0;
    else
        cursor_y++;

    return MOVE;
}

State cursor_left(void)
{
    if (cursor_x == 0)
        cursor_x = SPRITE_SIZE_W - 1;
    else
        cursor_x--;

    return MOVE;
}

State cursor_right(void)
{
    if (cursor_x == SPRITE_SIZE_W - 1)
        cursor_x = 0;
    else
        cursor_x++;

    return MOVE;
}
