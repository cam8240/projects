#include "keyboard.h"
#include "i8259.h"
#include "lib.h"
#include "terminal.h"
#include "syscall.h"

// Define keyboard data location and number of scancodes in array
#define KEYBOARD_DATA 0x60
#define NUM_SCANCODES 58

// Define special key scancodes
#define KEYBOARD_DATA 0x60
#define SPACE_SCANCODE 0x39
#define TAB_SCANCODE 0x0F
#define CAPS_LOCK_PRESS 0x3A
#define LEFT_SHIFT_PRESS 0x2A
#define RIGHT_SHIFT_PRESS 0x36
#define LEFT_SHIFT_RELEASE 0xAA
#define RIGHT_SHIFT_RELEASE 0xB6
#define CTRL_PRESS 0x1D
#define CTRL_RELEASE 0x9D
#define BACKSPACE 0x0E
#define ENTER 0x1C
#define CTRL_L 0x26
#define ALT_PRESS 0x38
#define ALT_RELEASE 0xB8
#define F1 0x3B
#define F2 0x3C
#define F3 0x3D

/* Scancodes based on OSDEV */
char keys[NUM_SCANCODES][2] = {
    {'\0', '\0'}, {'\0', '\0'}, {'1', '!'}, {'2', '@'},
    {'3', '#'}, {'4', '$'}, {'5', '%'}, {'6', '^'},
    {'7', '&'}, {'8', '*'}, {'9', '('}, {'0', ')'},
    {'-', '_'}, {'=', '+'}, {'\b', '\b'}, {'\t', '\t'},
    {'q', 'Q'}, {'w', 'W'}, {'e', 'E'}, {'r', 'R'},
    {'t', 'T'}, {'y', 'Y'}, {'u', 'U'}, {'i', 'I'},
    {'o', 'O'}, {'p', 'P'}, {'[', '{'}, {']', '}'},
    {'\n', '\n'}, {'\0', '\0'}, {'a', 'A'}, {'s', 'S'},
    {'d', 'D'}, {'f', 'F'}, {'g', 'G'}, {'h', 'H'},
    {'j', 'J'}, {'k', 'K'}, {'l', 'L'}, {';', ':'},
    {'\'', '"'}, {'`', '~'}, {'\0', '\0'}, {'\\', '|'},
    {'z', 'Z'}, {'x', 'X'}, {'c', 'C'}, {'v', 'V'},
    {'b', 'B'}, {'n', 'N'}, {'m', 'M'}, {',', '<'},
    {'.', '>'}, {'/', '?'}, {'\0', '\0'}, {'\0', '\0'},
    {' ', ' '}
};


/* Key manipulation flags */
uint8_t shift_flag = 0;
uint8_t ctrl_flag = 0;
uint8_t caps_lock_flag = 0;
uint8_t alt_flag = 0;
uint8_t enter_flag = 0;

// Initializes external functions from terminal.h
void terminal_clear_screen(void);
void terminal_putc(char c);
void switch_terminal(int new_terminal_index);

/* Initializes keyboard
keyboard_init(void)
Inputs: None
Outputs: None
Effects: Initializes keyboard by enabling IRQ #1 in the PIC
*/
void keyboard_init(void) {
    enable_irq(1); // Enable keyboard IRQ
}

/* scancode_to_char(uint8_t scancode) 
 * Converts a scancode to its corresponding character considering Caps Lock and Shift.
 * Inputs: scancode - the scancode from keyboard interrupt
 * Outputs: char - the character from the scancode, considering modifier keys
 * Effects: Utilizes the global flags for Caps Lock and Shift to determine the correct character output.
 */
char scancode_to_char(uint8_t scancode) {
    char c = '\0';
    if (scancode < NUM_SCANCODES) {
        char base_char = keys[scancode][0]; // Base character without any modifiers
        char shifted_char = keys[scancode][1]; // Character with shift applied

        // Determine if the base character is a lowercase letter or an uppercase letter
        int is_lowercase_letter = base_char >= 'a' && base_char <= 'z';
        int is_uppercase_letter = base_char >= 'A' && base_char <= 'Z';

        // Handling Caps Lock and Shift together for letter keys
        if ((caps_lock_flag && !shift_flag && is_lowercase_letter) ||
            (!caps_lock_flag && shift_flag && is_lowercase_letter) ||
            (caps_lock_flag && shift_flag && is_uppercase_letter)) {
            c = shifted_char; // Produces uppercase letters
        } else if (caps_lock_flag && shift_flag && is_lowercase_letter) {
            c = base_char; // Produces lowercase letters when both are active
        } else if (shift_flag && !is_lowercase_letter && !is_uppercase_letter) {
            c = shifted_char; // Non-letter keys, affected by Shift only
        } else {
            c = base_char; // No modifiers or non-letter keys without Shift
        }
    }
    return c;
}

/* keyboard_handler(void)
 * Handles keyboard interrupts by reading the scancode and performing actions.
 * Inputs: None
 * Outputs: None
 * Effects: Processes the keyboard scancode to perform actions such as character input,
 *          handling special keys, and modifying control flags.
 */
void keyboard_handler(void) {
    send_eoi(1);
    uint8_t scancode = inb(KEYBOARD_DATA); // Read the scancode from the keyboard data port
    char c = '\0';
    int i;
    keypress_flag = 1;

    switch (scancode) {
        case CAPS_LOCK_PRESS:
            caps_lock_flag = !caps_lock_flag;
            break;
        case LEFT_SHIFT_PRESS:
        case RIGHT_SHIFT_PRESS:
            shift_flag = 1;
            break;
        case LEFT_SHIFT_RELEASE:
        case RIGHT_SHIFT_RELEASE:
            shift_flag = 0;
            break;
        case CTRL_PRESS:
            ctrl_flag = 1;
            break;
        case CTRL_RELEASE:
            ctrl_flag = 0;
            break;
        case ALT_PRESS:
            alt_flag = 1;
            break;
        case ALT_RELEASE:
            alt_flag = 0;
            break;
        case F1:
        case F2:
        case F3:
            if (alt_flag && !enter_flag) {
                int terminal_index = scancode - F1;  // This will be 0 for F1, 1 for F2, and 2 for F3
                switch_terminal(terminal_index);
            }
            break;
        case SPACE_SCANCODE:
            if (!alt_flag && !ctrl_flag) {
                terminal_putc(' ');
                update_video_memory_paging(current_terminal);
                if (terminal_flag) putc(' '); // Only print if terminal_putc was successful
                update_cursor(screen_y, screen_x);
                update_video_memory_paging(current_scheduled_terminal);
            }
            break;
        case BACKSPACE:
            if (!alt_flag && !ctrl_flag) {
                terminal_putc('\b');
                update_video_memory_paging(current_terminal);
                if (terminal_flag) putc('\b'); // Only print if terminal_putc was successful
                update_cursor(screen_y, screen_x);
                update_video_memory_paging(current_scheduled_terminal);
            }
            break;
        case ENTER:
            if (!alt_flag && !ctrl_flag) {
                terminals[current_terminal].buffer_ready = 1;
                terminal_putc('\n');
                update_video_memory_paging(current_terminal);
                if (terminal_flag) putc('\n'); // Only print if terminal_putc was successful
                update_cursor(screen_y, screen_x);
                update_video_memory_paging(current_scheduled_terminal);
            }
            break;
        case TAB_SCANCODE:
            if (!alt_flag && !ctrl_flag) {
                for (i = 0; i < 4; ++i) { // Tab is 4 spaces
                    terminal_putc(' ');
                    update_video_memory_paging(current_terminal);
                    if (terminal_flag) putc(' '); // Only print if terminal_putc was successful
                    update_cursor(screen_y, screen_x);
                    update_video_memory_paging(current_scheduled_terminal);    
                }
            }
            break;
    default:
        if (scancode & 0x80) {
            // Key release code, no action required
        } else if (ctrl_flag && scancode == CTRL_L) {
            terminal_clear_screen();
        } else if (!alt_flag && !ctrl_flag) {
            c = scancode_to_char(scancode);
            if (c != '\0') {
                terminal_putc(c);
                update_video_memory_paging(current_terminal);
                if (terminal_flag) putc(c); // Only print if terminal_putc was successful
                update_cursor(screen_y, screen_x);
                update_video_memory_paging(current_scheduled_terminal);
            }
        }
        break;
    }
    keypress_flag = 0;
}
