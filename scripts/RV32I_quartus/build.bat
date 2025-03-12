@echo off
setlocal enabledelayedexpansion

set "ARCH_FLAGS=-march=rv32e -mabi=ilp32e"

set "MEM_HEX=0x8000"
set "MEM_DEC_B=32768"
set "MEM_DEC_W=8192"

set "USE_EXT=0"
set "RUN_SIM=0"

:parse_args
if "%~1"=="" goto done_parse

if /I "%~1"=="-i" (
    set "ARCH_FLAGS=-march=rv32i -mabi=ilp32"
) else if /I "%~1"=="-ext" (
    set "USE_EXT=1"
) else if /I "%~1"=="-sim" (
    set "RUN_SIM=1"
    
    set "MEM_HEX=0x2000"
    set "MEM_DEC_B=8192"
    set "MEM_DEC_W=2048"
)

shift
goto parse_args

:done_parse

echo.
echo  -i    Generate RV32I code (default: RV32E)
echo  -ext  Use extended HAL library
echo  -sim  8192 byte memory + readmemh file
echo.
echo ===============================================
if "%ARCH_FLAGS%"=="-march=rv32e -mabi=ilp32e" (
    echo Generating RV32E Code
    echo Using 16 registers and ilp32e
) else (
    echo Generating RV32I Code
    echo Using 32 registers and ilp32
)
echo Memory size: %MEM_HEX% (%MEM_DEC_B% Byte)
echo Config:
if "%USE_EXT%"=="1" (
    echo - Extended HAL library
) else (
    echo - Standard HAL library
)
if "%RUN_SIM%"=="1" (
    echo - Quartus and simulation file
) else (
    echo - Only Quartus file
)
echo ===============================================
echo.

set "LIB=..\src\lib"
set "LINKER=..\src\linker"
set "SCRIPTS=..\scripts\hex_conv"
set "BUILD=..\build"

if not exist %BUILD% mkdir %BUILD%
set "INCLUDES=-I%LIB%"

set "CC=riscv-none-elf-gcc.exe"
set "OBJDUMP=riscv-none-elf-objdump.exe"
set "OBJCOPY=riscv-none-elf-objcopy.exe"
set "PYTHON=python"

set "CFLAGS=-nostdlib -O2 -fno-schedule-insns -fno-schedule-insns2 %ARCH_FLAGS% -ffunction-sections -fdata-sections -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4 %INCLUDES%"

echo Compiling wgrlib.c
%CC% -c %LIB%\wgrlib.c -o %BUILD%\wgrlib.o %CFLAGS%
if errorlevel 1 exit /b 1

echo Compiling wgrhal.c
%CC% -c %LIB%\wgrhal.c -o %BUILD%\wgrhal.o %CFLAGS%
if errorlevel 1 exit /b 1

if "%USE_EXT%"=="1" (
    echo Compiling wgrhal_ext.c
    %CC% -c %LIB%\wgrhal_ext.c -o %BUILD%\wgrhal_ext.o %CFLAGS%
    if errorlevel 1 exit /b 1
)

echo Compiling main.c
%CC% -c ..\src\wgr\main.c -o %BUILD%\main.o %CFLAGS%
if errorlevel 1 exit /b 1

echo Compiling crt0.s
%CC% -c %ARCH_FLAGS% -fno-schedule-insns -fno-schedule-insns2 -o %BUILD%\crt0.o %LINKER%\crt0.s -ffunction-sections -fdata-sections -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4
if errorlevel 1 exit /b 1

echo Linking
if "%USE_EXT%"=="1" (
    %CC% -nostdlib -nodefaultlibs -nostartfiles -T %LINKER%\wgr.ld -Wl,--defsym,MEM_LENGTH=%MEM_DEC_B%,--gc-sections,--no-warn-rwx-segment -fno-schedule-insns -fno-schedule-insns2 -o %BUILD%\wgr.elf %BUILD%\crt0.o %BUILD%\main.o %BUILD%\wgrlib.o %BUILD%\wgrhal.o %BUILD%\wgrhal_ext.o -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4
) else (
    %CC% -nostdlib -nodefaultlibs -nostartfiles -T %LINKER%\wgr.ld -Wl,--defsym,MEM_LENGTH=%MEM_DEC_B%,--gc-sections,--no-warn-rwx-segment -fno-schedule-insns -fno-schedule-insns2 -o %BUILD%\wgr.elf %BUILD%\crt0.o %BUILD%\main.o %BUILD%\wgrlib.o %BUILD%\wgrhal.o -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4
)
if errorlevel 1 exit /b 1

echo Dumping wgr.asm
%OBJDUMP% -d -S %BUILD%\wgr.elf > %BUILD%\wgr.asm
if errorlevel 1 exit /b 1

echo Converting wgr.elf to wgr.hex
%OBJCOPY% -O ihex %BUILD%\wgr.elf %BUILD%\wgr.hex
if errorlevel 1 exit /b 1

%PYTHON% %SCRIPTS%\conv_hex.py %BUILD%\wgr.hex wgr_flat.hex 0x4000 %MEM_DEC_W%
if errorlevel 1 exit /b 1

if "%RUN_SIM%"=="1" (
    %PYTHON% %SCRIPTS%\conv_fram.py wgr_flat.hex wgr_sim.hex %MEM_DEC_B%
    if errorlevel 1 exit /b 1
)

echo Build complete!
endlocal