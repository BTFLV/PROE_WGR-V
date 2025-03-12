@echo off

set SHIFT_AMOUNT=0x4000
set MEMORY_WORDS=8192
set /a MEMORY_BYTES=MEMORY_WORDS*4

set "MARCH_MABI=-march=rv32i -mabi=ilp32"
