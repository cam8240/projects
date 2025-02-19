/*
Purpose: Acts as a wrapper in assembly for the C functions, allowing them to handle interrupts 
in a manner compatible with x86
Effect: Saves all general-purpose registers and flags upon an interrupt, calls the 
handler C function to process the interrupt, restores the flags and registers, and 
then returns from the interrupt.
*/
#ifndef _INTERRUPT_ASM_H
#define _INTERRUPT_ASM_H
#ifndef ASM

#include "keyboard.h"
#include "rtc.h"
#include "pit.h"

/* Declarations of asm functions to use in C code */
void keyboard_wrapper();
void rtc_wrapper();
void pit_wrapper();

#endif
#endif
