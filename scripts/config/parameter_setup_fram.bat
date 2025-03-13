@echo off

set SHIFT_AMOUNT=0x4000
set MEMORY_WORDS=2048
set /a MEMORY_BYTES=MEMORY_WORDS*4

set "MARCH_MABI=-march=rv32e -mabi=ilp32e"
