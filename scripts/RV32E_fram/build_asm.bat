@echo off
call ..\config\path_setup.bat
call ..\config\parameter_setup.bat
setlocal

echo.
echo Creating %MEMORY_BYTES% Byte wgr_fram.hex for readmemh with main_asm.S

if not exist %BUILD_DIR% mkdir %BUILD_DIR%

%GCC% %MARCH_MABI% -Os -c %LINKER_PATH%\crt0.s -o %BUILD_DIR%\crt0.o
%GCC% %MARCH_MABI% -Os -c %MAIN_ASM%\main_asm.S -o %BUILD_DIR%\wgr_asm.o
%GCC% -nostdlib -nodefaultlibs -nostartfiles -T %LINKER_PATH%\wgr.ld -o %BUILD_DIR%\wgr_asm.elf %BUILD_DIR%\crt0.o %BUILD_DIR%\wgr_asm.o -Wl,--defsym,MEM_LENGTH=%MEMORY_BYTES%,--gc-sections
%OBJCOPY% -O ihex %BUILD_DIR%\wgr_asm.elf %BUILD_DIR%\wgr_asm.hex
%OBJDUMP% -d -S %BUILD_DIR%\wgr_asm.elf > %BUILD_DIR%\wgr_asm.asm

%PYTHON% %SCRIPT_PATH%\hex_conv\conv_hex.py %BUILD_DIR%\wgr_asm.hex %QUARTUS_PATH%\sim\wgr_flat.hex %SHIFT_AMOUNT% %MEMORY_WORDS%
%PYTHON% %SCRIPT_PATH%\hex_conv\conv_fram.py %QUARTUS_PATH%\sim\wgr_flat.hex %ASIC_PATH%\sim\wgr_flat.hex %MEMORY_WORDS%

endlocal
