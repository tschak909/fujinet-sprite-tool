/**
 * @brief Update and draw current sprite
 */

#ifndef DRAW_H
#define DRAW_H

#include "state.h"

/**
 * @brief Draw sprite on screen
 * @return New program state.
 */
State draw_sprite(void);

/**
 * @brief toggle pixel at cursor
 */
State draw_plot(void);

/**
 * @brief Clear the canvas
 */
State draw_clear(void);

#endif /* DRAW_H */
