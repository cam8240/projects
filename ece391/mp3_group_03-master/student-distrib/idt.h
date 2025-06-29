#ifndef _IDT_H
#define _IDT_H

#ifndef ASM

#include "lib.h"

#define NUM_EXCEPTIONS 0x20 // 0x20 in hex exceptions
#define SYSTEM_CALL_VECTOR 0x80 // Standard system call vector
#define NUM_VEC 256 // Total number of vectors in the IDT
#define KEYBOARD_VECTOR 0x21 // According to OSDEV
#define RTC_VECTOR 0x28 // According to OSDEV
#define PIT_VECTOR 0x20 // According to OSDEV

/* Registers used for debugging */
 struct x86_regs {
    uint32_t edi;
    uint32_t esi;
    uint32_t ebp;
    uint32_t esp;
    uint32_t ebx;
    uint32_t edx;
    uint32_t ecx;
    uint32_t eax;
 } __attribute__ (( packed ));

/* Initializes the IDT with the necessary entries */
void idt_init(void);

/* Called by the exception handler wrapper to handle specific exceptions */
void exception_handler(uint32_t vec_num, struct x86_regs regs, uint32_t flags, uint32_t error);

#endif /* ASM */
#endif /* _IDT_H */
