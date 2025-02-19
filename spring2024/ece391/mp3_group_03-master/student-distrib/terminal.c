#include "terminal.h"
#include "rtc.h"
#include "i8259.h"
#include "lib.h"
#include "syscall.h"
#include "paging.h"


terminal_t terminals[NUM_TERMINALS]; // Array of terminals

char* video_mem = (char *)VIDEO_MEMORY_ADDRESS; // Memory access

terminal_t *scheduled_term_ptr = &(terminals[0]);
terminal_t *displayed_term_ptr = &(terminals[0]);

// Physical addresses for each terminal's video memory
char* terminal_video_mem[NUM_TERMINALS] = {
    (char*) VIDEO_MEM_INACTIVE1, // Buffer for terminal 0 when inactive
    (char*) VIDEO_MEM_INACTIVE2, // Buffer for terminal 1 when inactive
    (char*) VIDEO_MEM_INACTIVE3  // Buffer for terminal 2 when inactive
};


void putc(uint8_t c);


/* update_cursor(int row, int col)
 * Inputs: None
 * Outputs: None
 * Effects: Helper function to update cursor position in hardware
 */
void update_cursor(int row, int col) {
        // Calculate the position of the cursor based on row and column
        unsigned short position = (row * TERMINAL_WIDTH) + col; // Convert row and column to a linear offset

        // Sending the low byte of the cursor position
        outb(CURSOR_LOW_BYTE, VGA_INDEX_REGISTER); // Select cursor low byte
        outb((unsigned char)(position & 0xFF), VGA_DATA_REGISTER); // Send the low byte of the position to the VGA data register

        // Sending the high byte of the cursor position
        outb(CURSOR_HIGH_BYTE, VGA_INDEX_REGISTER); // Select cursor high byte
        outb((unsigned char)((position >> 8) & 0xFF), VGA_DATA_REGISTER); // Send the high byte of the position to the VGA data register
}


/* terminal_init(void)
 * Inputs: None
 * Outputs: None
 * Effects: Resets the terminal structure and clears the screen.
 */
void terminal_init(void) {
    int i;
    for (i = 0; i < NUM_TERMINALS; i++) {
        // Reset terminal structure
        memset(&terminals[i], 0, sizeof(terminal_t));
        
        // Set the starting cursor positions to the top-left corner
        terminals[i].tid = i; // Set terminal ID.
        terminals[i].pid = -1; // Initialize process ID to -1, indicating no process initially.
        terminals[i].buffer_position = 0; // Start with the buffer position at the beginning.
        terminals[i].buffer_ready = 0; // Mark the buffer as not ready for reading.
        terminals[i].cursor_x = 0; // Initialize cursor x-position at the start of the line.
        terminals[i].cursor_y = 0; // Initialize cursor y-position at the top of the terminal.
        terminals[i].video_memory = terminal_video_mem[i]; // Assign a segment of video memory to the terminal.
        terminals[i].active = 0; // Set the terminal as inactive initially.

        current_terminal = 0; // Initilizes the current terminal to 0 to start

        set_paging(i);


        
        // Clear the screen and initialize the hardware cursor position for each terminal
        terminal_clear_screen();
        update_cursor(terminals[i].cursor_x, terminals[i].cursor_y); // directly use 0, 0 here for clarity
        
        flush_tlb();
    }
}

/* terminal_open(const uint8_t *filename)
 * Inputs: filename - Not used in this context.
 * Outputs: Always returns 0 (success).
 * Effects: None
 */
int32_t terminal_open(const uint8_t *filename) {
    return 0;
}

/* terminal_close(int32_t fd)
 * Inputs: fd
 * Outputs: Returns 0
 * Effects: None
 */
int32_t terminal_close(int32_t fd) {
    return 0;
}

/* terminal_read(int32_t fd, void *buf, int32_t nbytes)
 * Inputs: fd - Not used, buffer - Destination buf, nbytes - Maximum bytes to read
 * Outputs: Number of bytes read into buffer
 * Effects: Copies data from the terminal's internal buffer to the provided buffer up to nbytes.
 */
int32_t terminal_read(int32_t fd, void *buf, int32_t nbytes) {
    if (!buf || nbytes <= 0) return -1; // Return error if buffer is null or nbytes is non-positive

    while (terminals[current_scheduled_terminal].buffer_ready == 0); // Wait for the buffer to become ready
    cli(); // Disable interrupts to protect buffer during access
    int bytes_to_read = nbytes < TERMINAL_BUFFER_SIZE ? nbytes : TERMINAL_BUFFER_SIZE; // Calculate the number of bytes to read
    memcpy(buf, terminals[current_scheduled_terminal].buffer, bytes_to_read); // Copy data from terminal buffer to user buffer

    // Reset and clear the internal buffer
    memset(terminals[current_scheduled_terminal].buffer, 0, TERMINAL_BUFFER_SIZE); // Clear the buffer
    terminals[current_scheduled_terminal].buffer_ready = 0; // Mark buffer as not ready
    terminals[current_scheduled_terminal].buffer_position = 0; // Reset buffer position
    sti(); // Enable interrupts

    return bytes_to_read; // Return the actual number of bytes read
}

/* terminal_write(int32_t fd, const void *buf, int32_t nbytes)
 * Inputs: fd - Not used, buf - Data to write, nbytes - Number of bytes to write
 * Outputs: Number of bytes written
 * Effects: Writes the provided data to the terminal screen.
 */
int32_t terminal_write(int32_t fd, const void *buf, int32_t nbytes) {
    if (!buf || nbytes <= 0) return -1; // Return error if buffer is null or nbytes is non-positive

    char *char_buf = (char*)buf; // Cast void buffer to char buffer for character processing
    cli(); // Disable interrupts during screen write
    int32_t i;
    for (i = 0; i < nbytes; i++) {
        if (char_buf[i] != '\0') { // Check for non-null characters
            putc(char_buf[i]); // Output character to screen
        }
    }
    sti(); // Enable interrupts
    return nbytes; // Return number of bytes processed
}

/*
 * terminal_clear_screen(void)
 * Inputs: None
 * Outputs: None
 * Side effects: Clears the screen of the current terminal and resets cursor position.
 * Description: This function clears the physical video memory, resets the cursor position,
 * and updates the display buffer to ensure the terminal is visually cleared.
 */
void terminal_clear_screen() {
    cli(); // Disable interrupts to prevent conflicts during screen clearing

    // Clear the physical video memory using the clear function
    clear(); 

    // Clear the video memory buffer of the current terminal
    memset(terminals[current_terminal].video_memory, 0, VIDEO_MEM_SIZE); 

    int32_t i;
    // Fill the terminal video memory with blank spaces and set attributes
    for (i = 0; i < TERMINAL_HEIGHT * TERMINAL_WIDTH; i++) {
        ((uint16_t*)terminals[current_terminal].video_memory)[i] = (' ' | (ATTRIB << 8));
    }

    // If current terminal is displayed, copy its video memory to the main video memory
    if (terminals[current_terminal].video_memory == video_mem) {
        memcpy(video_mem, terminals[current_terminal].video_memory, VIDEO_MEM_SIZE);
    }

    // Reset the cursor position in the terminal structure
    terminals[current_terminal].cursor_x = 0;
    terminals[current_terminal].cursor_y = 0;
    update_cursor(terminals[current_terminal].cursor_y, terminals[current_terminal].cursor_x); // Update the hardware cursor position

    sti(); // Re-enable interrupts
}

/*
 * terminal_scroll(void)
 * Inputs: None
 * Outputs: None
 * Side effects: Scrolls the display of the current terminal up by one row.
 * Description: This function shifts all lines of the terminal display up by one row,
 * clears the last row, and updates the cursor position to the beginning of the last line.
 */
void terminal_scroll(void) {
    cli(); // Disable interrupts to ensure scrolling operation is atomic

    char *video_memory = terminals[current_terminal].video_memory; // Local pointer to the terminal's video memory
    int row_size = TERMINAL_WIDTH * 2; // Each character and attribute pair occupies 2 bytes in VGA text mode
    int i;

    // Loop through all rows except the last, moving each up by one row
    for (i = 0; i < TERMINAL_HEIGHT - 1; i++) {
        memmove(video_memory + (i * row_size), video_memory + ((i + 1) * row_size), row_size);
    }

    // Clear the last row to make it blank after scrolling
    int32_t last_row_start = TERMINAL_WIDTH * (TERMINAL_HEIGHT - 1) * 2; // Start position of the last row in video memory
    for (i = 0; i < TERMINAL_WIDTH; i++) {
        *(uint16_t *)(video_memory + last_row_start + (i * 2)) = ' ' | (ATTRIB << 8); // Set each character to a blank space with default attributes
    }

    // Set the cursor position to the start of the last line after scrolling
    screen_x = 0; // Reset horizontal position of the cursor
    screen_y = TERMINAL_HEIGHT - 1; // Vertical position is the last line

    // Update the hardware cursor to reflect the new position
    update_cursor(screen_y, screen_x);

    sti(); // Re-enable interrupts
}

/*
 * terminal_putc(char c)
 * Inputs: c - The character to process and potentially add to the terminal buffer
 * Outputs: None
 * Side effects: Adds a character to the terminal's input buffer, handles special characters.
 * Description: This function processes a single character input for the terminal. It handles 
 * special characters. The function modifies the terminal's buffer. It sets a flag to indicate 
 * a successful operation. It ignores NULL characters and does not exceed the buffer size limitations.
 */
void terminal_putc(char c) {
    terminal_flag = 0; // Assume failure by default, indicating no successful operation

    if (c == '\0') { // If the character is NULL, ignore and return
        return;
    }

    // Handle newline or carriage return
    if (c == '\n' || c == '\r') {
        terminals[current_terminal].buffer_position = 0; // Reset buffer position to start
        terminal_flag = 1; // Indicate successful processing of newline or return
        return;
    }

    // Handle backspace character
    if (c == '\b') {
        if (terminals[current_terminal].buffer_position > 0) { // Ensure there's a character to remove
            terminals[current_terminal].buffer_position--; // Move position back by one
            terminals[current_terminal].buffer[terminals[current_terminal].buffer_position] = '\0'; // Clear the character at the new position
            terminal_flag = 1; // Indicate successful backspace operation
        }
        return;
    }
    
    // Add the character to the buffer if there is space
    if (terminals[current_terminal].buffer_position < TERMINAL_BUFFER_SIZE - 1) {
        terminals[current_terminal].buffer[terminals[current_terminal].buffer_position++] = c; // Store character and increment position
        terminal_flag = 1; // Indicate successful addition of character
    }
}

/* switch_terminal(int32_t new_terminal_index)
 * Inputs: new_terminal_index - Index of the terminal to switch to.
 * Outputs: None
 * Effects: Switches active terminal to the specified index. This function handles the transition by:
 *          1. Validating the requested terminal number.
 *          2. Checking if the terminal is already active to avoid unnecessary processing.
 *          3. Saving the state of the current terminal, including its video buffer and cursor position.
 *          4. Restoring the state of the target terminal, updating video and cursor settings to reflect the new active terminal.
 *          5. Flushing the Translation Lookaside Buffer (TLB) to ensure memory mappings are updated.
 */
void switch_terminal(int32_t new_terminal_index) {
    if (new_terminal_index < 0 || new_terminal_index >= NUM_TERMINALS || current_terminal == new_terminal_index) {
        return; // Validate terminal index and ensure not switching to the same terminal
    }

    // Disable interrupts to avoid race conditions during terminal switching
    cli();

    // Get references to the current and new terminals
    terminal_t* current_terminal_ref = &terminals[current_terminal]; 
    terminal_t* new_terminal_ref = &terminals[new_terminal_index]; 

    current_terminal_ref->cursor_x = screen_x;
    current_terminal_ref->cursor_y = screen_y;

    // Determine and handle different switching scenarios
    if (current_scheduled_terminal == current_terminal && new_terminal_index != current_scheduled_terminal) {
        // Case 1: Scheduled to non-scheduled
        /*
        copy from 0xb8000 to previous terminal cached page
        copy from new terminal cached page into 0xb8000
        remap phys offset of 0xb8000 virtual page and vidmap page to point to the currently scheduled cached page
        */
        memcpy(current_terminal_ref->video_memory, (const void*)VIDEO_MEMORY_ADDRESS, VIDEO_MEM_SIZE); // Save current to cache
        memcpy((void*)VIDEO_MEMORY_ADDRESS, new_terminal_ref->video_memory, VIDEO_MEM_SIZE); // Load new from cache
        update_video_memory_paging(current_scheduled_terminal); // Remap to current scheduled terminal
    } else if (new_terminal_index == current_scheduled_terminal){
        // Case 2: Non-scheduled to scheduled
        /* 
        remap phys offset of 0xb8000 virtual page and vidmap page to point to true 0xb8000 VGA memory
        copy from 0xb8000 to previous terminal cached page
        copy from new terminal cached page into 0xb8000
        */
        update_video_memory_paging(current_terminal); // Remap to actual VGA memory
        memcpy(current_terminal_ref->video_memory, (const void*)VIDEO_MEMORY_ADDRESS, VIDEO_MEM_SIZE); // Save current to cache
        memcpy((void*)VIDEO_MEMORY_ADDRESS, new_terminal_ref->video_memory, VIDEO_MEM_SIZE); // Load new from cache
    } else {
        // Case 3: Non-scheduled to non-scheduled
        /*
        remap phys offset of 0xb8000 virtual page and vidmap page to point to true 0xb8000 VGA memory
        copy from 0xb8000 to previous terminal cached page
        copy from new terminal cached page into 0xb8000
        remap phys offset of 0xb8000 virtual page and vidmap page to point to the currently scheduled cached page
        */
        update_video_memory_paging(current_terminal); // Remap first to actual VGA
        memcpy(current_terminal_ref->video_memory, (const void*)VIDEO_MEMORY_ADDRESS, VIDEO_MEM_SIZE); // Save current to cache
        memcpy((void*)VIDEO_MEMORY_ADDRESS, new_terminal_ref->video_memory, VIDEO_MEM_SIZE); // Load new from cache
        update_video_memory_paging(current_scheduled_terminal); // Remap to current scheduled terminal
    }

    // Update screen cursor position for the new terminal
    screen_x = new_terminal_ref->cursor_x;
    screen_y = new_terminal_ref->cursor_y;
    update_cursor(screen_y, screen_x); // Move the cursor to the correct position

    // Set the current terminal to the new terminal index
    current_terminal = new_terminal_index;

    // Re-enable interrupts
    sti();
}

void set_paging(int terminal){

    // get page table index
    uint32_t index = (uint32_t)(terminals[terminal].video_memory) >> 12;

    // set paging 
    first_page_table[index].present = 1;        
    first_page_table[index].read_write = 1;      
    first_page_table[index].user = 0;     
    first_page_table[index].page_address = index;

    // flush TLB
    flush_tlb();
}

