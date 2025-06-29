div_test.s:
    .align 4
    .section .text
    .globl _start
_start:

# Initialize registers with values for division
li x1, 100
li x2, 20
li x3, -75
li x4, 5 
li x5, -200
li x6, 20
li x7, 0
li x8, -1
li x9, -2147483648

# Introduce some NOPs for initial delay
nop
nop
nop
nop
nop

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

#BREAKS
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

#BREAKS
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

#BREAKS
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

#BREAKS
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

#BREAKS
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

#BREAKS
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)
# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Signed division
div x9, x1, x2       # x9 = x1 / x2 (signed quotient)
rem x10, x1, x2      # x10 = x1 % x2 (signed remainder)

# Unsigned division
divu x11, x5, x6     # x11 = x5 / x6 (unsigned quotient)
remu x12, x5, x6     # x12 = x5 % x6 (unsigned remainder)

# Division by zero (signed)
div x13, x1, x7      # x13 = x1 / 0, should set x13 to -1 (signed division by zero)
rem x14, x1, x7      # x14 = x1 % 0, should set x14 to x1 (signed remainder for division by zero)

# Division by zero (unsigned)
divu x15, x5, x7     # x15 = x5 / 0, should set x15 to 2^XLEN-1 (unsigned division by zero)
remu x16, x5, x7     # x16 = x5 % 0, should set x16 to x5 (unsigned remainder for division by zero)

# Overflow test for signed division
div x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)

# Overflow test for unsigned division
divu x17, x9, x8      # x17 = x9 / -1, should set x17 to x3 (overflow case)
remu x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)


# Signed division
rem x18, x9, x8      # x18 = x9 % -1, should set x18 to 0 (remainder should be zero for overflow)




halt:
    # Infinite loop to stop the program
    slti x0, x0, -256
