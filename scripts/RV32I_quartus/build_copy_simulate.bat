@echo off
call ..\config\path_setup.bat
call ..\config\parameter_setup.bat
setlocal enabledelayedexpansion
cls

set SKIP_SIM=0
if "%1"=="-ns" set SKIP_SIM=1

set BUILD_SCRIPT=build_main.bat
set SIM_PATH=..\sim\questa
set RUN_SCRIPT=run.bat
set PULSEVIEW=C:\Progra~1\sigrok\PulseView\pulseview.exe

call %BUILD_SCRIPT%
if %ERRORLEVEL% NEQ 0 (
    echo   - Error: Build script failed!
    exit /b 1
)

if %SKIP_SIM%==1 (
    echo.
    echo   - Skipping simulation and PulseView startup.
    exit /b 0
)

echo.
echo   - Starting Simulation
echo.

pushd "%SIM_PATH%"
call %RUN_SCRIPT% -rtl -vcd -q
if %ERRORLEVEL% NEQ 0 (
    echo   - Error: Simulation script failed!
    popd
    exit /b 1
)
popd

echo. 
echo   - Compiled, copied, simulated
echo.
echo   - Starting Pulseview

start "" "%PULSEVIEW%"
exit /b 0
