#include "rtc.h"
#include "i8259.h"
#include "lib.h"

// Global flag for RTC interrupts
volatile int rtc_interrupt_occurred = 0;

/*
flicker_rate(int32_t freq)
Inputs: frequency of the interrupts
Outputs: none
Effects: Sets the interrupt frequency while checking bounds to ensure stability
*/
int32_t flicker_rate(int32_t freq) {
    int log_val = 0;
    uint8_t tmp, frame_rate;

    // Check if frequency is within bounds and is a power of 2
    if (freq < FREQUENCY_LOW || freq > FREQUENCY_HIGH || ((freq - 1) & freq)) {
        return -1;
    }

    // Calculate the base-2 logarithm of freq to find the corresponding rate
    while (freq >>= 1) {
        log_val += 1;
    }

    // Calculate the rate to set in the RTC's register A
    frame_rate = FRAME_MAX - log_val; // This corresponds to the rate value for the RTC

    // Disable NMI and select Register A
    tmp = inb(INDEX_PORT) | INDEX_PORT_MASK; // Keeps index port and sets new bit to 1
    outb(tmp, INDEX_PORT);

    // Read the current value of Register A, then modify the rate
    outb(SEL_A_DIS_NMI, INDEX_PORT); // Select register A, disable NMI
    tmp = inb(READ_WRITE_PORT); // Read the current value of register A
    outb(SEL_A_DIS_NMI, INDEX_PORT); // Select register A again
    outb((tmp & UPPER_MASK) | frame_rate, READ_WRITE_PORT); // Set the new frequency rate
    
    // Re-enable NMI
    tmp = inb(INDEX_PORT) & 0x7F; // Same as index port and keeps lower 4 bits
    outb(tmp, INDEX_PORT);

    return 0; // Success
}

/*
rtc_init(void)
Inputs: none
Outputs: none
Effects: enables the RTC
*/
void rtc_init(void) {
    // Select RTC Register B, and disable NMI
    outb(REGISTER_B, INDEX_PORT);
    // Read the current value of Register B
    unsigned char prev = inb(READ_WRITE_PORT);
    // Re-select Register B, preparing to write the new value
    outb(REGISTER_B, INDEX_PORT);
    // Write the new value into Register B to turn on bit 6 (enable periodic interrupt)
    outb((prev | 0x40), READ_WRITE_PORT);
    // Enable IRQ line 8, which is connected to the RTC
    enable_irq(8);
    // Set the RTC to a interrupt rate
    flicker_rate(FREQUENCY_LOW);
}

/*
rtc_handler(void)
Inputs: none
Outputs: none
Effects: Handle RTC interrupts by reading interrupt status, clearing garbage, sending eoi
*/
void rtc_handler(void) {
    // Uncomment the following line to test interrupts
    //test_interrupts();
    send_eoi(8); // Send End-Of-Interrupt signal to PIC for RTC IRQ line (8)
    unsigned char garbage = inb(READ_WRITE_PORT); // Read from the RTC to acknowledge the interrupt
    (void)garbage; // Cast to void to explicitly ignore the value
    outb(REGISTER_C, INDEX_PORT); // Select RTC Register C to read the interrupt status
    inb(READ_WRITE_PORT); // Read to ensure control register is accessed correctly
    rtc_interrupt_occurred = 1; // Indicate an RTC interrupt occurred
}

/*
 * rtc_open(const uint8_t* filename)
 * Inputs: filename - A pointer to the filename
 * Outputs: 0 on success
 * Effects: Opens the RTC device, by resetting the frequency to 2Hz. 
 */
int32_t rtc_open(const uint8_t* filename) {
    flicker_rate(FREQUENCY_LOW); // Set to initial frequency
    return 0;
}

/*
 * rtc_close(int32_t fd)
 * Inputs: fd
 * Outputs: 0 on success
 * Effects: Cleans up any state or resources specific to the RTC.
 */
int32_t rtc_close(int32_t fd) {
    return 0;
}

/*
 * rtc_read(int32_t fd, void* buf, int32_t nbytes)
 * Inputs: fd, buf, nbytes
 * Outputs: 0 on success
 * Effects: Waits for the next RTC interrupt before returning.
 */
int32_t rtc_read(int32_t fd, void* buf, int32_t nbytes) {
    rtc_interrupt_occurred = 0; // Reset interrupt flag
    while (!rtc_interrupt_occurred); // Busy wait for interrupt
    rtc_interrupt_occurred = 0;
    return 0;
}

/*
 * rtc_write(int32_t fd, const void* buf, int32_t nbytes)
 * Inputs: fd; buf - Pointer to the frequency value; nbytes - sizeof(int)
 * Outputs: Number of bytes written or -1 on error
 * Effects: Changes the RTC interrupt frequency based on the value in buffer.
 */
int32_t rtc_write(int32_t fd, const void* buf, int32_t nbytes) {
    if (buf == NULL || nbytes != sizeof(int32_t)) {
        return -1; // Invalid buffer or wrong size
    }
    int freq = *(int32_t*)buf;
    // Check if freq is a power of 2 using binary
    if (freq < FREQUENCY_LOW || freq > FREQUENCY_HIGH || (freq & (freq - 1)) != 0) {
        return -1; // Validate frequency is within bounds and is a power of 2
    }
    flicker_rate(freq); // Adjust RTC frequency
    return 0;
}
