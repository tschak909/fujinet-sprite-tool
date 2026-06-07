#include <fujinet-network.h>
#ifndef _CMOC_VERSION_
#include <stdio.h>
#include <string.h>
#endif /* _CMOC_VERSION_ */

#include "screen.h"
#include "state.h"
#include "init.h"
#include "draw.h"
#include "cursor.h"
#include "command.h"
#include "plot.h"
#include "toggle_mag.h"
#include "set_color.h"
#include "import.h"
#include "export.h"
#include "clear.h"
#include "done.h"

State state=INIT;

void main()
{
    while(state!=DONE)
    {
        switch(state)
        {
        case INIT:
            state = init();
            break;
        case DRAW:
            state = draw_sprite();
            break;
        case MAIN:
            state = command_main();
            break;
        case COMMAND:
            state = command();
            break;
        case CURSOR_LEFT:
            state = cursor_left();
            break;
        case CURSOR_RIGHT:
            state = cursor_right();
            break;
        case CURSOR_UP:
            state = cursor_up();
            break;
        case CURSOR_DOWN:
            state = cursor_down();
            break;
        case MOVE:
            state = cursor_move();
            break;
        case PLOT:
            state = draw_plot();
            break;
        case TOGGLE_MAG:
            state = toggle_mag();
            break;
        case SET_COLOR:
            state = set_color();
            break;
        case IMPORT:
            state = import();
            break;
        case EXPORT:
            state = export();
            break;
        case CLEAR:
            state = clear();
            break;
        }
    }

    // While falls out when DONE.
    done();
}
