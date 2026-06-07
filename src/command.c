/**
 * @brief Command processor
 */
#include <conio.h>
#include "state.h"
#include "command.h"
#include "input.h"
#include "vars.h"
#include "screen.h"

State command_main(void)
{
    screen_command();
    return DRAW;
}

State command(void)
{
    int k=input();

    switch(k)
    {
    case KEY_LEFT:
        return CURSOR_LEFT;
    case KEY_RIGHT:
        return CURSOR_RIGHT;
    case KEY_UP:
        return CURSOR_UP;
    case KEY_DOWN:
        return CURSOR_DOWN;
    case KEY_PLOT:
        return PLOT;
    case KEY_SET_COLOR:
        return SET_COLOR;
    case KEY_TOGGLE_MAG:
        return TOGGLE_MAG;
    case KEY_IMPORT:
        return IMPORT;
    case KEY_EXPORT:
        return EXPORT;
    case KEY_CLEAR:
        return CLEAR;
    }

    return COMMAND;
}
