#ifndef _PIT_H
#define _PIT_H

#include "types.h"

#define PIT_CHANNEL_0 0x40       // PIT channel 0 data port (used for interrupt generating)
#define PIT_MODE_REG 0x43        // PIT mode/command register
#define PIT_IRQ 0                // IRQ number for PIT
#define PIT_FREQUENCY 1193182    // Clock frequency for the PIT timer (Online)
#define TARGET_FREQUENCY 100     // Target frequency of 100 Hz (10 ms period)

/* Sets up the PIT to generate system clock ticks at a specified rate */
extern void pit_init(void);

/* Handles the Programmable Interval Timer (PIT) interrupt */
void pit_handler(void);

#endif /* _PIT_H */
