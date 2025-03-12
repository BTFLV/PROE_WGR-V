.section .text.boot
.global _start
.global _estack

_start:
    la sp, _estack
    jal ra, main

infinite_loop:
    j infinite_loop
