#ifndef _KEYBOARD_H
#define _KEYBOARD_H

#include "types.h"

/* Declarations for assembly and extern functions */
void keyboard_handler(void);
extern void keyboard_init(void);

int keypress_flag; // Flag to let lib.c know if the input is from a keypress or terminal_write

#endif /* _KEYBOARD_H */
