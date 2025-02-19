#ifndef IDT_ASM_H
#define IDT_ASM_H
#ifndef ASM

/* Generic exception handler initilization for exceptions ans syscalls */
void system_call_handler_wrapper();
void divide_by_zero_handler();
void debug_exception_handler();
void nmi_handler();
void breakpoint_handler();
void overflow_handler();
void bound_range_exceeded_handler();
void invalid_opcode_handler();
void device_na_handler();
void double_fault_handler();
void coprocessor_segment_overrun_handler();
void invalid_tss_handler();
void segment_not_present_handler();
void stack_segment_fault_handler();
void general_protection_fault_handler();
void page_fault_handler();
void x87_fpu_error_handler();
void alignment_check_handler();
void machine_check_handler();
void simd_floating_point_exception_handler();

void system_call_handler();

#endif
#endif
