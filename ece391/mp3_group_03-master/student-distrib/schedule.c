#include "schedule.h"
#include "x86_desc.h"
#include "paging.h"
#include "terminal.h"
#include "lib.h"
#include "types.h"
#include "rtc.h"
#include "i8259.h"
#include "keyboard.h"
#include "syscall.h"


/* schedule_init(void)
 * Initializes the scheduler for handling multiple terminals.
 * Inputs: None
 * Outputs: None
 * Effects: Sets up an initial state for the scheduler by clearing the schedule control
 *          array and resetting the number of active processes to zero. This is essential
 *          for starting the task scheduling cleanly, ensuring no terminal has an active
 *          process assigned at the initialization stage.
 */
void schedule_init(void) {
    int i; // Loop index

    // Reset the count of active processes to zero
    current_scheduled_terminal = 0;

    // Initialize all terminal scheduling controls to NULL, indicating no active process at startup
    for (i = 0; i < MAX_TERMINAL_NUM; i++) {
        schedule_control[i] = NULL; // Set each terminal's scheduling slot to NULL
    }
    return;
}


/**
 * void schedule(void)
 * Description: Handles process scheduling for each terminal, swapping the currently
 *              running process with the next one determined by a round-robin policy.
 * Inputs: None
 * Outputs: None
 * Side effects: Changes the currently running process, updates TSS and hardware contexts,
 *               potentially launches a base shell if a terminal has no active processes.
 */
void schedule_handler(void) {
   schedule_helper();
}
