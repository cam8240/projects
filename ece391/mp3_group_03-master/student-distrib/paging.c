#include "paging.h"
// Declare the paging structures in .c so they are allocated correctly
page_dir_entry_t page_directory[NUM_PAGE_ENTRIES] __attribute__((aligned(PAGE_SIZE_4KB)));
page_dir_entry_4MB_t page_directory_4MB[NUM_PAGE_ENTRIES] __attribute__((aligned(PAGE_SIZE_4KB)));
page_table_entry_t first_page_table[NUM_PAGE_ENTRIES] __attribute__((aligned(PAGE_SIZE_4KB)));
page_table_entry_t video_page_table[NUM_PAGE_ENTRIES] __attribute__((aligned(PAGE_SIZE_4KB)));

// Function prototype for enabling paging, assuming it's defined elsewhere

extern void enable_paging(int directory);
/*
 * paging_init(void)
 * Inputs: none
 * Outputs: none
 * Effects: Initializes paging by setting up the page directory and the first page table.
 *          The video memory page is set as present and writable. The kernel page is set as present,
 *          writable, and uses a 4MB page size. Paging is enabled by loading the base address of the
 *          page directory into the CR3 register, setting the Page Size Extension (PSE) bit in CR4 to
 *          enable 4MB pages, and setting the paging (PG) and protection enable (PE) bits in CR0.
 */
void paging_init() {
    unsigned int i;
    // Zero out the entire page directory and tables initially
    for (i = 0; i < NUM_PAGE_ENTRIES; i++) {
        *((uint32_t*)&page_directory[i]) = 0;
        *((uint32_t*)&first_page_table[i]) = 0;
        *((uint32_t*)&video_page_table[i]) = 0;
    }
    // Set up the first page table for the first 4MB of physical memory
    page_directory[0].present = 1;          // Mark the entry as present
    page_directory[0].read_write = 1;       // Allow read and write operations
    page_directory[0].user = 0;             // Mark as supervisor level, not accessible from user mode
    page_directory[0].size = 0;             // Use 4KB pages
    page_directory[0].table_address = ((int)first_page_table) / PAGE_SIZE_4KB; // Set the address of the first page table
    // Setup the kernel space to use a 4MB page
    page_directory[INDEX_KERNEL].present = 1; // Mark the entry as present
    page_directory[INDEX_KERNEL].read_write = 1; // Allow read and write operations
    page_directory[INDEX_KERNEL].user = 0; // Mark as supervisor level, not accessible from user mode
    page_directory[INDEX_KERNEL].size = 1; // Indicates usage of a 4MB page
    page_directory[INDEX_KERNEL].table_address = ADDR_KERNEL_BASE / PAGE_SIZE_4KB; // Set the base address for the kernel
    // Setup user space
    page_directory[INDEX_USER_SPACE].present = 1; // Mark the entry as present
    page_directory[INDEX_USER_SPACE].read_write = 1; // Allow read and write operations
    page_directory[INDEX_USER_SPACE].user = 1; // Mark as user level, accessible from user mode
    page_directory[INDEX_USER_SPACE].size = 1; // Indicates usage of a 4MB page
    page_directory[INDEX_USER_SPACE].table_address = ADDR_USER_SPACE_BASE / PAGE_SIZE_4KB; // Set the base address for user space


    page_directory[INDEX_VIDMEM].present = 1; // Mark the entry as present
    page_directory[INDEX_VIDMEM].read_write = 1; // Allow read and write operations
    page_directory[INDEX_VIDMEM].user = 1; // Mark as user level, accessible from user mode
    page_directory[INDEX_VIDMEM].size = 1; // Indicates usage of a 4MB page
    page_directory[INDEX_VIDMEM].table_address = ADDR_VIDEO_MEMORY / PAGE_SIZE_4KB; // Set the base address for user space

    for (i = 0; i < NUM_PAGE_ENTRIES; ++i) {
        // Initialize entries in the first page table
        first_page_table[i].present = 0; // Default to not present
        first_page_table[i].read_write = 1; // Typically, allow read/write
        first_page_table[i].user = 0; // Supervisor level
        first_page_table[i].page_address = i; // Direct mapping (can adjust as needed)
        // Specific entries for video memory
        if (i == ADDR_VIDEO_MEMORY / PAGE_SIZE_4KB || i == VIDEO_MEM_INACTIVE1 / PAGE_SIZE_4KB ||
            i == VIDEO_MEM_INACTIVE2 / PAGE_SIZE_4KB || i == VIDEO_MEM_INACTIVE3 / PAGE_SIZE_4KB) {
            first_page_table[i].present = 1; // Mark the video memory's page as present
        }
        // Initialize entries in the video page table
        video_page_table[i].read_write = 1;       // Allow read and write operations
        video_page_table[i].cache_disable = 1;    // Disable caching for this table
        video_page_table[i].page_address = i;     // Map each entry to its corresponding physical address
        video_page_table[i].present = 1;          // Assume all entries here need to be present
    }
    // Enable paging by setting up the control registers
    enable_paging((int)page_directory);
}
