#ifndef SCHEDULE_H
#define SCHEDULE_H

#include "types.h"

/* Calls schedule_helper in syscall.c */
extern void schedule_handler(void);

/* Initialize scheduler structures and values */
void schedule_init(void);


#endif /* SCHEDULE_H */
