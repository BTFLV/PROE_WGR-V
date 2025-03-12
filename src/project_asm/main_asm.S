    .section .text
    .globl _start

    .equ DEBUG_REG, 0x00000100

_start:
    li t0, 0
    li t1, 1
    sw t0, 0(sp)
    sw t1, 4(sp)

loop:
    lw t0, 0(sp)
    lw t1, 4(sp)
    add t2, t0, t1
    
    sw t1, 0(sp)
    sw t2, 4(sp)

    sw t2, DEBUG_REG(zero) 

    j loop
