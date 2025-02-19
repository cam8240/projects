fft_short.s:
.align 4
.section .text
.globl _start
_start:

nop
li	x1,0
li	x2,0
li	x3,0
li	x4,0
li	x5,0
li	x6,0
li	x7,0
li	x8,0
li	x9,0
li	x10,0
li	x11,0
li	x12,0
li	x13,0
li	x14,0x1efeb
li	x15,0x1efeb
li	x16,0
li	x17,0
li	x18,0
li	x19,0
li	x20,0
li	x21,0
li	x22,0
li	x23,0
li	x24,0
li	x25,0
li	x26,0
li	x27,0
li	x28,0
li	x29,0
li	x30,0
li	x31,0

nop
nop
nop


lw	x17,0(x14)
lw	x16,4(x14)
lw	x11,8(x14)
lw	x12,12(x14)
sw	x17,0(x15)
sw	x16,4(x15)
sw	x11,8(x15)
sw	x12,12(x15)
addi	x14,x14,16
addi	x15,x15,16

slti	x0,x0,1
slti	x0,x0,3
lui	x16,0x3
add	x13,x2,x16
li	x11,0
addi	x16,x16,1536
li	x12,0
andi	x14,x11,511
andi	x15,x12,511
slli	x14,x14,0x1
slli	x15,x15,0x1
add	x14,x10,x14
add	x15,x10,x15
lhu	x14,0(x14)
lhu	x15,0(x15)

slti x0, x0, -256 # this is the magic instruction to end the simulation