load_store.s:
    .align 4
    .section .text
    .globl _start
_start:

    li x0, 1201
    li x1, -1647
    li x2, 36
    li x3, -733
    li x4, 1475
    li x5, -919
    li x6, -269
    li x7, -1262
    li x8, -718
    li x9, -944
    li x10, 1464
    li x11, -1312
    li x12, 1350
    li x13, 1306
    li x14, 1924
    li x15, -54
    li x16, 72
    li x17, -570
    li x18, 1555
    li x19, 489
    li x20, -395
    li x21, -737
    li x22, -1966
    li x23, -1021
    li x24, 809
    li x25, 1515
    li x26, -1240
    li x27, -2005
    li x28, -252
    li x29, 1403
    li x30, 0
    li x31, 0


lui x5, 0x1ecec
addi x5, x5, 0x0000
lui x6, 0x1ecec
addi x6, x6, 0x0004
lui x7, 0x1ecec
addi x7, x7, 0x0008
lui x8, 0x1ecec
addi x8, x8, 0x000C


sw x7, 0(x6)
lb x7, 0(x6)

sb x7, 0(x6)
lb x7, 0(x6)

sh x7, 0(x6)
lb x7, 0(x6)

sb x7, 0(x6)
lw x7, 0(x6)

sw x7, 0(x6)
lh x7, 0(x6)

sh x7, 0(x6)
lh x7, 0(x6)

sb x7, 0(x6)
lh x5, 0(x6)

sb x5, 0(x6)
lhu x5, 0(x6)

sb x5, 0(x6)
lhu x5, 0(x6)

sw x5, 0(x6)
lbu x5, 0(x6)

sb x5, 0(x6)
lbu x5, 0(x6)

sh x5, 0(x6)
lbu x5, 0(x6)

sh x5, 0(x6)
lhu x5, 0(x6)



# lw: Load word to x5
 #lw x1, 0(x5)

# # lb: Load byte from x7
 #lw x3, 0(x7)

# # lh: Load halfword from x5
 #lh x9, 0(x5)

# # lbu: Load unsigned byte from x7
 #lbu x11, 0(x7)

# # lhu: Load unsigned halfword from x8
 #lhu x12, 0(x8)


slti x0, x0, -256 # this is the magic instruction to end the simulation