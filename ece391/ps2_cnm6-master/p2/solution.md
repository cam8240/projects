### P2 Solution

1.
MTCP_BIOC_ON
Usage: Enable button for button interrupt-on-change (BIOC).
Effect: Activates BIOC mode whenever any button changes state (pressed/released).
Message Returned: MTCP_ACK, which indicates that the command was received and executed successfully.

MTCP_LED_SET
Usage: Set LED display values when the computer wants to change the display.
Effect: Updates specified LEDs to given values.
Message Returned: MTCP_ACK, which indicates that the LED settings were successfully received and applied by the device.

2.
MTCP_ACK
When Sent: After successful command execution.
Information: Indicates command successfully received and executed.

MTCP_BIOC_EVENT
When Sent: On button state change in interrupt-on-change (BIOC) mode.
Information: Indicates button status change (pressed/released).

MTCP_RESET
When Sent: After device re-initialization, including a manual reset initiated by a user, a command from the computer to reset the device, or an automatic reset.
Information: Indicates device re-initialized and ready for operation.

3.
The code in tuxctl_handle_packet cannot wait because it executes in the context of an interrupt handler or a bottom half, which is a critical section of code execution where delays are not allowed, as it would block the processing of other interrupts or critical kernel tasks, leading to system instability.
