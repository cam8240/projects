local_test.s:
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
li	x14,0
li	x15,0
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

auipc	x6,0x8
addi	x6,x6,-128 # 1ecf3000 <__global_pointer$>
auipc	x7,0x8
addi	x7,x7,-136 # 1ecf3000 <__global_pointer$>

sw	x0,0(x6)
addi	x6,x6,4

auipc	x2,0xd1315
addi	x2,x2,-160 # f0000000 <_stack_top>
add	x8,x2,x0
auipc	x1,0x2


addi	x2,x2,-32
sub	x28,x12,x11
sw	x8,24(x2)
sw	x9,20(x2)
sw	x18,16(x2)
sw	x19,12(x2)
sw	x20,8(x2)
sw	x21,4(x2)
sw	x1,28(x2)
addi	x8,x2,32
srai	x21,x28,0x1
add	x18,x11,x21
mv	x20,x12
mv	x19,x11
mv	x9,x10

# End the simulation
halt:
    slti x0, x0, -256            # Magic instruction to end the simulation (proper termination)
