#define ASM 1

#include "interrupt_asm.h"

#define ASM_HANDLER(name, int_handler) \
    .globl name     ;\
    .align 4        ;\
name:       ;\
    pushal      ;\
    pushfl      ;\
    call int_handler        ;\
    popfl      ;\
    popal       ;\
    iret        ;\

ASM_HANDLER(keyboard_wrapper, keyboard_handler);
ASM_HANDLER(rtc_wrapper, rtc_handler);
ASM_HANDLER(pit_wrapper, pit_handler);
