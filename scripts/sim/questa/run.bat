@echo off
call ..\..\config\path_setup.bat
call ..\..\config\parameter_setup.bat
set OUTPUT_DIR=sim_output
set QUARTUS_PATH=
set VSIM_PATH=

set GL_MODE=0
set VCD_MODE=0
set QUIET_MODE=0

for %%A in (%*) do (
    if "%%A"=="-gl" set GL_MODE=1
    if "%%A"=="-vcd" set VCD_MODE=1
    if "%%A"=="-q" set QUIET_MODE=1
)

pushd "%~dp0..\..\..\WGR-V-MAX"

if "%GL_MODE%"=="1" (
    echo Running Gate-Level Simulation: Generating Netlist

    if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
    %QUARTUS_PATH%quartus_map --read_settings_files=on --write_settings_files=off wgr_v_max -c wgr_v_max
    %QUARTUS_PATH%quartus_fit --read_settings_files=on --write_settings_files=off wgr_v_max -c wgr_v_max
    %QUARTUS_PATH%quartus_eda --write_settings_files=off --simulation=on --functional=on --flatten_buses=off --tool=modelsim_oem --format=verilog --output_directory="%OUTPUT_DIR%" wgr_v_max -c wgr_v_max
    
    if "%VCD_MODE%"=="1" (
        set SIM_SCRIPT=run_gl_vcd.tcl
    ) else (
        set SIM_SCRIPT=run_gl.tcl
    )
) else (
    echo Running RTL Simulation:

    if "%VCD_MODE%"=="1" (
        set SIM_SCRIPT=run_rtl_vcd.tcl
    ) else (
        set SIM_SCRIPT=run_rtl.tcl
    )
)

popd

pushd "%~dp0..\..\..\WGR-V-MAX"
"%VSIM_PATH%vsim" -c -do "..\scripts\sim\questa\%SIM_SCRIPT%"
popd

if "%QUIET_MODE%"=="0" (
    echo Simulation finished. Press any key to exit.
    pause
)
