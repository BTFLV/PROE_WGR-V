@echo off
call ..\config\path_setup.bat
call ..\config\parameter_setup_fram.bat
setlocal

if not exist %BUILD_DIR% mkdir %BUILD_DIR%

%GCC% -c %LIB_PATH%\wgrlib.c -o %BUILD_DIR%\wgrlib.o -nostdlib -O2 -fno-schedule-insns -fno-schedule-insns2 %MARCH_MABI% -ffunction-sections -fdata-sections -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4
if errorlevel 1 exit /b 1
%GCC% -c %LIB_PATH%\wgrhal.c -o %BUILD_DIR%\wgrhal.o -nostdlib -O2 -fno-schedule-insns -fno-schedule-insns2 %MARCH_MABI% -ffunction-sections -fdata-sections -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4
if errorlevel 1 exit /b 1
%GCC% -c %LIB_PATH%\wgrhal_ext.c -o %BUILD_DIR%\wgrhal_ext.o -nostdlib -O2 -fno-schedule-insns -fno-schedule-insns2 %MARCH_MABI% -ffunction-sections -fdata-sections -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4
if errorlevel 1 exit /b 1
%GCC% -c %MAIN_C%\main.c -o %BUILD_DIR%\main.o -nostdlib -O2 -fno-schedule-insns -fno-schedule-insns2 %MARCH_MABI% -ffunction-sections -fdata-sections -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4 -I%LIB_PATH%
if errorlevel 1 exit /b 1
%GCC% -c %MARCH_MABI% -fno-schedule-insns -fno-schedule-insns2 -o %BUILD_DIR%\crt0.o %LINKER_PATH%\crt0.s -ffunction-sections -fdata-sections -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4
if errorlevel 1 exit /b 1
%GCC% -nostdlib -nodefaultlibs -nostartfiles -T %LINKER_PATH%\wgr.ld -fno-schedule-insns -fno-schedule-insns2 -o %BUILD_DIR%\wgr.elf %BUILD_DIR%\crt0.o %BUILD_DIR%\main.o %BUILD_DIR%\wgrlib.o %BUILD_DIR%\wgrhal.o %BUILD_DIR%\wgrhal_ext.o -Wl,--gc-sections,--no-warn-rwx-segment -fno-builtin -falign-functions=4 -falign-jumps=4 -falign-labels=4 -mstrict-align -falign-loops=4
if errorlevel 1 exit /b 1

%OBJDUMP% -d -S %BUILD_DIR%\wgr.elf > %BUILD_DIR%\wgr.asm

%OBJCOPY% -O ihex %BUILD_DIR%\wgr.elf %BUILD_DIR%\wgr.hex

%PYTHON% %SCRIPT_PATH%\hex_conv\conv_hex.py %BUILD_DIR%\wgr.hex %ASIC_PATH%\mem\wgr_flat.hex %SHIFT_AMOUNT% %MEMORY_WORDS%
%PYTHON% %SCRIPT_PATH%\hex_conv\conv_fram.py %ASIC_PATH%\mem\wgr_flat.hex %ASIC_PATH%\mem\wgr_fram.hex %MEMORY_WORDS%

endlocal
