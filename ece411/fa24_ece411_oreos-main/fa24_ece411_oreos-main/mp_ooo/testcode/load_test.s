load_store.s:
    .align 4
    .section .text
    .globl _start
_start:

li x0, -588
li x1, 996
li x2, -411
li x3, -240
li x4, -49
li x5, 163
li x6, 786
li x7, -595
li x8, 294
li x9, -417
li x10, -731
li x11, 959
li x12, 113
li x13, -762
li x14, -572
li x15, -799
li x16, -336
li x17, 699
li x18, 556
li x19, 322
li x20, -932
li x21, -142
li x22, 152
li x23, 857
li x24, 398
li x25, -910
li x26, 385
li x27, 614
li x28, -113
li x29, -183
li x30, 0
li x31, 0

nop
nop
nop
nop
nop

lui x5, 0x1ecec
addi x5, x5, 0x0000
lui x6, 0x1ecec
addi x6, x6, 0x0004
lui x7, 0x1ecec
addi x7, x7, 0x0008
lui x8, 0x1ecec
addi x8, x8, 0x000C

# lw: Load word to x5
lw x1, 0(x5)

# lb: Load byte from x7
lb x3, 0(x7)
srli x14, x11, 31
srl x25, x17, x25
rem x26, x10, x21
or x16, x19, x8
slli x10, x20, 9
div x4, x11, x20
sub x13, x9, x7
sltu x6, x25, x7
addi x29, x2, -19
# lh: Load halfword from x5

sw x17, 0(x10)
sh x18, 0(x5)
lh x9, 0(x5)

# lbu: Load unsigned byte from x7
lbu x11, 0(x7)

# lhu: Load unsigned halfword from x8
lhu x12, 0(x8)

# lw: Load word to x5
lw x1, 0(x7)

# lb: Load byte from x7
lb x3, 0(x7)

# lh: Load halfword from x5
lh x9, 0(x7)
srli x14, x11, 31
srl x25, x17, x25
rem x26, x10, x21
or x16, x19, x8
slli x10, x20, 9
div x4, x11, x20
sub x13, x9, x7
sltu x6, x25, x7
addi x29, x2, -19
# lbu: Load unsigned byte from x7
lbu x11, 0(x7)

# lhu: Load unsigned halfword from x8
lhu x12, 0(x8)

# lw: Load word to x5
lw x1, 0(x5)

# lb: Load byte from x7
lb x3, 0(x7)

# lh: Load halfword from x5
lh x9, 0(x5)

# lbu: Load unsigned byte from x7
lbu x11, 0(x7)
srli x14, x11, 31
srl x25, x17, x25
rem x26, x10, x21
or x16, x19, x8
slli x10, x20, 9
div x4, x11, x20
sub x13, x9, x7
sltu x6, x25, x7
addi x29, x2, -19
# lhu: Load unsigned halfword from x8
lhu x12, 0(x8)

# lw: Load word to x5
lw x1, 0(x5)

# lb: Load byte from x7
lb x3, 0(x7)

# lh: Load halfword from x5
lh x9, 0(x5)

# lbu: Load unsigned byte from x7
lbu x11, 0(x7)

# lhu: Load unsigned halfword from x8
lhu x12, 0(x8)

# lw: Load word to x5
lw x1, 0(x5)

# lb: Load byte from x7
lb x3, 0(x7)
srli x14, x11, 31
srl x25, x17, x25
rem x26, x10, x21
or x16, x19, x8
slli x10, x20, 9
div x4, x11, x20
sub x13, x9, x7
sltu x6, x25, x7
addi x29, x2, -19
# lh: Load halfword from x5
lh x9, 0(x5)

# lbu: Load unsigned byte from x7
lbu x11, 0(x7)

# lhu: Load unsigned halfword from x8
lhu x12, 0(x8)
srli x14, x11, 31
srl x25, x17, x25
rem x26, x10, x21
or x16, x19, x8
slli x10, x20, 9
div x4, x11, x20
sub x13, x9, x7
sltu x6, x25, x7
addi x29, x2, -19

halt:
    # Infinite loop to stop the program
    slti x0, x0, -256