.section .text
.globl main

.equ DEBUG_REG, 0x00000100

main:
    li      t0, 0
    sw      t0, 0(sp)

loop:
    addi    sp, sp, -16         # Allocate 16 bytes on the stack

    # ---- Test 1: sh 12345 ----
    li      a1, 12345           # a1 = 12345
    sh      a1, 0(sp)           # Store halfword at sp
    lh      a0, 0(sp)           # Load halfword (sign-extended) into a0
    sw      a0, DEBUG_REG(zero) # Write result to debug output
    lhu     a0, 0(sp)           # Load halfword (zero-extended) into a0
    sw      a0, DEBUG_REG(zero) # Write result

    # ---- Test 2: sb 67 ----
    li      a1, 67              # a1 = 67
    sb      a1, 0(sp)           # Store byte at sp
    lb      a0, 0(sp)           # Load byte (sign-extended) into a0
    sw      a0, DEBUG_REG(zero) # Write result
    lbu     a0, 0(sp)           # Load byte (zero-extended) into a0
    sw      a0, DEBUG_REG(zero) # Write result

    # ---- Test 3: sh -54321 ----
    li      a1, -54321          # a1 = -54321
    sh      a1, 0(sp)           # Store halfword at sp
    lh      a0, 0(sp)           # Load halfword (sign-extended) into a0
    sw      a0, DEBUG_REG(zero) # Write result
    lhu     a0, 0(sp)           # Load halfword (zero-extended) into a0
    sw      a0, DEBUG_REG(zero) # Write result

    # ---- Test 4: sb -76 ----
    li      a1, -76             # a1 = -76
    sb      a1, 0(sp)           # Store byte at sp
    lb      a0, 0(sp)           # Load byte (sign-extended) into a0
    sw      a0, DEBUG_REG(zero) # Write result
    lbu     a0, 0(sp)           # Load byte (zero-extended) into a0
    sw      a0, DEBUG_REG(zero) # Write result

    j       loop                # Loop forever
