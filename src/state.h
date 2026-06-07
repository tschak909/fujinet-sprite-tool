#ifndef STATE_H
#define STATE_H

/**
 * @brief The possible program states
 */
typedef enum _state
{
    INIT,
    DRAW,
    MAIN,
    COMMAND,
    INVALID_COMMAND,
    CURSOR_LEFT,
    CURSOR_RIGHT,
    CURSOR_UP,
    CURSOR_DOWN,
    MOVE,
    PLOT,
    TOGGLE_MAG,
    SET_COLOR,
    IMPORT,
    EXPORT,
    CLEAR,
    DONE,
} State;

#endif /* STATE_H */
