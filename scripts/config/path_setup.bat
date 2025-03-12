@echo off

set GCC=riscv32-unknown-elf-gcc
set OBJCOPY=riscv32-unknown-elf-objcopy
set OBJDUMP=riscv-none-elf-objdump.exe
set PYTHON=python

set LINKER_PATH=..\..\src\linker
set SCRIPT_PATH=..\..\scripts
set QUARTUS_PROJEKT_PATH=..\..\WGR-V-MAX
set ASIC_PATH=..\..\asic
set LIB_PATH=..\..\src\lib

set MAIN_C=..\..\src\project
set MAIN_ASM=..\..\src\project_asm
set BUILD_DIR=..\..\build
