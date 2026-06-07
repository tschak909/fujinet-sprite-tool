/**
 * @brief Cursor management functions
 */

#ifndef CURSOR_H
#define CURSOR_H

#include "state.h"

void cursor_update(unsigned char x, unsigned char y); // Implemented in subclass.
State cursor_up(void);
State cursor_down(void);
State cursor_left(void);
State cursor_right(void);
State cursor_move(void);

#endif /* CURSOR_H */
