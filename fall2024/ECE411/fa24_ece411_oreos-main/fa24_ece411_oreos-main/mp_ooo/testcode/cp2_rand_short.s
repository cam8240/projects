cp2_rand.s:
.align 4
.section .text
.globl _start
_start:

li x0, 1889
li x1, -798
li x2, -921
li x3, 9
li x4, -1959
li x5, -748
li x6, 335
li x7, 1055
li x8, 1922
li x9, -783
li x10, -1250
li x11, -1984
li x12, 1943
li x13, -1625
li x14, 777
li x15, 1223
li x16, 209
li x17, -1174
li x18, 1770
li x19, 195
li x20, 536
li x21, 1202
li x22, -1032
li x23, 1354
li x24, 1514
li x25, 1460
li x26, -225
li x27, -1144
li x28, 1241
li x29, -204
li x30, 0
li x31, 0

nop
nop
nop
nop
nop

or x0, x3, x21
rem x0, x15, x28
xor x0, x10, x6
div x0, x11, x1
mulh x0, x23, x22
rem x0, x19, x23
slli x0, x14, 29
remu x0, x11, x18
add x0, x20, x26
xor x0, x6, x28
mulhu x0, x28, x24
sltiu x0, x15, 81
divu x0, x19, x29
divu x0, x13, x25
add x0, x3, x10


halt:
    slti x0, x0, -256