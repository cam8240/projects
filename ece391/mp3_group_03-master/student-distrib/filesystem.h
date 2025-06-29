#ifndef FILESYSTEM_H
#define FILESYSTEM_H

#include "types.h"

#define MAX_FILES 63 // Maximum number of files in the filesystem
#define MAX_CHAR 32 // Maximum number of characters in a filename
#define MAX_INODES 1023 // Maximum number of inodes
#define BLOCK_SIZE 4096 // Size of a data block in bytes
#define BOOT_RESERVED_SIZE 52 // Reserved size in boot block
#define DENTRY_RESERVED_SIZE 24 // Reserved size in directory entry

// Define file types to distinguish between RTC, directories, and regular files
#define FILE_TYPE_RTC 0
#define FILE_TYPE_DIRECTORY 1
#define FILE_TYPE_REGULAR 2

// Status flags for file descriptor usage
#define IN_USE 1

// Define the starting address of the file system in memory
extern unsigned int FS_START_ADDR;

// Structure defining a directory entry
typedef struct dentry {
    int8_t filename[MAX_CHAR]; // File name
    uint32_t type; // File type (RTC, directory, or regular file)
    uint32_t inode_num; // Index to the inode
    uint8_t boot_block_reserved[DENTRY_RESERVED_SIZE]; // Reserved bytes in boot block
} dentry_t;

// Structure defining an inode
typedef struct inode {
    uint32_t length; // Length of the file
    uint32_t data_blocks[MAX_INODES]; // Data blocks of the file
} inode_t;

// Structure defining a data block
typedef struct data_block {
    uint8_t data_blocks[BLOCK_SIZE]; // Array of data blocks
} data_block_t;

// Structure for a file descriptor
typedef struct file_descriptor {
    uint32_t operation_ptr; // Pointer to the operations table
    uint32_t inode_idx; // Index to inode
    uint32_t file_position; // Current position in the file
    uint32_t flags; // Flag to indicate if the descriptor is in use
} file_descriptor_t;

file_descriptor_t fd_array[MAX_FILES]; // Array of file descriptors

// Structure for the boot block
typedef struct boot_block {
    uint32_t num_dir_entries; // Number of directory entries
    uint32_t inode_num; // Number of inodes
    uint32_t data_block_num; // Number of data blocks
    uint8_t boot_block_reserved[BOOT_RESERVED_SIZE]; // Reserved bytes in boot block
    dentry_t dentries[MAX_FILES]; // Array of directory entries
} boot_block_t;

// Global variables for the file system base pointers
extern boot_block_t* boot_block_start;
extern inode_t* inode_start;

// Function pointer types for file operations
typedef int32_t (*file_read_t)(file_descriptor_t*, void*, int32_t);
typedef int32_t (*file_write_t)(int32_t, const void*, int32_t);
typedef int32_t (*file_open_t)(const uint8_t*, file_descriptor_t*);
typedef int32_t (*file_close_t)(int32_t);

// Structure for file operation function pointers
typedef struct file_operations {
    file_read_t f_read;
    file_write_t f_write;
    file_open_t f_open;
    file_close_t f_close;
} file_operations_t;

// Function pointer types for device driver operations
typedef int32_t (*driver_read_t)(int32_t, void*, int32_t);
typedef int32_t (*driver_write_t)(int32_t, const void*, int32_t);
typedef int32_t (*driver_open_t)(const uint8_t*);
typedef int32_t (*driver_close_t)(int32_t);

// Structure for driver operation function pointers
typedef struct driver_operations {
    driver_read_t driver_read;
    driver_write_t driver_write;
    driver_open_t driver_open;
    driver_close_t driver_close;
} driver_operations_t;

// Extern declarations for file and driver operations
extern file_operations_t file_ops;
extern file_operations_t dir_ops;
extern driver_operations_t rtc_ops;
extern driver_operations_t in_ops;
extern driver_operations_t out_ops;

extern void filesystem_init(void); // Function to initialize the file system

// File system operations functions
int32_t read_dentry_by_name(const uint8_t* fname, dentry_t* dentry);
int32_t read_dentry_by_index(uint32_t index, dentry_t* dentry);
int32_t read_data(uint32_t inode, uint32_t offset, uint8_t* buf, uint32_t length);

// File operations functions
int32_t file_read(file_descriptor_t* fd, void* buf, int32_t nbytes);
int32_t file_write(int32_t fd, const void* buf, int32_t nbytes);
int32_t file_open(const uint8_t* filename, file_descriptor_t* fd);
int32_t file_close(int32_t fd);

// Directory operations functions
int32_t dir_read(file_descriptor_t* fd, void* buf, int32_t nbytes);
int32_t dir_write(int32_t fd, const void* buf, int32_t nbytes);
int32_t dir_open(const uint8_t* filename, file_descriptor_t* fd);
int32_t dir_close(int32_t fd);

#endif  /* FILESYSTEM_H */
