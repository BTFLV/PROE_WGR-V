@echo off
call ..\config\path_setup.bat
call ..\config\parameter_setup.bat
setlocal

if not exist %BUILD_DIR% mkdir %BUILD_DIR%

%GCC% %MARCH_MABI% -Os -c %MAIN_ASM%\main_asm.S -o %BUILD_DIR%\wgr_asm.o

%GCC% -nostdlib -nodefaultlibs -nostartfiles -T %LINKER_PATH%\wgr.ld -o %BUILD_DIR%\wgr_asm.elf %BUILD_DIR%\wgr_asm.o -Wl,--no-warn-rwx-segment

%OBJCOPY% -O ihex %BUILD_DIR%\wgr_asm.elf %BUILD_DIR%\wgr_asm.hex

%OBJDUMP% -d -S %BUILD_DIR%\wgr_asm.elf > %BUILD_DIR%\wgr_asm.asm

%PYTHON% %SCRIPT_PATH%\hex_conv\conv_hex.py %BUILD_DIR%\wgr_asm.hex %ASIC_PATH%\mem\wgr_flat.hex %SHIFT_AMOUNT% %MEMORY_WORDS%

endlocal
