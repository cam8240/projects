#define ASM 1

#include "idt_asm.h"

/* Macro for exceptions without an error code */
/*
Push a dummy error code onto the stack (EC ONLY)
Push EFLAGS register on stack to save state
Push all general-purpose registers
Push interrupt vector number onto the stack
Call the handler function
Clean up the stack by popping the vector number
Pop all general-purpose registers to restore state
Pop EFLAGS register to restore state
Additional stack cleanup
Return from interrupt (restores IP, CS, and EFLAGS)
*/

#define MY_ASM_MACRO(function_name, handler, vector) \
    .globl function_name    ;\
    .align 4        ;\
function_name:      ;\
    pushfl         ;\
    pushal         ;\
    pushl $vector  ;\
    call handler   ;\
    addl $4, %esp  ;\
    popal          ;\
    popfl          ;\
    addl $4, %esp  ;\
    iret           ;\

/* Macro for exceptions with an error code */
#define MY_ASM_MACRO_EC(function_name, handler, vector) \
    .globl function_name    ;\
    .align 4        ;\
function_name:      ;\
    pushl $0       ;\
    pushfl         ;\
    pushal         ;\
    pushl $vector  ;\
    call handler   ;\
    addl $4, %esp  ;\
    popal          ;\
    popfl          ;\
    addl $4, %esp  ;\
    iret           ;\

/* Divide by zero error */
MY_ASM_MACRO(divide_by_zero_handler, exception_handler, 0);

/* Debug */
MY_ASM_MACRO(debug_exception_handler, exception_handler, 1);

/* Non-maskable Interrupt */
MY_ASM_MACRO(nmi_handler, exception_handler, 2);

/* Breakpoint */
MY_ASM_MACRO(breakpoint_handler, exception_handler, 3);

/* Overflow */
MY_ASM_MACRO(overflow_handler, exception_handler, 4);

/* Bound Range Exceeded */
MY_ASM_MACRO(bound_range_exceeded_handler, exception_handler, 5);

/* Invalid Opcode */
MY_ASM_MACRO(invalid_opcode_handler, exception_handler, 6);

/* Device Not Available */
MY_ASM_MACRO(device_na_handler, exception_handler, 7);

/* Double Fault */
MY_ASM_MACRO_EC(double_fault_handler, exception_handler, 8);

/* Coprocessor Segment Overrun */
MY_ASM_MACRO(coprocessor_segment_overrun_handler, exception_handler, 9);

/* Invalid TSS */
MY_ASM_MACRO_EC(invalid_tss_handler, exception_handler, 10);

/* Segment Not Present */
MY_ASM_MACRO_EC(segment_not_present_handler, exception_handler, 11);

/* Stack Segment Fault */
MY_ASM_MACRO_EC(stack_segment_fault_handler, exception_handler, 12);

/* General Protection Fault */
MY_ASM_MACRO_EC(general_protection_fault_handler, exception_handler, 13);

/* Page Fault */
MY_ASM_MACRO_EC(page_fault_handler, exception_handler, 14);

/* x87 FPU Floating-Point Error */
MY_ASM_MACRO(x87_fpu_error_handler, exception_handler, 16);

/* Alignment Check */
MY_ASM_MACRO_EC(alignment_check_handler, exception_handler, 17);

/* Machine Check */
MY_ASM_MACRO(machine_check_handler, exception_handler, 18);

/* SIMD Floating-Point Exception */
MY_ASM_MACRO(simd_floating_point_exception_handler, exception_handler, 19);


/* System Call Handler (uses 0x80 location) */
MY_ASM_MACRO(system_call_handler_wrapper, syscall_entry, 0x80);
