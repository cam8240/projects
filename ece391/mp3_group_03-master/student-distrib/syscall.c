#include "syscall.h"
#include "x86_desc.h"
#include "paging.h"
#include "terminal.h"
#include "lib.h"
#include "types.h"
#include "rtc.h"
#include "keyboard.h"


// Function to find the terminal ID for a given process ID
int find_terminal_for_process(int pid);

// When a process is created:
void assign_process_to_terminal(int pid, int tid);

// When a process is terminated:
void remove_process_from_terminal(int pid);

// Local PID and terminal values
uint32_t curr_pid_val = 0;
uint32_t parent_pid = 0;
uint8_t next_terminal = -1;
int last_flag = 0;

// PCB pointer and buffer initilization
pcb_t *pcb_ptr = NULL;
int pcb_buffer[6] = {0, 0, 0, 0 ,0 ,0};

/* Terminal struct initilization to hold tid, pid, in use info */
typedef struct process_terminal_mapping {
    int pid;    // Process ID
    int tid;    // Terminal ID associated with the process
    int in_use; // Flag indicating whether this mapping is currently in use
} process_terminal_mapping_t;

process_terminal_mapping_t process_terminal_map[MAX_PID_NUM];


// Buffers to hold the filename and argument from the command
uint8_t filename[MAX_CHAR] = {0};
uint8_t argument[ARG_LENGTH] = {0};

int base_shell_pid[MAX_TERMINAL_NUM]; // Array to hold the base shell PID for each terminal
int latest_pid[MAX_TERMINAL_NUM]; // Array to hold the latest PID for latest terminal


/*
 * syscall_init(void)
 * Inputs: None
 * Outputs: None
 * Side effects: Initializes PID and terminal mappings to default states
 * Description: Resets all entries in the process_terminal_map and initializes base shell PID and latest PID arrays
 * for all terminals to -1. This function sets up the system for handling processes by marking all potential PIDs
 * and terminals as not in use at startup.
 */
void syscall_init(void) {
    int i;
    // Loop through the maximum number of process IDs
    for (i = 0; i < MAX_PID_NUM; i++) {
        process_terminal_map[i].pid = -1; // Initialize process ID to -1, indicating empty
        process_terminal_map[i].tid = -1; // Initialize terminal ID to -1, indicating no terminal is assigned
        process_terminal_map[i].in_use = 0; // Set in_use flag to 0, marking the map entry as not in use
    }
    // Loop through the maximum number of terminals
    for (i = 0; i < MAX_TERMINAL_NUM; i++) {
        base_shell_pid[i] = -1; // Initialize base shell PID for each terminal to -1
        latest_pid[i] = -1; // Set the latest process ID for each terminal to -1
    }
}


/* Initializes the file descriptor table for a process
 * void init_file_table(pcb_t *pcb)
 * Inputs: pcb - pointer to the process control block where the file descriptor table is located
 * Outputs: None
 * Effects: Sets up stdin and stdout and marks the rest of the file descriptors as available
 */
void init_file_table(pcb_t *pcb) {
    int i;
    for (i = 0; i < MAX_FD_NUM; i++) { // MAX_FD_NUM to cover the entire fd_array
        if (i == 0) {
            // Initialize stdin
            pcb->fd_array[i].operation_ptr = (uint32_t)&in_ops;
            pcb->fd_array[i].inode_idx = 0; // Standard for unused inodes
            pcb->fd_array[i].file_position = 0; // Standard initialization
            pcb->fd_array[i].flags = 1;
        } else if (i == 1) {
            // Initialize stdout
            pcb->fd_array[i].operation_ptr = (uint32_t)&out_ops;
            pcb->fd_array[i].inode_idx = 0; // Standard for unused inodes
            pcb->fd_array[i].file_position = 0; // Standard initialization
            pcb->fd_array[i].flags = 1;
        } else {
            // Mark the rest as empty
            pcb->fd_array[i].inode_idx = 0;
            pcb->fd_array[i].file_position = 0;
            pcb->fd_array[i].flags = 0;
            pcb->fd_array[i].operation_ptr = (uint32_t)&out_ops;
        }
    }
}

/* Terminates a process and returns to the parent process
 * int32_t halt(uint8_t status)
 * Inputs: status - Status code indicating the reason for halting.
 * Outputs: Returns 0 on successful halt, -1 if error occurs.
 * Side effects: Terminates a process, cleans up resources, and restores parent process control.
 * Description: This function halts a specified process, cleans up its resources, switches context
 *              to the parent process if available, and resets the process control block and terminal data.
 */
int32_t halt(uint8_t status) {
    cli();
    // Setup function variables
    uint32_t return_status;

    // NULL check for buffer to ensure there is a value to clear
    if(pcb_buffer[terminals[current_scheduled_terminal].pid] == 0){
        return -1;  // Return error if the buffer is already empty
    }

    // Retrieve the current PCB and remove the process from terminal management
    pcb_t* tmp_pcb_ptr = get_curr_pcb(terminals[current_scheduled_terminal].pid);
    remove_process_from_terminal(tmp_pcb_ptr->pid); // Update terminal struct by removing old process

    // Prevent exiting the base shell; reinitialize if attempted
    if (terminals[current_scheduled_terminal].pid == 0 || terminals[current_scheduled_terminal].pid == 1 || terminals[current_scheduled_terminal].pid == 2){
        pcb_buffer[current_scheduled_terminal] = 0;  // Clear PCB buffer entry
        terminals[current_scheduled_terminal].pid = current_scheduled_terminal;  // Reset PID to terminal number
        curr_pid_val = current_scheduled_terminal;  // Reset current PID to terminal number
        execute((const uint8_t*)"shell");  // Relaunch shell
    }

    // Clear PCB buffer entry for the current PID
    pcb_buffer[terminals[current_scheduled_terminal].pid] = 0;

    // Set up to continue execution with the parent process
    parent_pid = tmp_pcb_ptr->parent_pid;
    pcb_t *parent_ptr = get_curr_pcb(parent_pid);  // Retrieve the parent's PCB
    terminals[current_scheduled_terminal].pid = parent_ptr->pid;  // Update terminal's PID to parent's PID

    if(parent_ptr != NULL){
        // Intended to restore parent context; commented to avoid page fault
        schedule_control[current_scheduled_terminal] = parent_ptr;
    }
    
    // Clear PCB buffer entry for halted process
    pcb_buffer[tmp_pcb_ptr->pid] = 0;

    // Restore paging to parent process
    // Calculate the base physical address for user-space pages based on the current process's PID
    uint32_t phys_addr = _8M + (terminals[current_scheduled_terminal].pid * _4M); // 8 MB offset plus 4 MB per process
    
    // Convert the physical address to a page directory index and assign it to the user space entry
    page_directory[INDEX_USER_SPACE].table_address = phys_addr / _4K; // Convert byte address to page table index

    flush_tlb();  // Flush the TLB after updating page directory

    // Close any file descriptors that are open
    int i;
    for (i = 0; i < MAX_FD_NUM; i++) {
        if (tmp_pcb_ptr->fd_array[i].flags != 0) {
            close(i);  // Close each file descriptor
        }
    }

    // Update video memory paging for the current terminal
    // update_video_memory_paging(current_scheduled_terminal);

    /* Set tss.esp0 for the current process's kernel stack top, ensuring isolated kernel-mode 
    stacks by allocating 8KB per process and adjusting for 4 bytes to align the stack properly. */
    tss.esp0 = _8M - (terminals[current_scheduled_terminal].pid * _8K) - sizeof(int32_t);

    // Set return status from input value, adjusting based on exit code conventions
    return_status = (status == 255) ? 256 : (uint32_t)status;
    putc('\n');  // Print a newline for visual separation of output
    sti();
    // Assembler instruction to restore context and return
    asm volatile(
            "movl %0, %%esp    \n\t"  // Restore stack pointer
            "movl %1, %%ebp    \n\t"  // Restore base pointer
            "movl %2, %%eax    \n\t"  // Load return status into EAX
            "leave             \n\t"  // Prepare to leave current function frame
            "ret               \n\t"  // Return from function, using restored stack frame
            :
            : "r"(tmp_pcb_ptr->esp_user), "r"(tmp_pcb_ptr->ebp_user), "r"(return_status)
            : "esp", "ebp", "eax"
        );  
    return 0;  // Indicate successful halt
}

/* Parses a command string into executable name and arguments
 * command_length(const uint8_t *command, int8_t *file_cmd, int8_t *file_arg, int max_length)
 * Inputs: command - the full command string, file_cmd - buffer for the executable name, file_arg - buffer for the arguments, max_length - max size of buffers
 * Outputs: None
 * Effects: Separates the command string into executable name and arguments
 */
void command_length(const uint8_t *command, uint8_t *file_cmd, uint8_t *file_arg, int max_length) {
    int command_len = 0;
    int arg_len = 0;
    int arg_len_counter = 0;
    int i = 0, arg_start = 0;

    // Initialize command and argument strings
    memset(file_cmd, 0, max_length);
    memset(file_arg, 0, max_length);

    // Skip spaces before the command
    while (command[i] == ' ') {
        i++;
    }

    // Go through command to fill file_cmd
    while (command[i] != ' ' && command[i] != '\0' && command_len < max_length) {
        file_cmd[command_len++] = command[i++];
    }
    file_cmd[command_len] = '\0';  // Null-terminate

    // Skip spaces between command and argument to find the start of the argument
    while (command[i] == ' ') {
        ++i;
    }
    arg_start = i;  // Mark the start of the argument

    // Determine the length of the argument without modifying it
    while (command[i] != '\0') {
        if (++arg_len_counter > MAX_ARG_LENGTH) {
            return;
        }
        ++i;
    }

    // Reset i to start of the argument
    i = arg_start;

    // Parse argument within allowed length
    while (command[i] != '\0' && command[i] != ' ' && arg_len < arg_len_counter) {
        file_arg[arg_len++] = command[i++];
    }
    file_arg[arg_len] = '\0';  // Null-terminate

    // Now you can check if there are non-space characters after the argument
    while (command[i] == ' ') {
        i++; // Skip trailing spaces
    }

    // If the next character is not the end of the string, it's an error
    if (command[i] != '\0') {
        // Clear the file_arg buffer since the input is incorrect
        memset(file_arg, 0, max_length);
    }
}


/* Attempts to execute a new program
 * int32_t execute(const uint8_t* command)
 * Inputs: command - space-separated string containing the file name to execute and arguments
 * Outputs: Returns -1 on failure, 0 on success
 * Effects: Loads and executes a new program, creating a new process
 */
int32_t execute(const uint8_t* command) {
    cli();

    // Setup function variables
    int pcb_full = 0;
    int i;
    uint32_t esp_tmp, ebp_tmp;

    // Validate command input
    if (command == NULL || *command == '\0') {
        return -1;
    }

    // Split the command into filename and argument
    command_length(command, filename, argument, MAX_CHAR);

    dentry_t dentry;
    if (read_dentry_by_name(filename, &dentry) == -1) {
        return -1; // File not found or not executable
    }

    // Check file validity
    uint8_t elf_buf[4]; // Buffer for reading ELF header
    if (read_data(dentry.inode_num, 0, elf_buf, sizeof(elf_buf)) == -1 ||
        elf_buf[0] != 0x7F || elf_buf[1] != 'E' || elf_buf[2] != 'L' || elf_buf[3] != 'F') {
        return -1; // Not an ELF executable
    }
    
    // Find an available PID and mark it as used
    for(i = 0; i < MAX_PID_NUM; i++) {  // MAX_PID_NUM (6) total
        if(pcb_buffer[i] == 0){
            curr_pid_val = i; // Assign the current PID value to the first available slot
            pcb_buffer[i] = 1; // Mark this PID as now in use
            pcb_full = 1; // Set flag indicating that a PCB slot has been filled
            break;
        }
    }

    // Check if no available PID was found
    if(!pcb_full){
        printf("too many processes\n");
        return 0;
    }

    assign_process_to_terminal(curr_pid_val, current_terminal); // Update terminal struct by adding new process

    // Configure paging for the new proces and flush tlb
    // Calculate the base physical address for user-space pages based on the current process's PID
    uint32_t phys_addr = _8M + (curr_pid_val * _4M); // 8 MB offset plus 4 MB per process

    // Convert the physical address to a page directory index and assign it to the user space entry
    page_directory[INDEX_USER_SPACE].table_address = phys_addr / _4K; // Convert byte address to page table index
    flush_tlb();

    // Obtain a pointer to the inode structure based on the directory entry's inode number
    inode_t* inode_ptr = (inode_t*)(inode_start + dentry.inode_num);

    // Load the executable into memory
    if (read_data(dentry.inode_num, 0, (uint8_t*)PROGRAM_ADDR, inode_ptr->length) == -1) {
        return -1;
    }

    // Initialize Process Control Block (PCB) for the new process and set up file descriptors
    pcb_ptr = get_curr_pcb(curr_pid_val); // Get the PCB associated with the current PID
    pcb_ptr->pid = curr_pid_val;          // Set the PID in the PCB
    pcb_ptr->parent_pid = parent_pid;     // Record the PID of the parent process
    
    // Determine if initializing the base shell for a terminal
    if (base_shell_pid[current_terminal] == -1 && filename[0] == 's' && filename[1] == 'h' && 
        filename[2] == 'e' && filename[3] == 'l' && filename[4] == 'l') {
        parent_pid = current_terminal;  // Assign current terminal as the parent for the base shell
        terminals[current_terminal].pid = current_terminal;  // Set terminal's PID to its own identifier (for base shell)

    } else {
        parent_pid = terminals[current_terminal].pid;  // Set parent PID to the current terminal's active process
        terminals[current_terminal].pid = curr_pid_val;  // Update terminal's active process to new PID
    }

    pcb_ptr->tid = current_terminal;  // Set the terminal ID in the PCB
    pcb_ptr->parent_pid = parent_pid;  // Update PCB's parent PID

    if(pcb_ptr != NULL){
        schedule_control[current_scheduled_terminal] = pcb_ptr; // CAUSES PAGE FAULT
    }


    latest_pid[pcb_ptr->tid] = curr_pid_val; // Gets most recent pid value and stores it in that terminal 

    if (base_shell_pid[pcb_ptr->tid] == -1 && filename[0] == 's' && filename[1] == 'h' && 
        filename[2] == 'e' && filename[3] == 'l' && filename[4] == 'l') {
        base_shell_pid[pcb_ptr->tid] = pcb_ptr->tid; // Update the base shell PID for this terminal
    }


    // Call helper function to setup file table using pcb
    init_file_table(pcb_ptr);

    strncpy(pcb_ptr->args, (int8_t*)argument, MAX_CHAR);

    uint8_t eip_buf[4]; //Buffer to store the EIP value, bytes 24-27 of the file
    read_data(dentry.inode_num, 24, eip_buf, sizeof(int32_t)); //Store the eip from the file into the eip
    
    uint32_t eip_val = *((uint32_t*)eip_buf); // Set eip to buffer size
    uint32_t esp_val = _128M + _4M - sizeof(int32_t); // Set esp to user space + one page and align

    // pcb_ptr->eip_user = eip_val; // Set new eip
    // pcb_ptr->esp_user = esp_val; // Set new esp

    // Context switch
    tss.esp0 = _8M - (curr_pid_val * _8K) - sizeof(int32_t); // Stack pointer for kernel mode and align
    pcb_ptr->tss = tss.esp0;

    // Save esp, ebp
    asm volatile(
        "movl %%esp, %0     \n\t"
        "movl %%ebp, %1     \n\t"
        : "=r"(esp_tmp), "=r"(ebp_tmp)
    );
    pcb_ptr->esp_user = esp_tmp;
    pcb_ptr->ebp_user = ebp_tmp;
    sti();

    // IRET
    asm volatile (
        "movw %%ax, %%ds        \n\t" // Set user data segment
        "pushl %%eax            \n\t" // Push USER_DS
        "pushl %%ebx            \n\t" // Push new stack pointer for user program
        "pushfl                 \n\t" // Push flags
        "popl %%eax             \n\t" // Pop eax
        "orl $0x200, %%eax      \n\t" // Enable interrupts in flags
        "pushl %%eax            \n\t" // Push modified flags
        "pushl %%ecx            \n\t" // Push USER_CS
        "pushl %%edx            \n\t" // Push eip_val (address of the first instruction)
        "iret                   \n\t" // Interrupt return - switches to user mode
         :
         : "a"(USER_DS), "b"(esp_val), "c"(USER_CS), "d"(eip_val)
        : "memory"
    );
    return 0;
}

/* Reads data from a file or device
 * int32_t read(int32_t fd, void* buf, int32_t nbytes)
 * Inputs: fd - file descriptor to read from, buf - buffer to store read data, nbytes - number of bytes to read
 * Outputs: Returns the number of bytes read, or -1 on failure
 * Effects: Reads data into buf from the file or device associated with fd
 */
int32_t read(int32_t fd, void* buf, int32_t nbytes) {
    sti();
    int32_t return_val;
    // Check file descriptor bounds and buffer pointer
    if(fd < 0 || fd > (MAX_FD_NUM - 1) || buf == NULL || fd == 1 || nbytes < 0){ // Read cannot output (stdout)
        return -1;
    }
    // Get updated pcb pointer and store as tmp val
    pcb_t* tmp_pcb_ptr = get_tmp_pcb();
    if (tmp_pcb_ptr == NULL) {
        // Failed to get PCB
        return -1;
    }
    // Check if the file descriptor is in use
    if(tmp_pcb_ptr->fd_array[fd].flags == 0){
        return -1;
    }
    // Get the file operations pointer for the fd
    file_operations_t *sys_read = (file_operations_t*) tmp_pcb_ptr->fd_array[fd].operation_ptr;
    if (sys_read == NULL || sys_read->f_read == NULL) {
        return -1; // Operation not supported or file descriptor not properly initialized
    }
    // Specific read function based on the file/device type
    return_val = sys_read->f_read(&(tmp_pcb_ptr->fd_array[fd]), buf, nbytes);
    return return_val;
}

/* Writes data to a file or device
 * int32_t write(int32_t fd, const void* buf, int32_t nbytes)
 * Inputs: fd - file descriptor to write to, buf - buffer containing data to write, nbytes - number of bytes to write
 * Outputs: Returns the number of bytes written, or -1 on failure
 * Effects: Writes data from buf to the file or device associated with fd
 */
int32_t write(int32_t fd, const void* buf, int32_t nbytes) {
    int32_t return_val;
    cli();
    // Check file descriptor bounds and buffer pointer
    if(fd < 0 || fd > (MAX_FD_NUM - 1) || buf == NULL || fd == 0 || nbytes < 0) { // Write cannot input (stdin)
        return -1;
    }
    // Get updated pcb pointer and store as tmp val
    pcb_t* tmp_pcb_ptr = get_tmp_pcb();
    if (tmp_pcb_ptr == NULL) {
        // Failed to get PCB
        return -1;
    }
    // Check if the file descriptor is in use
    if(tmp_pcb_ptr->fd_array[fd].flags == 0) {
        return -1;
    }
    // Get the file operations pointer for the fd
    file_operations_t *sys_write = (file_operations_t*) tmp_pcb_ptr->fd_array[fd].operation_ptr;
    if (sys_write == NULL || sys_write->f_write == NULL) {
        return -1; // Operation not supported or file descriptor not properly initialized
    }
    return_val = sys_write->f_write(fd, buf, nbytes);
    // Specific write function based on the file/device type
    sti();
    return return_val;
}

/* Opens a file
int32_t open(const uint8_t* filename)
Inputs: filename - the name of the file to be opened by the function
Outputs: Returns -1 on an error, on success returns the index of the file descriptor for the file
Effects: Opens the file specified by the filename input
*/
int32_t open(const uint8_t* filename) {
    // Check for a null filename pointer
    if (filename == NULL) {
        return -1;
    }
    // Attempt to read the directory entry for the given filename.
    dentry_t dentry;
    if (read_dentry_by_name(filename, &dentry) == -1){
        return -1;
    }

    // Get updated pcb pointer and store as tmp val
    pcb_t* tmp_pcb_ptr = get_tmp_pcb();
    if (tmp_pcb_ptr == NULL) {
        // Failed to get PCB
        return -1;
    }
    
    // Search for an unused file descriptor
    int i;
    for (i = 2; i < MAX_FD_NUM; i++){
        // Check if the file descriptor is unused
        if (tmp_pcb_ptr->fd_array[i].flags != 1){
            tmp_pcb_ptr->fd_array[i].flags = 1; // Mark the file descriptor as used.
            tmp_pcb_ptr->fd_array[i].file_position = 0; // Initialize file position to the start.
            tmp_pcb_ptr->fd_array[i].inode_idx = dentry.inode_num; // Assign inode index for file types

            switch (dentry.type) {
            case FILE_TYPE_RTC:
                // Open the RTC
                tmp_pcb_ptr->fd_array[i].operation_ptr = (uint32_t)&rtc_ops; // Set the operations pointer to RTC operations
                rtc_open(filename); // Call the open function for RTC
                break;
            case FILE_TYPE_DIRECTORY:
                // Open the directory
                tmp_pcb_ptr->fd_array[i].operation_ptr = (uint32_t)&dir_ops; // Set the operations pointer to directory operations
                dir_open((uint8_t*)filename, &tmp_pcb_ptr->fd_array[i]); // Call the open function for directory
                break;
            case FILE_TYPE_REGULAR:
                // Open the regular file
                tmp_pcb_ptr->fd_array[i].operation_ptr = (uint32_t)&file_ops; // Set the operations pointer to file operations
                file_open((uint8_t*)filename, &tmp_pcb_ptr->fd_array[i]); // Call the open function for regular files
                break;
            default:
                // Reset the flags and return an error
                tmp_pcb_ptr->fd_array[i].flags = 0; // Clear file descriptor flags indicating unused or error
                break;
            }   
            return i; // Return the file descriptor index, successful allocation
        }
    }
    return -1; // Return -1 if no free file descriptor is found
}

/* Closes a file
int32_t close(int32_t fd)
Inputs: fd - the file descriptor number that specifies which file to close
Outputs: Returns -1 on an error, 0 on success
Effects: Closes the file specified by the fd input
*/
int32_t close(int32_t fd) {
    // Prevent closing default file descriptors and check if fd is in valid range
    if (fd < 2 || fd > (MAX_FD_NUM - 1)){
        return -1;
    }
    // Get updated pcb pointer and store as tmp val
    pcb_t* tmp_pcb_ptr = get_tmp_pcb();
    if (tmp_pcb_ptr == NULL) {
        // Failed to get PCB
        return -1;
    }
    // Check if the file descriptor is currently in use
    if(tmp_pcb_ptr->fd_array[fd].flags == 0) {
        return -1;
    }
    // Mark the file descriptor as free
    tmp_pcb_ptr->fd_array[fd].flags = 0;
    return 0;
}


/* Reads command line arguments into a buffer
int32_t getargs(uint8_t* buf, int32_t nbytes)
Inputs: buf - the buffer that arguments data will be written into
        nbytes - number of bytes to write
Outputs: Returns -1 on an error, 0 on success
Effects: Reads nbytes of the arguments into the buffer specified by the buf parameter
*/
int32_t getargs(uint8_t* buf, int32_t nbytes) {
    if (buf == NULL){ // Makes sure that the location of the buffer is non-NULL
        return -1;
    }
    pcb_t* tmp_pcb_ptr = get_tmp_pcb(); // Retrieves pointer to current pcb based on the current pid val
    if (tmp_pcb_ptr->args[0] != NULL){ 
        // Copies nbytes of the arguments into buf if the arguments are non-NULL
        strncpy((int8_t*)buf, (int8_t*)(tmp_pcb_ptr->args), nbytes);
        return 0;
    }
    return -1;
}


/* Maps the text-mode video memory into user space at a pre-set virtual address
int32_t vidmap(uint8_t** screen_start)
Inputs: screen_start - virtual address that points to video memory
Outputs: Returns -1 on an error, 0 on success
Effects: Writes the text-mode memory location into the memory location specified by the caller
*/
int32_t vidmap(uint8_t** screen_start) {
    // Check if the pointer to the screen start is NULL, indicating an invalid argument
    if (screen_start == NULL) { 
        return -1; // Return error for invalid pointer
    }

    int phys_addr = (uint32_t)screen_start;
    // Ensure the address is within the user space virtual memory range assigned for this purpose
    if (phys_addr >= (ADDR_USER_SPACE_BASE + _4M) || phys_addr < ADDR_USER_SPACE_BASE) { 
        return -1;
    }

    // Map the screen start pointer to a designated virtual address where video memory will be accessible
    *screen_start = (uint8_t*)(ADDR_USER_SPACE_BASE + _8M);

    // Configure the first entry of the video page table to map to the physical video memory
    video_page_table[0].page_address = ADDR_VIDEO_MEMORY / _4K; // Set the physical address of video memory divided by page size
    video_page_table[0].user = 1; // Set the user mode bit to allow access from user space
    video_page_table[0].present = 1;

    // Configure the page directory entry for video memory
    page_directory[INDEX_VIDMEM].table_address = ((unsigned int)(video_page_table)) / _4K; // Set the address of the video page table
    page_directory[INDEX_VIDMEM].present = 1; // Mark the directory entry as present
    page_directory[INDEX_VIDMEM].size = 0; // Indicate that this is not a 4MB page, but rather uses a page table
    page_directory[INDEX_VIDMEM].user = 1;
    page_directory[INDEX_VIDMEM].read_write = 1;

    flush_tlb();

    return 0;
}

/* Changes the default action when a signal is received
int32_t set_handler(int32_t signum, void* handler_address)
Inputs: signum - Specifies which signal's handler to change
        handler_address - Points to a user-level function to be run when the signal is received
Outputs: Returns -1 on an error, 0 on success
Effects: OS does not support signals, so -1 is returned on default
*/
int32_t set_handler(int32_t signum, void* handler_address) {
    return -1;
}

/* Copies the hardware context that was on the user-level stack back onto the processor
int32_t sigreturn(void)
Inputs: None
Outputs: Returns -1 on an error, 0 on success
Effects: OS does not support signals, so -1 is returned on default
*/
int32_t sigreturn(void) {
    return -1;
}

/* Retrieves a pointer to the current process control block (PCB) based on the current PID. */
pcb_t* get_tmp_pcb(){
    // Calculate the start address of the PCB for the given PID
    // The -1 accounts for PID starting from 0 and the memory layout being top-down
    return (pcb_t*)(_8M - (curr_pid_val + 1) * _8K);
}


/* Returns the PCB for a specific process, identified by its PID.*/
pcb_t* get_curr_pcb(int32_t pid){
    // Calculate the start address of the PCB for the given PID
    // The -1 accounts for PID starting from 0 and the memory layout being top-down
    uint32_t addr = _8M - (pid + 1) * _8K;
    return (pcb_t*)addr;
}

/* Returns the PID of the currently running process, or -1 if no process is active. */
int get_curr_pid() {
    if (pcb_ptr != NULL) {
        return pcb_ptr->pid;  // Return the PID from the current process control block
    } else {
        return -1;  // Return -1 or some error code if no process is currently running
    }
}


/*
 * Function: get_most_recent_pid
 * Inputs: None
 * Outputs: Returns the highest PID currently in use.
 * Side effects: None
 * Description: Searches through the process-terminal map to find the highest process ID (PID) that is currently in use.
 */
int get_most_recent_pid() {
    int most_recent_pid = -1;  // Initialize to -1 to indicate no process found
    int i;

    for (i = 0; i < MAX_PID_NUM; i++) {
        if (process_terminal_map[i].in_use) {
            // Check if this PID is the largest we've found so far
            if (process_terminal_map[i].pid > most_recent_pid) {
                most_recent_pid = process_terminal_map[i].pid;  // Update most recent PID
            }
        }
    }

    return most_recent_pid;  // Return the largest PID found or -1 if none
}

/*
 * Function: find_terminal_for_process
 * Inputs: pid - Process ID
 * Outputs: Returns the terminal ID associated with the given PID or -1 if not found.
 * Side effects: None
 * Description: Looks up the terminal ID for a given process ID within the process-terminal map.
 */
int find_terminal_for_process(int pid) {
    int i;
    for (i = 0; i < MAX_PID_NUM; i++) {
        if (process_terminal_map[i].in_use && process_terminal_map[i].pid == pid) {
            return process_terminal_map[i].tid;  // Return the terminal ID associated with this PID
        }
    }
    return -1; // Return -1 if the terminal ID for the PID is not found
}

/*
 * Function: assign_process_to_terminal
 * Inputs: pid - Process ID, tid - Terminal ID
 * Outputs: None
 * Side effects: Maps a process ID to a terminal ID in the process-terminal map.
 * Description: Assigns a process ID to a specific terminal ID, marking the entry as in use.
 */
void assign_process_to_terminal(int pid, int tid) {
    int i;
    for (i = 0; i < MAX_PID_NUM; i++) {
        if (!process_terminal_map[i].in_use) {
            process_terminal_map[i].pid = pid;  // Set the process ID
            process_terminal_map[i].tid = tid;  // Set the terminal ID
            process_terminal_map[i].in_use = 1;  // Mark this entry as in use
            break;
        }
    }
}

/*
 * Function: remove_process_from_terminal
 * Inputs: pid - Process ID
 * Outputs: None
 * Side effects: Clears a process ID from the process-terminal map, marking the entry as not in use.
 * Description: Removes a process ID from its associated terminal in the process-terminal map, resetting the entry.
 */
void remove_process_from_terminal(int pid) {
    int i;
    for (i = 0; i < MAX_PID_NUM; i++) {
        if (process_terminal_map[i].pid == pid) {
            process_terminal_map[i].pid = -1;  // Clear the process ID
            process_terminal_map[i].tid = -1;  // Clear the terminal ID
            process_terminal_map[i].in_use = 0;  // Mark this entry as not in use
            break;
        }
    }
}

/*
 * Function: update_video_memory_paging(int terminal_id)
 * Inputs: terminal_id
 * Outputs: None
 * Side effects: Updates the paginng and changes the video mem based on scheduling.
 * Description: Updates video memory, updates page tables, flushes tlb.
 */
void update_video_memory_paging(int terminal_id) {
    cli();

    uint32_t video_mem_physical_addr;
    if (current_terminal == terminal_id) {
        // If the terminal is active, map video memory to the main address
        video_mem_physical_addr = ADDR_VIDEO_MEMORY;
    } else {
        // Otherwise, map video memory to a background buffer
        video_mem_physical_addr = BACKGROUND_VIDEO_ADDR + (terminal_id * VIDEO_MEM_SIZE);
    }

    // Update the video memory page table with the new physical address
    video_page_table[0].page_address = video_mem_physical_addr >> 12;
    first_page_table[ADDR_VIDEO_MEMORY / PAGE_SIZE_4KB].page_address = video_mem_physical_addr >> 12;

    // Flush the TLB to ensure paging changes are applied
    flush_tlb();
    sti();
}


/*
 * Function: schedule_helper(void)
 * Inputs: None
 * Outputs: None
 * Side effects: Changes the currently scheduled terminal and process, updates system state
 * Description: Manages the scheduling of processes across terminals in a round-robin manner.
 *              It handles context saving for the current process, initiates new shells as needed,
 *              and context restores for the next process. It also updates the paging for the next process.
 */
void schedule_helper(void) {
    // Calculate the next scheduled terminal/process in a round-robin fashion
    int next_terminal = (current_scheduled_terminal + 1) % MAX_TERMINAL_NUM;

    // Retrieve the PCB of the current and next scheduled process
    pcb_t* current_pcb = schedule_control[current_scheduled_terminal];
    pcb_t* next_pcb_ptr = schedule_control[next_terminal];

    // Context save if the current process is running
    if (current_pcb != NULL) {
        current_pcb->tss = tss.esp0;
        asm volatile(
            "movl %%esp, %0     \n\t"
            "movl %%ebp, %1     \n\t"
            : "=r"(current_pcb->esp), "=r"(current_pcb->ebp)
        );
    }

    // Check if the next terminal has an active shell and loop to start a terminal in each shell
    if (terminals[next_terminal].active == 0) {
        terminals[next_terminal].active = 1;
        // If no active shell, execute a new shell
        terminals[current_scheduled_terminal].pid = curr_pid_val;
        current_scheduled_terminal = next_terminal;
        switch_terminal(next_terminal);
        execute((const uint8_t*)"shell");
    } else {
        current_scheduled_terminal = next_terminal;
    }

    // Check to see if scheduler needs to update video memory paging based on scheduled terminal
    if(current_terminal == next_terminal){
        update_video_memory_paging(current_terminal);
    }else{
        update_video_memory_paging(next_terminal);
    }

    // Make sure terminal is starting on first terminal as simple correction
    if(last_flag == 0){
        switch_terminal(current_scheduled_terminal);
        last_flag = 1;
    }
    // Ensure the next process PCB is valid
    if (next_pcb_ptr == NULL) {
        return; // Skip scheduling if no next process is available
    }

    // Update the page directory for the next process
    uint32_t phys_addr = _8M + (next_pcb_ptr->pid * _4M);
    page_directory[INDEX_USER_SPACE].table_address = phys_addr / _4K;
    flush_tlb(); // Flush the TLB after updating page directory

    // Update TSS for the next process
    tss.esp0 = next_pcb_ptr->tss;

    // Context restore for the next process
    asm volatile(
        "movl %0, %%esp     \n\t"
        "movl %1, %%ebp     \n\t"
        "leave              \n\t"
        "ret                \n\t"
        :
        : "r"(next_pcb_ptr->esp), "r"(next_pcb_ptr->ebp)
    );
}
