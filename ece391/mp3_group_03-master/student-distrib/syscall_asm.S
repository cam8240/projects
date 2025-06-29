#define ASM 1
#include "x86_desc.h"

.globl syscall_entry

.text
.align 4
syscall_entry:
    pushl %ebx        # Save general-purpose registers
    pushl %ecx
    pushl %edx
    pushl %esp
    pushl %ebp
    pushl %esi
    pushl %edi

    pushfl            # Save flags register

    # System call arguments are pushed onto the stack
    pushl %edx
    pushl %ecx
    pushl %ebx

    cmpl $0, %eax # Validate against a non-existent syscall 0
    jz syscall_error
    cmpl $10, %eax # Compare against max valid syscall number directly
    ja syscall_error

    # Move to the appropriate syscall handler based on validated syscall number
    call *syscall_entry_table(,%eax,4)

# Restore registers and flags
syscall_exit:
    # Adjust stack pointer back by 12 bytes for 3 arguments
    addl $12, %esp
    popfl             # Restore flags register
    popl %edi         # Restore general-purpose registers
    popl %esi
    popl %ebp
    popl %esp
    popl %edx
    popl %ecx
    popl %ebx
    iret              # Return from interrupt

syscall_error:
    movl $-1, %eax    # Indicate error
    jmp syscall_exit

syscall_entry_table:
    .long 0
    .long halt
    .long execute
    .long read
    .long write
    .long open
    .long close
    .long getargs
    .long vidmap
    .long set_handler
    .long sigreturn


# Flushes the TLB by reloading the %cr3 register
.globl flush_tlb
.align 4
flush_tlb:
    movl %cr3, %eax
    movl %eax, %cr3
    ret
