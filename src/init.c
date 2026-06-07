/**
 * @brief Program initialization
 */
#include <fujinet-network.h>
#include "init.h"
#include "screen.h"
#include "input.h"
#include "cursor.h"

State init(void)
{
    screen_init();
    input_init();
    network_init();
    cursor_move();
    return MAIN;
}
