// All necessary declarations for the Tux Controller driver must be in this file

#ifndef TUXCTL_H
#define TUXCTL_H

#define TUX_SET_LED _IOR('E', 0x10, unsigned long)
#define TUX_READ_LED _IOW('E', 0x11, unsigned long*)
#define TUX_BUTTONS _IOW('E', 0x12, unsigned long*)
#define TUX_INIT _IO('E', 0x13)
#define TUX_LED_REQUEST _IO('E', 0x14)
#define TUX_LED_ACK _IO('E', 0x15)

/* - Byte 0: The packet and which LEDs are being targeted.
 * - Bits 7-4 (0 | 1 | 0 | 1) are a fixed pattern, indicating the type of the packet.
 * - Bits 3-1 are used to indicate additional flags. In Packet 0, bit 2 (A1) is 0, 
 *   and in Packet 1, it is 1, which differentiates between the two packet types.
 * - Bit 0 (A0) is used in both packets.
 * 
 * - Byte 1 & Byte 2: The data for LED0 and LED1, respectively.
 * - Bit 7 (1) indicates the start of LED data.
 * - Bits 6-0 (E | F | dp | G | C | B | D) specify the segments of the 7-segment 
 *   display for each LED. The dp bit controls the decimal point.
*/
#define BUFFER_LEDS 6 // The size of the buffer used to store LED command and state information
#define COUNT_LEDS 4  // The number of LEDs that can be controlled on TUX
#define MASK_LEDS 0x000F // The value (1111) of an LED mask to mask the correct LED segments for 4-segment display

// LED representation of hex characters
#define ZERO 0xE7
#define ONE 0x06
#define TWO 0xCB
#define THREE 0x8F
#define FOUR 0x2E
#define FIVE 0xAD
#define SIX 0xED
#define SEVEN 0x86
#define EIGHT 0xEF
#define NINE 0xAE
#define A 0xEE
#define B 0x6D
#define C 0xE1
#define D 0x4F
#define E 0xE9
#define F 0xE8

// Array to hold set of characters for LEDs
unsigned char LED_CHAR_ARRAY[16] = {ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, A, B, C, D, E, F};

#endif
