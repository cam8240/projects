/* tuxctl-ioctl.c
 *
 * Driver (skeleton) for the mp2 tuxcontrollers for ECE391 at UIUC.
 *
 * Mark Murphy 2006
 * Andrew Ofisher 2007
 * Steve Lumetta 12-13 Sep 2009
 * Puskar Naha 2013
 */

#include <asm/current.h>
#include <asm/uaccess.h>

#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/sched.h>
#include <linux/file.h>
#include <linux/miscdevice.h>
#include <linux/kdev_t.h>
#include <linux/tty.h>
#include <linux/spinlock.h>

#include "tuxctl-ld.h"
#include "tuxctl-ioctl.h"
#include "mtcp.h"

#define debug(str, ...) \
	printk(KERN_DEBUG "%s: " str, __FUNCTION__, ## __VA_ARGS__)

int tux_ack;
unsigned int tux_button;
unsigned long LED_safety;
static spinlock_t tux_lock;
unsigned char startup_func[2] = {MTCP_BIOC_ON, MTCP_LED_USR};
int tuxctl_ioctl_led(struct tty_struct* tty, unsigned long arg);

/************************ Protocol Implementation *************************/

/* tuxctl_handle_packet()
 * IMPORTANT : Read the header for tuxctl_ldisc_data_callback() in 
 * tuxctl-ld.c. It calls this function, so all warnings there apply 
 * here as well.
 */

/* 
 * tuxctl_handle_packet
 *   DESCRIPTION: Processes incoming packets from the TUX controller, handling acknowledgments, 
 *                button events, and device resets. It updates global state based on packet content.
 *   INPUTS: tty_struct* tty - Pointer to the associated TTY device structure.
 *           unsigned char* packet - Array containing the received packet data
 *   OUTPUTS: Modifies global variables and reinitializes the TUX or update LEDs
 *   RETURN VALUE: none
 *   SIDE EFFECTS: none
 */
void tuxctl_handle_packet (struct tty_struct* tty, unsigned char* packet) {
    unsigned a, b, c;
	unsigned long packet_flag;

    a = packet[0]; /* Avoid printk() sign extending the 8-bit */
    b = packet[1]; /* values when printing them. */
    c = packet[2];

switch (a) {
    case MTCP_ACK:
        spin_lock_irqsave(&tux_lock, packet_flag); // Lock and save the interrupt state
        tux_ack = 1;                         // Acknowledge received
        spin_unlock_irqrestore(&tux_lock, packet_flag); // Unlock and restore the interrupt state
        break;
    case MTCP_POLL: // Fall-through to MTCP_BIOC_EVENT
    case MTCP_BIOC_EVENT:
        spin_lock_irqsave(&tux_lock, packet_flag);
        // Reset tux_button for MTCP_BIOC_EVENT, for MTCP_POLL it's a no-op
        if (a == MTCP_BIOC_EVENT) tux_button &= 0x00;
        // Update button states (shift to 11110000)
		tux_button |= (~c & 0x02) << 5; // Checks if 0010 position is 0 (Up), shifts 5
		tux_button |= (~c & 0x04) << 3; // Checks if 0100 position is 0 (Down), shifts 3
		tux_button |= (~c & 0x09) << 4; // Checks if 1001 position is 0 (Left, Down), shifts 4
        tux_button |= (~b & 0x0F);      // Checks if 1111 position is 0 (button R,L,U,D), shifts 0
        spin_unlock_irqrestore(&tux_lock, packet_flag);
        break;
    case MTCP_RESET:
        // Calls to reinitialize the TUX device and restore LED state
        // Ensure these functions are safe to call in this context
        tuxctl_ioctl(tty, NULL, TUX_INIT, 0);
        tuxctl_ioctl_led(tty, LED_safety);
        break;
    default:
        break;
	}
    /*printk("packet : %x %x %x\n", a, b, c); */
}

/******** IMPORTANT NOTE: READ THIS BEFORE IMPLEMENTING THE IOCTLS ************
 *                                                                            *
 * The ioctls should not spend any time waiting for responses to the commands *
 * they send to the controller. The data is sent over the serial line at      *
 * 9600 BAUD. At this rate, a byte takes approximately 1 millisecond to       *
 * transmit; this means that there will be about 9 milliseconds between       *
 * the time you request that the low-level serial driver send the             *
 * 6-byte SET_LEDS packet and the time the 3-byte ACK packet finishes         *
 * arriving. This is far too long a time for a system call to take. The       *
 * ioctls should return immediately with success if their parameters are      *
 * valid.                                                                     *
 *                                                                            *
 ******************************************************************************/

/* 
 * tuxctl_ioctl
 *   DESCRIPTION: Handles ioctl commands for the TUX device, including initialization, button reading, 
 *                and LED control.
 *                The interrupt-driven approach is utilized to efficiently handle specific events from 
 *                the Tux controller, such as acknowledgments (MTCP_ACK), button events (MTCP_BIOC_EVENT), 
 *                and reset signals (MTCP_RESET), by executing corresponding actions within a switch 
 *                statement upon receiving an interrupt signal.
 *                The use of spin_lock_irqsave and spin_unlock_irqrestore functions are interrupt context, 
 *                where it's necessary to disable local interrupts on the current processor while holding a 
 *                spinlock. This prevents deadlock situations and ensures data consistency when accessing 
 *                shared resources like tux_ack or tux_button.
 *   INPUTS: tty_struct* tty - Pointer to the TTY device structure
 *           struct file* file - Unused, included for compatibility
 *           unsigned cmd - Command code to execute
 *           unsigned long arg - Command-specific argument
 *   OUTPUTS: none
 *   RETURN VALUE: 0 on success, -EINVAL for invalid commands or arguments, -EFAULT for user-space copy failures.
 *   SIDE EFFECTS: none
 */
int tuxctl_ioctl(struct tty_struct* tty, struct file* file, unsigned cmd, unsigned long arg){
    unsigned long flags; // Use with spinlock

    switch (cmd) {
        case TUX_INIT:
            // Acquire lock and reset tux_button state
            spin_lock_irqsave(&tux_lock, flags);
            tux_button = 0x00; // Reset button state
            tux_ack = 0; // Reset acknowledgment state
            spin_unlock_irqrestore(&tux_lock, flags);

            // Send initialization commands to the TUX device
            if (tuxctl_ldisc_put(tty, startup_func, 2) < 0) {
                return -EINVAL; // Return error if initialization fails
            }
            return 0; // Successful initialization

        case TUX_BUTTONS:
            if (!arg) return -EINVAL; // Validate the argument pointer
            // Acquire lock to safely access shared data
            spin_lock_irqsave(&tux_lock, flags);
            // Attempt to copy tux_button state to user space
            if (copy_to_user((int __user *)arg, &tux_button, sizeof(tux_button))) {
                spin_unlock_irqrestore(&tux_lock, flags);
                return -EFAULT; // Return error if copy to user fails
            }
            spin_unlock_irqrestore(&tux_lock, flags);
            return 0; // Successful copy

        case TUX_SET_LED:
            // Check if an acknowledgment is pending before proceeding
            spin_lock_irqsave(&tux_lock, flags);
            if (!tux_ack) {
                spin_unlock_irqrestore(&tux_lock, flags);
                return -EINVAL; // Return error if awaiting previous command's acknowledgment
            }
            tux_ack = 0; // Reset acknowledgment state
            spin_unlock_irqrestore(&tux_lock, flags);
            // Forward LED setting command
            return tuxctl_ioctl_led(tty, arg) == 0 ? 0 : -EINVAL;

        // Cases without actions
        case TUX_LED_ACK:
        case TUX_LED_REQUEST:
        case TUX_READ_LED:
            return 0;
        default:
            return -EINVAL; // Return error for unrecognized commands
    }
}

/* 
 * tuxctl_ioctl_led
 *   DESCRIPTION: Controls the LED display on the TUX controller by sending a command with 
 * 				  specific configurations for each LED. The function configures the LEDs based 
 * 				  on arg which encodes LED on/off states, decimal point settings, and individual 
 * 				  LED values. It prepares a command buffer according to the TUX protocol and 
 * 				  sends it to the TUX device for execution.
 *   INPUTS: tty_struct* tty - a pointer to the tty device structure associated with the TUX controller.
 *           unsigned long arg - a 32-bit argument encoding LED settings. The highest byte specifies 
 * 			 	decimal point settings, the next highest byte specifies which LEDs are on, and the 
 * 				lower two bytes specify the values for the LEDs
 *   OUTPUTS: none
 *   RETURN VALUE: Returns 0 on successful execution of the command to update LED states. Returns a 
 * 				   negative error code if the command fails to be sent to the TUX device
 *   SIDE EFFECTS: Modifies the global variable LED_safety to store the last command sent to the 
 * 				   device for safety purposes
 */
int tuxctl_ioctl_led(struct tty_struct* tty, unsigned long arg) {
    int i;
    unsigned char buffer[BUFFER_LEDS]; // Buffer to hold the LED command and data (6 bytes)
    unsigned char decimal[COUNT_LEDS];  // Stores decimal point settings for each LED (LED bytes 0-3)
    unsigned char led[COUNT_LEDS];  // Stores the value for each LED (LED bytes 0-3)
    buffer[0] = MTCP_LED_SET; // The command byte to set the LED states
    buffer[1] = MASK_LEDS; // The mask specifying which LEDs are to be set
    LED_safety = arg; // Store the argument for safety and future reference

    // Extract LED values and decimal point settings from the argument
    for (i = 0; i < COUNT_LEDS; i++) {
        led[i] = (arg >> (i * COUNT_LEDS)) & MASK_LEDS; // Shift and mask to get each LED's value
        // Shifts 3 bytes to place decimal in correct spet and chek to see if disabled
        // The low 4 bits of the highest byte (bits 27:24) specify whether the corresponding decimal 
        // points should be turned on (shift 24 loop 4)
        decimal[i] = (arg >> 24) & (0x01 << i); // Determine the decimal point setting for each LED
    }
    // Populate the buffer with LED values and apply decimal points
    for (i = 2; i < BUFFER_LEDS; i++) {
        // Initialize buffer[i] to 0 to ensure a clean state for each LED.
        buffer[i] = 0;
        // Check if the current LED is enabled; if so, set its value.
        // The low 4 bits of the third byte specifies which LED’s should be turned on (shift 16 loop 4)
        if (((arg >> (16 + i - 2)) & 0x01) == 0x01) {
            // Set LED value from the LED_CHAR_ARRAY if the LED is enabled.
            buffer[i] = LED_CHAR_ARRAY[(int)led[i-2]];
        }
        // Independently apply the decimal point for this LED, regardless of whether the LED is displaying a numeric value.
        if (decimal[i-2]) {
            buffer[i] |= 0x10; // Apply decimal point
        }
    }
    // Send the configured buffer to the TUX device
    return tuxctl_ldisc_put(tty, buffer, BUFFER_LEDS);
}