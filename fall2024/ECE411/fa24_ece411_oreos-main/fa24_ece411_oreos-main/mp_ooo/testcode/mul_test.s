mul_test.s:
    .align 4
    .section .text
    .globl _start
_start:

# Initialize registers with some values
li x1, 10 
li x2, 20 
li x3, -15
li x4, 25 
li x5, -5 
li x6, 50 
li x7, 21   
li x8, 28   

# Introduce some NOPs for initial delay
nop
nop
nop
nop
nop

# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits

# High bits of signed multiply (signed x signed)
mulh x10, x1, x3     # x10 = high 32 bits of (x1 * x3)

# High bits of unsigned multiply (unsigned x unsigned)
mulhu x11, x7, x8    # x11 = high 32 bits of (x7 * x8)

# High bits of signed x unsigned multiply
mulhsu x12, x3, x8   # x12 = high 32 bits of (x3 * x8)


#BREAKS

# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits

# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits

# High bits of signed multiply (signed x signed)
mulh x10, x1, x3     # x10 = high 32 bits of (x1 * x3)

# High bits of unsigned multiply (unsigned x unsigned)
mulhu x11, x7, x8    # x11 = high 32 bits of (x7 * x8)

# High bits of signed x unsigned multiply
mulhsu x12, x3, x8   # x12 = high 32 bits of (x3 * x8)


#BREAKS

# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits


# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits

# High bits of signed multiply (signed x signed)
mulh x10, x1, x3     # x10 = high 32 bits of (x1 * x3)

# High bits of unsigned multiply (unsigned x unsigned)
mulhu x11, x7, x8    # x11 = high 32 bits of (x7 * x8)

# High bits of signed x unsigned multiply
mulhsu x12, x3, x8   # x12 = high 32 bits of (x3 * x8)


#BREAKS

# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits


# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits

# High bits of signed multiply (signed x signed)
mulh x10, x1, x3     # x10 = high 32 bits of (x1 * x3)

# High bits of unsigned multiply (unsigned x unsigned)
mulhu x11, x7, x8    # x11 = high 32 bits of (x7 * x8)

# High bits of signed x unsigned multiply
mulhsu x12, x3, x8   # x12 = high 32 bits of (x3 * x8)


#BREAKS

# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits


# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits

# High bits of signed multiply (signed x signed)
mulh x10, x1, x3     # x10 = high 32 bits of (x1 * x3)

# High bits of unsigned multiply (unsigned x unsigned)
mulhu x11, x7, x8    # x11 = high 32 bits of (x7 * x8)

# High bits of signed x unsigned multiply
mulhsu x12, x3, x8   # x12 = high 32 bits of (x3 * x8)


#BREAKS

# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits


# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits

# High bits of signed multiply (signed x signed)
mulh x10, x1, x3     # x10 = high 32 bits of (x1 * x3)

# High bits of unsigned multiply (unsigned x unsigned)
mulhu x11, x7, x8    # x11 = high 32 bits of (x7 * x8)

# High bits of signed x unsigned multiply
mulhsu x12, x3, x8   # x12 = high 32 bits of (x3 * x8)


#BREAKS

# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits


# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits

# High bits of signed multiply (signed x signed)
mulh x10, x1, x3     # x10 = high 32 bits of (x1 * x3)

# High bits of unsigned multiply (unsigned x unsigned)
mulhu x11, x7, x8    # x11 = high 32 bits of (x7 * x8)

# High bits of signed x unsigned multiply
mulhsu x12, x3, x8   # x12 = high 32 bits of (x3 * x8)


#BREAKS

# Standard signed multiply (lower bits of result)
mul x9, x1, x2       # x9 = x1 * x2, lower 32 bits







halt:
    # Infinite loop to stop the program
    slti x0, x0, -256