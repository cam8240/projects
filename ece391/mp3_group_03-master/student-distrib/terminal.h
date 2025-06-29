#ifndef TERMINAL_H
#define TERMINAL_H

#include "types.h"

#define TERMINAL_BUFFER_SIZE 128 // Defines the maximum size for the terminal input buffer
#define TERMINAL_WIDTH 80
#define TERMINAL_HEIGHT 25
#define ATTRIB 0x07 // Black on grey text (0x0A is matrix green!)
#define VIDEO_MEMORY_ADDRESS 0xB8000 // Start of video memory
#define VIDEO_MEM_SIZE 0x1000  // Size of the video memory for one terminal

/* I had to do some reasearch to find these ports */
#define VGA_INDEX_REGISTER 0x3D4 // Port to select VGA internal register for reading/writing
#define VGA_DATA_REGISTER 0x3D5 // Port to read from/write to the selected VGA register
#define CURSOR_HIGH_BYTE 0x0E // High 8 bits of cursor position
#define CURSOR_LOW_BYTE 0x0F // Low 8 bits of cursor position
#define NUM_TERMINALS 3

typedef struct {
    char buffer[TERMINAL_BUFFER_SIZE];
    int tid; // Terminal identifier, unique for each terminal.
    int pid; // Process identifier associated with the terminal.
    int buffer_position;
    volatile int buffer_ready;
    int cursor_x, cursor_y;
    char* video_memory; // Pointer to the start of video memory for this terminal
    int active;
} terminal_t;

terminal_t terminals[NUM_TERMINALS]; // Array of terminals

extern terminal_t *scheduled_term_ptr;
extern terminal_t *displayed_term_ptr;

int current_terminal;

int terminal_flag;

// Initialize screen location to 0
int screen_x;
int screen_y;

extern char* video_mem;

/* Initializes the terminal */
extern void terminal_init(void);

/* Clears the terminal screen and resets cursor position */
extern void terminal_clear_screen(void);

/* Clears one space in terminal for backspace */
void terminal_backspace(void);

/* Adds one space in terminal for new char */
void terminal_putc(char c);

void update_cursor(int row, int col);

/* Reads data from the terminal buffer into a given buffer */
int32_t terminal_read(int32_t fd, void* buf, int32_t nbytes);

/* Writes data from a given buffer to the terminal */
int32_t terminal_write(int32_t fd, const void* buf, int32_t nbytes);

/* Opens the terminal */
int32_t terminal_open(const uint8_t* filename);

/* Closes the terminal */
int32_t terminal_close(int32_t fd);

/* Switches between multiple terminals */
void switch_terminal(int32_t new_terminal_index);

/* Sets paging based on current temrinal id */
void set_paging(int term_id);

#endif /* TERMINAL_H */
