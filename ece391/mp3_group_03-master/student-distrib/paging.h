#ifndef PAGING_H
#define PAGING_H

#include "types.h"

// Constants for the number of entries and page sizes
#define NUM_PAGE_ENTRIES 1024
#define PAGE_SIZE_4KB 4096
#define PAGE_SIZE_4MB 0x400000

// Addresses for kernel, video memory, and user space
#define ADDR_VIDEO_MEMORY 0xB8000 // Physical base address where video memory is loaded
#define ADDR_KERNEL_BASE 0x400000 // Physical base address where kernel is loaded
#define ADDR_USER_SPACE_BASE 0x08000000 // Physical base address where user is loaded

// Memory addresses for terminal buffers
#define VIDEO_MEM_INACTIVE1 0xB9000 // Start of video memory + 0x1000
#define VIDEO_MEM_INACTIVE2 0xBA000 // Start of video memory + 0x2000
#define VIDEO_MEM_INACTIVE3 0xBB000 // Start of video memory + 0x3000

// Indices for special pages in the directory
#define INDEX_KERNEL 1
#define INDEX_USER_SPACE 32
#define INDEX_VIDMEM 34

// Struct for page directory entries for 4KB
typedef struct __attribute__((packed)) directory_entry  {
    uint32_t present            : 1;
    uint32_t read_write         : 1;
    uint32_t user               : 1;
    uint32_t write_through      : 1;
    uint32_t cache_disable      : 1;
    uint32_t accessed           : 1;
    uint32_t reserved           : 1;
    uint32_t size               : 1;
    uint32_t ignored            : 1;
    uint8_t  available          : 3;  // 3 bits reserved for use by the OS; not used by the hardwar
    uint32_t table_address      : 20; // Base address of the 4KB page, using only 20 bits because
                                      // the lowest 12 bits of the address are assumed to be zero in 
                                      // 4KB aligned pages, effectively addressing up to 4MB
} page_dir_entry_t;

// Struct for page directory entries for 4MB
typedef struct __attribute__((packed)) directory_entry_4MB  {
    uint32_t present            : 1;
    uint32_t read_write         : 1;
    uint32_t user               : 1;
    uint32_t write_through      : 1;
    uint32_t cache_disable      : 1;
    uint32_t accessed           : 1;
    uint32_t reserved           : 1;
    uint32_t size               : 1;
    uint32_t ignored            : 4;
    uint8_t  available          : 3;  // 3 bits reserved for use by the OS; not used by the hardwar
    uint32_t table_address      : 20; // Base address of the 4KB page, using only 20 bits because
                                      // the lowest 12 bits of the address are assumed to be zero in 
                                      // 4KB aligned pages, effectively addressing up to 4MB
} page_dir_entry_4MB_t;

// Struct for page table entries
typedef struct __attribute__((packed)) table_entry {
    uint32_t present            : 1;
    uint32_t read_write         : 1;
    uint32_t user               : 1;
    uint32_t write_through      : 1;
    uint32_t cache_disable      : 1;
    uint32_t accessed           : 1;
    uint32_t dirty              : 1;
    uint32_t reserved           : 1;
    uint32_t global             : 1;
    uint8_t  available          : 3;  // 3 bits reserved for use by the OS; not used by the hardwar
    uint32_t page_address       : 20; // Base address of the 4KB page, using only 20 bits because
                                      // the lowest 12 bits of the address are assumed to be zero in 
                                      // 4KB aligned pages, effectively addressing up to 4MB
} page_table_entry_t;

// Arrays for the page directory, first page table, and video page table, aligned to 4KB boundaries
extern page_dir_entry_t page_directory[NUM_PAGE_ENTRIES] __attribute__((aligned(PAGE_SIZE_4KB)));
extern page_dir_entry_4MB_t page_directory_4MB[NUM_PAGE_ENTRIES] __attribute__((aligned(PAGE_SIZE_4KB)));
extern page_table_entry_t first_page_table[NUM_PAGE_ENTRIES] __attribute__((aligned(PAGE_SIZE_4KB)));
extern page_table_entry_t video_page_table[NUM_PAGE_ENTRIES] __attribute__((aligned(PAGE_SIZE_4KB)));

// Function to initialize paging
extern void paging_init(void);

#endif /* PAGING_H */
