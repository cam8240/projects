.section .text
.globl enable_paging
.align 4
enable_paging:
    pushl %ebp                       # Save old base pointer
    movl  %esp, %ebp                 # Set base pointer to current stack pointer
    movl  8(%ebp), %eax              # Get the function argument (page directory address)
    movl %eax, %cr3                  # Load page directory base address into CR3

    movl %cr4, %eax                  # Load current CR4
    orl  $0x00000010, %eax           # Enable PSE (Page Size Extension) to use 4MB pages
    movl %eax, %cr4                  # Store back to CR4

    movl %cr0, %eax                  # Load current CR0
    orl  $0x80000001, %eax           # Enable paging (PG) and set PE (Protection Enable)
    movl %eax, %cr0                  # Store back to CR0

    movl %cr3, %eax                  # Flushing the TLB by reloading the page directory base address
    movl %eax, %cr3

    leave
    ret
