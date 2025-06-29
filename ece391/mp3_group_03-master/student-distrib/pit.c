#include "pit.h"
#include "rtc.h"
#include "i8259.h"
#include "lib.h"
#include "schedule.h"
#include "syscall.h"

/* pit_init(void)
 * Initializes the Programmable Interval Timer (PIT) for system timing.
 * Inputs: None
 * Outputs: None
 * Effects: Sets up the PIT to generate system clock ticks at a specified rate. This configuration
 *          involves setting the command mode and divisor to achieve a 100Hz tick rate (10ms per tick).
 *          Additionally, it ensures the PIT is connected to the correct interrupt request line (IRQ 0),
 *          enabling it to properly handle timer interrupts.
 */
void pit_init(void) {
    outb(0x34, PIT_MODE_REG); // Command byte 0x34 = 00 11 010 0 (Select channel 0, lobyte/hibyte, rate generator)

    // Calculate the divisor for a 10ms (100Hz) tick rate
    uint16_t divisor = PIT_FREQUENCY / TARGET_FREQUENCY;

    // Set frequency divisor low byte and the high byte
    outb((uint8_t)(divisor & 0xFF), PIT_CHANNEL_0);       // Set low byte
    outb((uint8_t)((divisor >> 8) & 0xFF), PIT_CHANNEL_0); // Set high byte

    // Connect the PIT to the correct IRQ line (IRQ 0)
    enable_irq(0);
}

/* pit_handler(void)
 * Inputs: None
 * Outputs: None
 * Effects: Handles the Programmable Interval Timer (PIT) interrupt. Disables interrupts to ensure 
 * atomic operations. Invokes the scheduler to  switch tasks based on timing and priorities.
 */
void pit_handler(void) {
    send_eoi(0); // PIT eoi irq number
    schedule_handler(); // Call scheduling
}
