/**
 * @brief Import
 */

#include <fujinet-network.h>
#include "import.h"
#include "state.h"
#include "global.h"
#include "vars.h"
#include "screen.h"
#include "input.h"

State import(void)
{
    unsigned short read_len=0;

    screen_import_prompt();
    input_line(network_url);

    if (!network_url[0])
        return MAIN;

    screen_import_open();
    if (network_open(network_url,OPEN_MODE_READ,OPEN_TRANS_NONE) != FN_ERR_OK)
    {
        screen_import_open_error();
        goto import_end;
    }

    screen_import_reading();
    read_len = network_read(network_url,sprite_data,SPRITE_DATA_LEN);
    if (read_len != SPRITE_DATA_LEN)
    {
        screen_import_read_error(read_len);
        goto import_end;
    }

import_end:
    network_close(network_url);
    return MAIN;
}
