#include "tests.h"
#include "x86_desc.h"
#include "lib.h"
#include "idt.h"
#include "rtc.h"
#include "keyboard.h"
#include "paging.h"
#include "terminal.h"
#include "filesystem.h"
#include "syscall.h"

#define PASS 1
#define FAIL 0

#define VMEM_START 0xB8000
#define VMEM_END 0xB8FFF
#define KERNEL_SPACE_START 0x400000
#define KERNEL_SPACE_END 0x7FFFFF

/* format these macros as you see fit */
#define TEST_HEADER 	\
	printf("[TEST %s] Running %s at %s:%d\n", __FUNCTION__, __FUNCTION__, __FILE__, __LINE__)
#define TEST_OUTPUT(name, result)	\
	printf("[TEST %s] Result = %s\n", name, (result) ? "PASS" : "FAIL");

static inline void assertion_failure(){
	/* Use exception #15 for assertions, otherwise
	   reserved by Intel */
	asm volatile("int $15");
}


/* Checkpoint 1 tests */

/* IDT Test - Example
 * 
 * Asserts that first 10 IDT entries are not NULL
 * Inputs: None
 * Outputs: PASS/FAIL
 * Side Effects: None
 * Coverage: Load IDT, IDT definition
 * Files: x86_desc.h/S
 */
int idt_test(){
	TEST_HEADER;

	int i;
	int result = PASS;
	for (i = 0; i < 10; ++i){
		// Check if both parts of the handler address in the IDT entry are NULL
		if ((idt[i].offset_15_00 == NULL) && 
			(idt[i].offset_31_16 == NULL)){
			// If both parts are NULL, the IDT entry is not properly initialized
			assertion_failure();
			result = FAIL;
		}
	}

	return result;
}

/* Divide by Zero Test
 * 
 * Basic test for divide by zero
 * Inputs: None
 * Outputs: FAIL
 * Side Effects: None
 * Coverage: divide_by_zero exception
 * Files: idt_asm.S, idt.h
 */
int divide_by_zero_test() {
	TEST_HEADER;
	int a = 3;
	int b = 0;
	a = a/b; // Attemt to divide by zero
	return FAIL; // Should never reach here
}

/* Page Fault
 * 
 * Basic test for exception with error code
 * Inputs: None
 * Outputs: FAIL
 * Side Effects: None
 * Coverage: page_fault exception
 * Files: idt_asm.S, idt.h
 */
int page_fault_test() {
    TEST_HEADER;
	asm volatile("int $14");
    return FAIL; // Should never reach here
}

/* Overflow
 * 
 * Basic test for exception without error code
 * Inputs: None
 * Outputs: FAIL
 * Side Effects: None
 * Coverage: overflow exception
 * Files: idt_asm.S, idt.h
 */
int overflow_test() {
    TEST_HEADER;
	asm volatile("int $4");
    return FAIL; // Should never reach here
}

/* System Call
 * 
 * Basic test for system call
 * Inputs: None
 * Outputs: FAIL
 * Side Effects: None
 * Coverage: system_call
 * Files: idt_asm.S, idt.h
 */
int system_call_test() {
    TEST_HEADER;
	asm volatile("int $0x80");
    return FAIL; // Should never reach here
}

/* Paging
 * 
 * Basic test for CP1 Paging
 * Inputs: None
 * Outputs: PASS
 * Side Effects: None
 * Coverage: paging
 * Files: paging.h
 */
int paging_test() {
    TEST_HEADER;
    char val;
	char test;

    char* ptr = (char*)(KERNEL_SPACE_START); // Address pointing to the beginning of kernel space
    val = *ptr; // Attempt to read a byte from the start of the kernel space

    ptr = (char*)(KERNEL_SPACE_END); // Address pointing to the end of kernel space (kernel ends at 0x800000)
    val = *ptr; // Attempt to read a byte from the bottom of the kernel space

	ptr = (char*)(KERNEL_SPACE_START + 0x272131); // random middle value in kernel space
	val = *ptr;

	test = *((char*)(VMEM_START)); //dereference first byte of video memory

	test = *((char*)(VMEM_END)); //dereference last byte of video memory

	test = *((char*)(VMEM_START + 0x14F)); //dereference random middle value in video memory

    return PASS;
}

/* Paging Fault Lower Bound Test
 * 
 * Basic test for CP1 Paging out of bounds
 * Inputs: None
 * Outputs: FAIL
 * Side Effects: None
 * Coverage: paging
 * Files: paging.h
 */
int lower_page_fault_test() {
    TEST_HEADER;
	char test;
    test = *((char*)(KERNEL_SPACE_START - 1)); //access one byte before kernel space
    return FAIL; // Should never reach here
}

/* Paging Fault Upper Bound Test
 * 
 * Basic test for CP1 Paging out of bounds
 * Inputs: None
 * Outputs: FAIL
 * Side Effects: None
 * Coverage: paging
 * Files: paging.h
 */
int upper_page_fault_test() {
    TEST_HEADER;
	char test;
    test = *((char*)(KERNEL_SPACE_END + 1)); //access one byte after kernel space
    return FAIL; // Should never reach here
}

/* Paging Fault Lower Bound Test
 * 
 * Basic test for CP1 Paging out of bounds for vmem
 * Inputs: None
 * Outputs: FAIL
 * Side Effects: None
 * Coverage: paging
 * Files: paging.h
 */
int vmem_lower_page_fault_test() {
    TEST_HEADER;
	char test;
    test = *((char*)(VMEM_START - 1)); //access one byte before vmem space
    return FAIL; // Should never reach here
}

/* Paging Fault Upper Bound Test
 * 
 * Basic test for CP1 Paging out of bounds for vmem
 * Inputs: None
 * Outputs: FAIL
 * Side Effects: None
 * Coverage: paging
 * Files: paging.h
 */
int vmem_upper_page_fault_test() {
    TEST_HEADER;
	char test;
    test = *((char*)(VMEM_END + 1)); //access one byte after vmem space
    return FAIL; // Should never reach here
}

/* Paging Null Test
 * 
 * Basic test for CP1 Paging out of bounds for vmem
 * Inputs: None
 * Outputs: FAIL
 * Side Effects: None
 * Coverage: paging
 * Files: paging.h
 */
int paging_null_test() {
    TEST_HEADER;
    char test;
    char* ptr = (char*) 0;
    test = *ptr;
    return FAIL; // If exception BSODs, we never get here
}

/* Checkpoint 2 tests */

/*
 * test_rtc_frequencies()
 * Inputs: None
 * Outputs: None
 * Effects: Iterates through all valid RTC frequencies, sets each frequency, and waits for an interrupt
 *          to confirm the RTC is operating at that frequency. Prints the current frequency to the screen.
 */
int test_rtc_frequencies() {
    TEST_HEADER;
    uint32_t freq;
    uint32_t pulse_count;
    int32_t retval = 0;
    int32_t result;

    // Attempt to open the RTC device
    result = rtc_open(NULL);
    if (result != 0) {
        printf("RTC open failed\n");
        return FAIL;
    }
    printf("\n");

    // Iteratively test RTC frequencies from 2Hz to 1024Hz, doubling each time
    for (freq = 2; freq <= 1024; freq *= 2) {
        // Reset character counter for each frequency test

        // Set the RTC to the current frequency
        result = rtc_write(NULL, &freq, sizeof(freq));
        if (result != 0) {
            printf("RTC write failed at %u Hz\n", freq);
            retval++; // Accumulate errors
			continue; // Proceed to the next frequency despite the failure
        }
        clear();
        printf(" Running Test: %u Hz\n", freq);
        // Simulate the RTC tick by reading, expecting as many ticks as the frequency in one second
        for (pulse_count = 0; pulse_count <= freq; pulse_count++) {
            result = rtc_read(NULL, NULL, 0);
            if (result != 0) {
                printf("\nRTC read failed at %u Hz, pulse %u\n", freq, pulse_count);
                retval++; // Accumulate errors
            }

            printf("1"); // Visual representation of a tick
        }

        printf("\n"); // Close the printing
    }

    // Close the RTC device
    rtc_close(NULL);

    // Test success
    if (retval == 0) {
        return PASS;
    } else {
        return FAIL;
    }
}

/*
 * test_rtc_write_invalid()
 * Inputs: None
 * Outputs: None
 * Effects: Tests invalid rtc write locations due to out of bounds frequencies
 */
int test_rtc_write_invalid() {
    TEST_HEADER;
    int32_t result;
    int invalid_frequency = 2048; // Example of a frequency too high
    result = rtc_write(NULL, &invalid_frequency, sizeof(invalid_frequency));
    if (result == 0) {
        printf("rtc_write should have failed with a too-high frequency.\n");
        return FAIL;
    }

    invalid_frequency = 1; // Example of a frequency too low
    result = rtc_write(NULL, &invalid_frequency, sizeof(invalid_frequency));
    if (result == 0) {
        printf("rtc_write should have failed with a too-low frequency.\n");
        return FAIL;
    }

    int valid_frequency = 2; // Minimum valid frequency
    result = rtc_write(NULL, &valid_frequency, 0); // Incorrect byte_count
    if (result == 0) {
        printf("rtc_write should have failed with incorrect byte_count.\n");
        return FAIL;
    }

    result = rtc_write(NULL, NULL, sizeof(valid_frequency)); // NULL buffer
    if (result == 0) {
        printf("rtc_write should have failed with NULL buffer.\n");
        return FAIL;
    }
    return PASS;
}

/*
 * terminal_test()
 * Inputs: None
 * Outputs: None
 * Effects: Tests buffer sizes withing the terminal and outside of terminal. Reads
 * and writes returning PASS if tests stay within buffer and FAIL otherwise. Prints
 * the actual number of bytes read.
 */
int terminal_test() {
    TEST_HEADER;
    int nbytes;
    char buf[1024];
    int test_result = PASS;
    
    //printf(" Opening terminal with filename: %s\n", filename);
    terminal_write(0, "\n\nOpening terminal...\n", 22);
    
    if (terminal_open(NULL) != 0) {
        terminal_write(0, "Failed to open terminal.\n", 25);
        return FAIL;
    }

    // Clear buffer before test
    memset(buf, 0, sizeof(buf));

    // Test with a buffer smaller than the maximum buffer size
    terminal_write(0, "Testing with buffer size 10\n", 29);
    nbytes = terminal_read(0, buf, 10);
    //printf("                                         Read bytes: %d\n", nbytes);
    if (nbytes != 10) {
        test_result = FAIL;
    }
    terminal_write(0, "Read bytes.\n", 12);

    // Clear buffer before next test
    memset(buf, 0, sizeof(buf));

    // Test with a buffer at the maximum buffer size
    terminal_write(0, "Testing with buffer size 128\n", 30);
    nbytes = terminal_read(0, buf, 128);
    //printf("                                         Read bytes: %d\n", nbytes);
    if (nbytes != 128) {
        test_result = FAIL;
    }
    terminal_write(0, "Read bytes.\n", 12);

    // Clear buffer before next test
    memset(buf, 0, sizeof(buf));

    // Test with a buffer larger than the maximum buffer size
    terminal_write(0, "Testing with buffer size 150\n", 30);
    nbytes = terminal_read(0, buf, 130);
    //printf("                                         Read bytes: %d\n", nbytes);
    if (nbytes > 128) { // Reading should not exceed max buffer size
        test_result = FAIL;
    }
    terminal_write(0, "Read bytes.\n", 12);

    // Closing terminal
    //printf(" Closing terminal with filename: %s\n", filename);
    terminal_write(0, "Closing terminal.\n", 19);
    if (terminal_close(NULL) != 0) {
        terminal_write(0, "Failed to close terminal.\n", 26);
        return FAIL;
    }

    return test_result;
}

void terminal_echo_test(void) {
    int nbytes;
    char buf[1024]; // Buffer to hold input

    terminal_write(0, "Opening terminal...\n", 20);
    
    if (terminal_open(NULL) != 0) {
        terminal_write(0, "Failed to open terminal.\n", 25);
    }

    terminal_write(0, "Type something and press enter: ", 32);

    // Wait for user input; assuming terminal_read blocks until enter is pressed
    nbytes = terminal_read(0, buf, sizeof(buf)-1); // Save one space for null terminator
    if (nbytes < 0) { // Check for a read error
        terminal_write(0, "Failed to read from terminal.\n", 30);
    } else {
        buf[nbytes] = '\0'; // Null-terminate the string
        terminal_write(0, "You typed: ", 11);
        terminal_write(0, buf, nbytes); // Write back the input
        terminal_write(0, "\n", 1); // Newline for cleanliness
    }

    // Closing terminal
    terminal_write(0, "Closing terminal.\n", 19);
    if (terminal_close(NULL) != 0) {
        terminal_write(0, "Failed to close terminal.\n", 26);
    }
}



/*
 * filesystem_print(dentry_t* dentry)
 * Inputs: None
 * Outputs: Dentry
 * Effects: Helper function for test cases to print out data
 */
void filesystem_print(dentry_t* dentry) {
    if (dentry == NULL) {
        printf("dentry is NULL; ");
        return;
    }

    // Map the file type to a descriptive string
    const char* type_str = "";
    switch (dentry->type) {
        case FILE_TYPE_RTC:
            type_str = "0";
            break;
        case FILE_TYPE_DIRECTORY:
            type_str = "1";
            break;
        case FILE_TYPE_REGULAR:
            type_str = "2";
            break;
        default:
            type_str = "Unknown";
            break;
    }

    inode_t* inode_ptr = (inode_t*)(FS_START_ADDR + sizeof(boot_block_t) + dentry->inode_num * sizeof(inode_t));
    uint32_t file_size = inode_ptr->length;
    printf("file_name: ");
    puts_n(dentry->filename, MAX_CHAR);
    printf(", file_type: %s, file_size: %u", type_str, file_size);
}


/*
 * filesystem_test_by_index(void)
 * Inputs: None
 * Outputs: None
 * Effects: This is a test of multiple file names showing the reading functionality works
 * properly by testing both files that do exist and those that do not exist.
 */
int filesystem_test_by_index(void)
{
    TEST_HEADER;
    int32_t i;
    dentry_t dentry;
    uint32_t num_files = boot_block_start->num_dir_entries;
    // Loop through file indices 0 to 16
    for (i = 0; i < num_files; i++) {
        if (read_dentry_by_index(i, &dentry) == 0) {
            filesystem_print(&dentry);
        } else {
            printf("Dentry %d does not exist.\n", i);
        }
        printf("\n");
    }
    return PASS;
}

/*
 * filesystem_test_by_name(void)
 * Inputs: None
 * Outputs: None
 * Effects: This is a test of multiple file names showing the reading functionality works
 * properly by testing both files that do exist and those that do not exist.
 */
int filesystem_test_by_name(void) {
    TEST_HEADER;
    dentry_t dentry;
    int32_t i;
    int8_t *filenames[4] = {"hello", ".", "rtc", "verylargetextwithverylongname.txt"};

    // Iterate through the list of test filenames
    for (i = 0; i < 4; i++) {
        printf("Reading dentry by name: '%s'\n", filenames[i]);
        if (read_dentry_by_name((uint8_t *)filenames[i], &dentry) == 0) {
            printf("Dentry '%s' found:\n", filenames[i]);
            filesystem_print(&dentry);
        } else {
            printf("Dentry '%s' does not exist.\n", filenames[i]);
        }
        printf("\n");
    }
    return PASS;
}


/*
 * filesystem_test_frame0(void)
 * Inputs: None
 * Outputs: None
 * Effects: This tests a .txt file and read_data
 */
int filesystem_test_frame0(void) {
    TEST_HEADER;
    uint8_t buf[1];
    uint32_t i;
    dentry_t my_dentry;

    // Try to read the directory entry by name
    if (read_dentry_by_name((uint8_t *)"frame0.txt", &my_dentry) != 0) {
        printf("Failed to read 'frame0.txt'\n");
        return FAIL;
    }

    // Calculate the address of the inode for 'frame0.txt' using its inode number
    inode_t* inode_ptr = (inode_t*)(FS_START_ADDR + sizeof(boot_block_t) + my_dentry.inode_num * sizeof(inode_t));
    uint32_t file_size = inode_ptr->length;

    // Read through all possible bytes of the file, based on the inode's file size
    for (i = 0; i < file_size; i++) {
        if (read_data(my_dentry.inode_num, i, buf, 1) != 1) break; // Attempt to read 1 byte at a time
        putc(buf[0]); // Output the byte
    }

    filesystem_print(&my_dentry);

    printf("\nBytes read: %d\n", i);

    // Determine test result based on whether all bytes were read successfully
    if (i == file_size)
        return PASS;
    else
        return FAIL;
}

/*
 * filesystem_test_ls(void)
 * Inputs: None
 * Outputs: None
 * Effects: This tests a ls executable and dir_read by listing
 * 
 */
int filesystem_test_ls(void) {
    TEST_HEADER;
    file_descriptor_t fd;
    int32_t fd_close;
    int32_t fd_write;
    int32_t cnt;
    int8_t buf[MAX_CHAR]; // Buffer to hold filenames, +1 for null terminator
    int32_t result;

    // Open the root directory. Use "." to refer to the current directory
    result = dir_open((uint8_t*)"ls", &fd);
    if (result != 0) {
        // Handle error opening directory
        return FAIL;
    }

    // dir_write should always fail since filesystem is read-only
    if (dir_write(fd_write, (const int8_t*)buf, sizeof(buf)) != -1) {
        dir_close(fd_close); // Make sure to close the directory before returning
        return FAIL;
    }

    // Read and print each directory entry
    while (0 != (cnt = dir_read(&fd, buf, 127))) {
        if (-1 == cnt) {
            printf("Directory entry read failed\n");
            return FAIL;
        }
        buf[cnt] = '\n'; // Append newline
        printf("%s", buf);
    }

    dir_close(fd_close);
    return PASS;
}

/*
 * filesystem_test_frame0(void)
 * Inputs: None
 * Outputs: None
 * Effects: This tests a long .txt file and read_data
 */
int filesystem_test_verylargetextwithverylongname(void) {
    uint8_t buf[1];
    uint32_t i;
    dentry_t my_dentry;
    clear();

    if (read_dentry_by_name((uint8_t*)"verylargetextwithverylongname.tx", &my_dentry) != 0) {
        printf("Failed to read directory entry for 'verylargetextwithverylongname.tx(t)'\n");
    }

    // Calculate the address of the inode for 'verylargetextwithverylongname.txt' using its inode number
    inode_t* inode_ptr = (inode_t*)(FS_START_ADDR + sizeof(boot_block_t) + my_dentry.inode_num * sizeof(inode_t));
    uint32_t file_size = inode_ptr->length;

    // Read through all possible bytes of the file, based on the inode's file size
    for (i = 0; i < file_size; i++) {
        if (read_data(my_dentry.inode_num, i, buf, 1) != 1) break; // Attempt to read 1 byte at a time
        putc(buf[0]); // Output the byte
    }
    return 1;
}

/*
 * filesystem_test_frame0(void)
 * Inputs: None
 * Outputs: None
 * Effects: This tests an executable file fish
 */
int filesystem_test_executable(void) {
    uint8_t buf[1];
    uint32_t i;
    dentry_t my_dentry;
    clear();

    if (read_dentry_by_name((uint8_t*)"ls", &my_dentry) != 0) { // Change 'fish' to grep for long test
        printf("Failed to read directory entry\n");
    }

    // Calculate the address of the inode for 'fish' using its inode number
    inode_t* inode_ptr = (inode_t*)(FS_START_ADDR + sizeof(boot_block_t) + my_dentry.inode_num * sizeof(inode_t));
    uint32_t file_size = inode_ptr->length;

    // Read through all possible bytes of the file, based on the inode's file size
    for (i = 0; i < file_size; i++) {
        if (read_data(my_dentry.inode_num, i, buf, 1) != 1) break; // Attempt to read 1 byte at a time
        putc(buf[0]); // Output the byte
    }
    return 1;
}

/* Checkpoint 3 tests */
/* Checkpoint 4 tests */
/* Checkpoint 5 tests */

/* Test suite entry point */
void launch_tests(){
	// launch your tests here

	/* Checkpoint 1 tests */
	//TEST_OUTPUT("idt_test", idt_test());
	//TEST_OUTPUT("divide_by_zero_test", divide_by_zero_test());
	//TEST_OUTPUT("page_fault_test", page_fault_test());
	//TEST_OUTPUT("overflow_test", overflow_test());
	//TEST_OUTPUT("system_call_test", system_call_test());

	//TEST_OUTPUT("paging_test", paging_test());
	//TEST_OUTPUT("lower_bound_page_fault_test", lower_page_fault_test());
	//TEST_OUTPUT("upper_bound_page_fault_test", upper_page_fault_test());
	//TEST_OUTPUT("vmem_lower_bound", vmem_lower_page_fault_test());
	//TEST_OUTPUT("vmem_upper_bound", vmem_upper_page_fault_test());
	//TEST_OUTPUT("paging_null_test", paging_null_test());

	/* Checkpoint 2 tests */
	//TEST_OUTPUT("test_rtc_frequencies", test_rtc_frequencies());
	//TEST_OUTPUT("test_rtc_write_invalid", test_rtc_write_invalid());

	//TEST_OUTPUT("terminal_test", terminal_test());
    //terminal_echo_test();

    //TEST_OUTPUT("filesystem_test_by_index", filesystem_test_by_index());
    //TEST_OUTPUT("filesystem_test_by_name", filesystem_test_by_name());
    //TEST_OUTPUT("filesystem_test_frame0", filesystem_test_frame0());
    //TEST_OUTPUT("filesystem_test_ls", filesystem_test_ls());

    //filesystem_test_verylargetextwithverylongname();
    //filesystem_test_executable();

	/* Checkpoint 3 tests */
    //flush_tlb();


    /* Checkpoint 4 tests */
    /* Checkpoint 5 tests */
}
