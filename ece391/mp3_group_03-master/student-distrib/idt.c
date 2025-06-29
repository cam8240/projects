#include "x86_desc.h"
#include "lib.h"
#include "idt.h"
#include "idt_asm.h"
#include "interrupt_asm.h"
#include "syscall.h"
#include "pit.h"


// Exception messages array with main 20
static char *exceptions[] = {
            "divide_by_zero",
            "debug_exception",
            "nmi",
            "breakpoint",
            "overflow",
            "bound_range_exceeded",
            "invalid_opcode",
            "device_na",
            "double_fault",
            "coprocessor_segment_overrun",
            "invalid_tss",
            "segment_not_present",
            "stack_segment_fault",
            "general_protection",
            "page_fault",
            "RESERVED",
            "x87_fpu_error",
            "alignment_check",
            "machine_check",
            "simd_floating_point_exception"
            };

/* 
Initializes the IDT with default values and exception/system call handlers
void idt_init(void)
Inputs: None
Outputs: None
Effects: Sets segment selector, gate type, and privilege levels for all IDT entries. 
Exception handlers are set for the first 32 entries, system call handler is set for 
entry 0x80, and specific handlers for keyboard and RTC interrupts. Finally, loads the 
IDT register with the address of the IDT.
*/
void idt_init(void) {
    unsigned int i;
    for (i = 0; i < NUM_VEC; i++) {
        idt[i].seg_selector = KERNEL_CS; // Set segment selector to kernel code segment
        idt[i].reserved4 = 0; // Reserved, must be zero
        idt[i].reserved3 = (i == SYSTEM_CALL_VECTOR) ? 1 : 0; // Use trap gate for system calls (1), interrupt gate for others (0)
        idt[i].reserved2 = 1; // Descriptor bit, always set to 1 for 32-bit interrupt and trap gates
        idt[i].reserved1 = 1; // Descriptor bit, always set to 1 for 32-bit interrupt and trap gates
        idt[i].size = 1; // Gate size, set to 1 for 32-bit gates
        idt[i].reserved0 = 0; // Reserved, must be zero
        idt[i].dpl = (i == SYSTEM_CALL_VECTOR) ? 3 : 0; // Descriptor Privilege Level: 3 for system calls, 0 for exceptions
        idt[i].present = 0; // Gate is not present by default, will be set to 1 when enabled

        // Sets idt based on osdev specifications
        if (i < NUM_EXCEPTIONS || i == SYSTEM_CALL_VECTOR) {
            switch (i) {
                case 0: SET_IDT_ENTRY(idt[i], divide_by_zero_handler); break;
                case 1: SET_IDT_ENTRY(idt[i], debug_exception_handler); break;
                case 2: SET_IDT_ENTRY(idt[i], nmi_handler); break;
                case 3: SET_IDT_ENTRY(idt[i], breakpoint_handler); break;
                case 4: SET_IDT_ENTRY(idt[i], overflow_handler); break;
                case 5: SET_IDT_ENTRY(idt[i], bound_range_exceeded_handler); break;
                case 6: SET_IDT_ENTRY(idt[i], invalid_opcode_handler); break;
                case 7: SET_IDT_ENTRY(idt[i], device_na_handler); break;
                case 8: SET_IDT_ENTRY(idt[i], double_fault_handler); break;
                case 9: SET_IDT_ENTRY(idt[i], coprocessor_segment_overrun_handler); break;
                case 10: SET_IDT_ENTRY(idt[i], invalid_tss_handler); break;
                case 11: SET_IDT_ENTRY(idt[i], segment_not_present_handler); break;
                case 12: SET_IDT_ENTRY(idt[i], stack_segment_fault_handler); break;
                case 13: SET_IDT_ENTRY(idt[i], general_protection_fault_handler); break;
                case 14: SET_IDT_ENTRY(idt[i], page_fault_handler); break;
                /* Case 15 reserved: corresponds to the Intel-defined exception number 15, 
                which is not currently assigned to any standard CPU exception by Intel. */
                case 16: SET_IDT_ENTRY(idt[i], x87_fpu_error_handler); break;
                case 17: SET_IDT_ENTRY(idt[i], alignment_check_handler); break;
                case 18: SET_IDT_ENTRY(idt[i], machine_check_handler); break;
                case 19: SET_IDT_ENTRY(idt[i], simd_floating_point_exception_handler); break;
                default: break;
            }
            idt[i].present = 1; // Mark the entry as present
        }

        // Special handling for system call vector
        if (i == SYSTEM_CALL_VECTOR) {
            SET_IDT_ENTRY(idt[i], syscall_entry);
        }
    }
    // Setting up specific hardware interrupt vectors
    idt[KEYBOARD_VECTOR].present = 1; // Enable the keyboard interrupt vector in the IDT
    idt[RTC_VECTOR].present = 1; // Enable the RTC (Real Time Clock) interrupt vector in the IDT
    idt[PIT_VECTOR].present = 1; // Enable the PIT (Programmable Interval Timer) interrupt vector in the IDT
    
    SET_IDT_ENTRY(idt[KEYBOARD_VECTOR], keyboard_wrapper);
    SET_IDT_ENTRY(idt[RTC_VECTOR], rtc_wrapper);
    SET_IDT_ENTRY(idt[PIT_VECTOR], pit_wrapper);

    lidt(idt_desc_ptr);
}

/* 
Handles exceptions by printing register states and error information
void exception_handler(uint32_t vec_num, struct x86_regs regs, uint32_t flags, uint32_t error)
Inputs: vec_num (vector number of the exception), regs (CPU registers at the time of exception), flags 
(EFLAGS register value), error (error code for the exception)
Outputs: None
Effects: Prints the exception number, CPU register states, and freezes the system. 
*/
void exception_handler(uint32_t vec_num, struct x86_regs regs, uint32_t flags, uint32_t error) {
    uint32_t cs;
    asm("\t movl %%cs, %0" : "=r"(cs));
    if (vec_num < NUM_EXCEPTIONS) { // Prints out registers for debugging
        printf("Exception: %s\n", exceptions[vec_num]);
        // printf(" ESP: 0x%#x \n ESI: 0x%#x\n", regs.esp, regs.esi);
        // printf(" EBP: 0x%#x \n EDI: 0x%#x\n", regs.ebp, regs.edi);
        // printf(" EAX: 0x%#x \n EBX: 0x%#x\n", regs.eax, regs.ebx);
        // printf(" ECX: 0x%#x \n EDX: 0x%#x\n", regs.ecx, regs.edx);
        // printf(" EFLAGS: 0x%#x \n ERROR: 0x%#x\n", flags, error);
    } else {
        printf(" Unknown Exception!\n");
    }
    halt(255); // Freeze the system
}
