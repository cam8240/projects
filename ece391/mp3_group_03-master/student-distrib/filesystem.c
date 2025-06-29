#include "filesystem.h"
#include "lib.h"
#include "terminal.h"
#include "rtc.h"

// Function operations for regular files, directories, and terminal input/output
file_operations_t file_ops;
file_operations_t dir_ops;
driver_operations_t rtc_ops;
driver_operations_t in_ops;
driver_operations_t out_ops;

// Variable declarations
boot_block_t* boot_block_start = NULL;
inode_t* inode_start;
data_block_t* data_block_start;

/* Initializes filesystem
void filesystem_init(void)
Inputs: None
Outputs: None
Effects: Initialize blocks in perperation for filesystem
*/
void filesystem_init(void) {
    // Initialize the boot block start pointer to the start address of the filesystem
    boot_block_start = (boot_block_t*)(FS_START_ADDR);

    // Correctly initialize the inode start pointer to immediately after the boot block
    inode_start = (inode_t*)((uint8_t*)boot_block_start + sizeof(boot_block_t));

    // Correctly initialize the data block start pointer to immediately after the last inode
    data_block_start = (data_block_t*)((uint8_t*)inode_start + boot_block_start->inode_num * sizeof(inode_t));

    // Initialize the operations table for files
    file_ops.f_read = file_read;
    file_ops.f_write = file_write;
    file_ops.f_open = file_open;
    file_ops.f_close = file_close;

    // Initialize the operations table for directories
    dir_ops.f_read = dir_read;
    dir_ops.f_write = dir_write;
    dir_ops.f_open = dir_open;
    dir_ops.f_close = dir_close;

    // Initialize the operations table for RTC
    rtc_ops.driver_read = rtc_read;
    rtc_ops.driver_write = rtc_write;
    rtc_ops.driver_open = rtc_open;
    rtc_ops.driver_close = rtc_close;

    // Initialize the operations table for terminal input
    in_ops.driver_read = terminal_read;
    in_ops.driver_write = NULL;
    in_ops.driver_open = terminal_open;
    in_ops.driver_close = terminal_close;

    // Initialize the operations table for terminal output
    out_ops.driver_read = NULL;
    out_ops.driver_write = terminal_write;
    out_ops.driver_open = terminal_open;
    out_ops.driver_close = terminal_close;
}

/* Reads from a file
int32_t file_read(file_descriptor_t* fd, void* buf, int32_t nbytes)
Inputs: fd: the file descriptor telling which file to read
        buf: the buffer that will store the read data
        nbytes: the length of data to read
Outputs: Returns the number of bytes read
Effects: The input buf contains the data read from the file
*/
int32_t file_read(file_descriptor_t* fd, void* buf, int32_t nbytes) {
    // Validate input parameters: file descriptor, buffer pointer, and positive nbytes
    if (fd == NULL || buf == NULL || nbytes < 0) return -1;
    
    // Read data from the file starting at the current file position
    int32_t count = read_data(fd->inode_idx, fd->file_position, buf, nbytes);
    // Check if read_data encountered an error
    if (count == -1) return -1;

    // Update the file descriptor's position by the number of bytes read
    fd->file_position += count;
    return count;
}

/* Writes to a file
file_write(int32_t fd, const void* buf, int32_t nbytes)
Inputs: fd: the file descriptor telling which file to write
        buf: the buffer that will store the write data
        nbytes: the nbytes of data to write
Outputs: -1, read only system so the function does not return anything notable
*/
int32_t file_write(int32_t fd, const void* buf, int32_t nbytes) {
    return -1;
}

/* Opens a File
file_open(const uint8_t* filename, file_descriptor_t* fd)
Inputs: filename: the name of the file to open
        fd: the file descriptor for the file
Outputs: -1 if there is an error opening the file, 0 if a success
Effects: sets the file descriptor's flags to in use
*/
int32_t file_open(const uint8_t* filename, file_descriptor_t* fd) {
    if (fd == NULL || filename == NULL) return -1;
    if (fd->flags == IN_USE) return -1;
    
    dentry_t dentry;
    // Attempt to read the directory entry by name; on failure, return -1
    if (read_dentry_by_name(filename, &dentry) == -1){
        return -1;
    }
    // Initialize file descriptor with the directory's inode number, mark it in use, and reset file position
    fd->inode_idx = dentry.inode_num;
    fd->flags = IN_USE; // Mark the file descriptor as in use
    fd->file_position = 0; // Start reading from the beginning of the file
    
    return 0;
}

/* Closes a File
file_close(int32_t fd)
Inputs: fd: the file descriptor for the file to close
Outputs: 0 if a successfully closes the file
Effects: Also resets the file descriptor flags to empty
*/
int32_t file_close(int32_t fd) {
    return 0;
}

/* Reads data into a buffer
read_data(uint32_t inode, uint32_t offset, uint8_t* buf, uint32_t length)
Inputs: inode: the inode to read the data from
        offset: the offset to start reading from 
        buf: the buffer that will store the read data
        nbytes: the nbytes of data to read and copy into the buffer
Outputs: nbytes: the number of bytes read and copied to the buffer
Effects: Copies the data into the input buffer
*/
int32_t read_data(uint32_t inode, uint32_t offset, uint8_t* buf, uint32_t length) {
    // Check if the inode number is beyond the maximum number of inodes in the boot block
    if (inode >= boot_block_start->inode_num) return -1;
    
    // Check if the buffer pointer is null
    if (buf == NULL) return -1;

    // Get the inode pointer from the inode array start plus the inode index
    inode_t* cur_inode = inode_start + inode;

    // Return no data if the requested offset is beyond the actual file length
    if (offset >= cur_inode->length) return 0;

    uint32_t nbytes = 0; // Track the number of bytes successfully read
    while (nbytes < length) {
        // Calculate the index of the data block in the inode based on the current offset
        uint32_t cur_block_index = (offset + nbytes) / BLOCK_SIZE;

        // Return the number of bytes read if we exceed the array of data blocks
        if (cur_block_index >= MAX_INODES) return nbytes;

        // Calculate the byte index within the current block
        uint32_t cur_byte_index = (offset + nbytes) % BLOCK_SIZE;

        // Retrieve the block index from the inode's data block array
        int block = cur_inode->data_blocks[cur_block_index];
        // Return error if the block index is invalid (beyond the total number of data blocks)
        if (block >= boot_block_start->data_block_num) return -1;

        // Calculate the address of the data in the block
        uint8_t* data = (uint8_t*)data_block_start + block * BLOCK_SIZE;

        // Determine the minimum number of bytes to read from the current data block
        uint32_t remaining_bytes_in_block = BLOCK_SIZE - cur_byte_index; // Remaining bytes in the current block
        uint32_t remaining_bytes_to_read = length - nbytes; // Remaining bytes needed to fulfill the user request
        // This prevents reading beyond the block's boundary and only reads up to the amount requested
        uint32_t to_read = (remaining_bytes_in_block < remaining_bytes_to_read) ? remaining_bytes_in_block : remaining_bytes_to_read;

        // Adjust the number of bytes to read if it extends beyond the file's data
        if (nbytes + to_read > cur_inode->length - offset) {
            to_read = cur_inode->length - offset - nbytes;
        }

        // Copy the calculated amount of data from the data block to the buffer
        memcpy(buf + nbytes, data + cur_byte_index, to_read);

        // Update the total number of bytes read
        nbytes += to_read;

        // Break the loop if the end of file is reached
        if (nbytes + offset >= cur_inode->length) break;
    }

    return nbytes; // Return the total number of bytes read
}

/* Puts the corresponding data into the dentry for the input filename
read_dentry_by_name(const uint8_t *fname, dentry_t *dentry)
Inputs: fname: the name of the file that's data should be copied to the dentry
        dentry: the dentry that will eventually store the data corresponding to the file name
Outputs: -1 if there is an error, 0 if success
Effects: Copies the data for the specified file into the dentry
*/
int32_t read_dentry_by_name(const uint8_t *fname, dentry_t *dentry) {
    int i;
    if (fname == NULL || dentry == NULL) return -1;
    
    if (strlen((const char*)fname) > MAX_CHAR) {
    return -1; // Filename is too long
    }

    // Loop through the boot block entries
    for (i = 0; i < boot_block_start->num_dir_entries; i++) {
        if (strncmp((const char*)boot_block_start->dentries[i].filename, (const char*)fname, MAX_CHAR) == 0) {
            // If a match is found, copy the directory entry
            memcpy(dentry, &boot_block_start->dentries[i], sizeof(dentry_t));
            return 0;
        }
    }
    return -1;
}

/* Puts the corresponding data into the dentry for the input filename
read_dentry_by_index(uint32_t index, dentry_t* dentry)
Inputs: index: the index of the file that's data should be copied to the dentry
        dentry: the dentry that will eventually store the data corresponding to the index
Outputs: -1 if there is an error, 0 if success
Effects: Copies the data for the specified file into the dentry
*/
int32_t read_dentry_by_index(uint32_t index, dentry_t* dentry) {
    if (index >= boot_block_start->num_dir_entries || dentry == NULL) return -1;
    
    // Directly copy the directory entry from the boot block
    memcpy(dentry, &boot_block_start->dentries[index], sizeof(dentry_t));

    return 0;
}

/* Opens a Directory Entry
dir_open(const uint8_t* filename, file_descriptor_t* fd)
Inputs: dirname: the name of the directory entry to open
        fd: the file descriptor for the data block
Outputs: -1 if there is an error opening the file, 0 if a success
Effects: sets the file descriptor's flags to in use
*/
int32_t dir_open(const uint8_t* filename, file_descriptor_t* fd) {
    // Check for NULL pointers or if the file descriptor is already in use
    if (filename == NULL || fd == NULL) return -1;
    if (fd->flags == IN_USE) return -1;

    dentry_t dentry;
    // Attempt to read the directory entry by name; on failure, return -1
    if (read_dentry_by_name(filename, &dentry) != 0) {
        return -1;
    }

    // Initialize file descriptor with the directory's inode number, mark it in use, and reset file position
    fd->inode_idx = dentry.inode_num;
    fd->flags = IN_USE; // Mark the file descriptor as in use
    fd->file_position = 0; // Start reading from the beginning of the file

    return 0; 
}

/* Closes a Directory Entry
dir_close(int32_t fd)
Inputs: dirname: the name of the directory entry to close
        fd: the file descriptor for the data block
Outputs: Sets the file descriptor flag field to empty and returns 0
Effects: sets the file descriptor's flags to empty
*/
int32_t dir_close(int32_t fd) {
    return 0;
}

/* Reading a Directory Entry
dir_read(file_descriptor_t* fd, void* buf, int32_t nbytes)
Inputs: fd: the file descriptor for the data block
        buf: the buffer to be filled with the directory data
        nbytes: the length of data to be read
Outputs: Returns 0 if the file position is outside of the bounds of the total
         number of directory entries. Returns the index of the last position of
         the buffer that was populated.
Effects: Populates buffer with data from directory entry
*/
int32_t dir_read(file_descriptor_t* fd, void* buf, int32_t nbytes) {
    if (fd == NULL || buf == NULL || nbytes > MAX_CHAR + 1) return -1;
    
    if (fd->file_position >= boot_block_start->num_dir_entries) {
            return 0; // No more entries to read
        }

        dentry_t dentry;
        if (read_dentry_by_index(fd->file_position, &dentry) == -1) {
            return -1; // Failed to read directory entry
        }

        // Prepare the buffer by clearing it
        memset(buf, '\0', MAX_CHAR + 1);
        char* char_buf = (char*)buf;
        // Copy the filename to the buffer
        int32_t num_read = 0;
        for (num_read = 0; num_read < MAX_CHAR; num_read++) {
            if (dentry.filename[num_read] == '\0') break;
            char_buf[num_read] = dentry.filename[num_read];
        }
        // Increment file position for the next read
        fd->file_position += 1;

        return num_read; // Return the number of characters copied to buffer, excluding any added metadata
}

/* Writes to a Directory Entry
dir_write(int32_t fd, const void* buf, int32_t nbytes)
Inputs: fd: the file descriptor telling which file to write
        buf: the buffer that will store the write data
        nbytes: the nbytes of data to write
Outputs: -1, read only system so the function does not return anything notable
*/
int32_t dir_write(int32_t fd, const void* buf, int32_t nbytes) {
    return -1;
}
