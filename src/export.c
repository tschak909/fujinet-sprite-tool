/**
 * @brief Export
 */

#include <fujinet-network.h>
#include "export.h"
#include "state.h"
#include "global.h"
#include "vars.h"
#include "screen.h"
#include "input.h"

State export(void)
{
    unsigned short write_len=0;

    screen_export_prompt();
    input_line(network_url);

    if (!network_url[0])
        return MAIN;

    screen_export_open();
    if (network_open(network_url,OPEN_MODE_RW,OPEN_TRANS_NONE) != FN_ERR_OK)
    {
        screen_export_open_error();
        goto export_end;
    }

    screen_export_writing();
    write_len = network_write(network_url,sprite_data,SPRITE_DATA_LEN);
    if (write_len != SPRITE_DATA_LEN)
    {
        screen_export_write_error(write_len);
        goto export_end;
    }

export_end:
    network_close(network_url);
    return MAIN;
}
