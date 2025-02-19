#ifndef RTC_H
#define RTC_H

#include "types.h"

#define INDEX_PORT 0x70
#define READ_WRITE_PORT 0x71
#define SEL_A_DIS_NMI 0x8A
#define INDEX_PORT_MASK 0x80

#define FREQUENCY_LOW 2 // Minimum rtc frequency
#define FREQUENCY_HIGH 1024 // Maximum rtc frequency
#define FREQUENCY_MASK 0x0F // rtc frequency mask value (lower bits)
#define UPPER_MASK 0xF0 // rtc frequency mask value (upper bits)
#define FRAME_MAX 16 // Maximum rtc frequency frame rate

#define REGISTER_A  0x0A
#define REGISTER_B  0x0B
#define REGISTER_C  0x0C

/* Initializes the RTC and sets the interrupt frequency */
extern void rtc_init(void);

/* Handles RTC interrupts */
void rtc_handler(void);

/* Blocks until an RTC interrupt occurs */
int32_t rtc_read(int32_t fd, void* buf, int32_t nbytes);

/* Sets the RTC frequency to a new value specified in the buffer */
int32_t rtc_write(int32_t fd, const void* buf, int32_t nbytes);

/* Opens the RTC device, resetting the frequency to 2Hz */
int32_t rtc_open(const uint8_t* filename);

/* Closes the RTC device, potentially resetting or cleaning up state */
int32_t rtc_close(int32_t fd);

/* For testing interrupts */
extern void test_interrupts(void);

#endif /* RTC_H */
