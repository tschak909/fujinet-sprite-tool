/**
 * @brief Screen API
 */
#ifndef SCREEN_H
#define SCREEN_H

void screen_init(void);
void screen_command(void);
void screen_import_prompt(void);
void screen_import_open(void);
void screen_import_open_error(void);
void screen_import_reading(void);
void screen_import_read_error(unsigned short len);
void screen_export_prompt(void);
void screen_export_open(void);
void screen_export_open_error(void);
void screen_export_writing(void);
void screen_export_write_error(unsigned short len);
void screen_done(void);

#endif /* SCREEN_H */
