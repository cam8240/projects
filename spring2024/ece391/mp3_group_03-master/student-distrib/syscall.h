#ifndef SYSCALL_H
#define SYSCALL_H

#include "types.h"
#include "filesystem.h"

#define ARG_LENGTH 128 // Max length of input argument buffer based on max buffer length
#define MAX_ARG_LENGTH 32 // Max length of input argument characters
#define MAX_FD_NUM 8 // Max possible number of fd processes running
#define MAX_PID_NUM 6 // Max possible number of pid running
#define PROGRAM_ADDR 0x08048000 // Program address start location based on docs
#define MAX_TERMINAL_NUM 3 // Max number of terminals
#define BACKGROUND_VIDEO_ADDR 0xB9000 // Start address of background memory

// Declarations for different data sizes
#define _4K 4096
#define _8K 8192
#define _4M 0x400000
#define _8M 0x800000
#define _128M 0x08000000

/* Process Control Block (PCB) struct initialization */
typedef struct pcb {
    file_descriptor_t fd_array[MAX_FD_NUM];
    uint32_t pid;             // Process ID
    uint32_t tid;             // Terminal ID
    uint32_t parent_pid;      // Parent Process ID
    uint32_t tss;             // TSS
    uint32_t esp;             // Stack Pointer
    uint32_t ebp;             // Base Pointer
    uint32_t eip;             // Instruction Pointer, saved during context switch
    uint32_t esp_user;        // Stack Pointer
    uint32_t ebp_user;        // Base Pointer
    uint32_t eip_user;        // Instruction Pointer, saved during context switch
    int8_t args[MAX_CHAR];  // Argument buffer
} pcb_t;

/* System call prototypes based on lab documentation */
int32_t halt(uint8_t status);
int32_t execute(const uint8_t* command);
int32_t read(int32_t fd, void* buf, int32_t nbytes);
int32_t write(int32_t fd, const void* buf, int32_t nbytes);
int32_t open(const uint8_t* filename);
int32_t close(int32_t fd);
int32_t getargs(uint8_t* buf, int32_t nbytes);
int32_t vidmap (uint8_t** screen_start);
int32_t set_handler (int32_t signum, void* handler_address);
int32_t sigreturn (void);
int32_t vidremap(uint8_t* phys_addr);

pcb_t *schedule_control[MAX_TERMINAL_NUM]; // Array to hold pointers to the Process Control Blocks (PCBs) for each terminal
uint8_t current_scheduled_terminal; // Variable to hold the current terminal active in scheduling

/* Helper function to initialize file descriptors */
extern void initialize_fd(pcb_t* pcb_ptr);

/* TLB flushing function declaration from assembly */
extern void flush_tlb(void);

/* Get the current address to the pcb using pid */
pcb_t* get_curr_pcb(int32_t pid);

/* Get the current address to the pcb using a temp_pid */
pcb_t* get_tmp_pcb();

/* Function to retrieve the current process ID */
int get_curr_pid();

/* Syscall function declaration from assembly */
extern void syscall_entry();

/* Helper function for the scheduler to manage process switching */
extern void schedule_helper(void);

/* Updates paging for video memory based on the specified terminal ID */
extern void update_video_memory_paging(int terminal_id);

/* Initializes syscall-related structures and settings */
extern void syscall_init(void); 

/*Finds the terminal associated with a given process ID */
extern int find_terminal_for_process(int pid);

/* Retrieves the PID of the most recently active process */
extern int get_most_recent_pid();

#endif /* SYSCALL_H */
