/**
 * @brief Input API
 */

#ifndef INPUT_H
#define INPUT_H

/**
 * @brief Initialize input, if needed
 */
void input_init(void);

/**
 * @brief get next input (command)
 */
int input(void);

/**
 * @brief get a line of text from keyboard
 */
void input_line(char *c);

#endif /* INPUT_H */
