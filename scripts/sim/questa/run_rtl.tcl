set RTL_PATH "../rtl"

quit -sim
transcript file sim_log.txt
if {[file exists work]} {
    echo "Library 'work' already exists. Skipping vlib creation."
} else {
    vlib work
}
vmap work work

vlog -work work "$RTL_PATH/alu.v"
vlog -work work "$RTL_PATH/cpu.v"
vlog -work work "$RTL_PATH/memory.v"
vlog -work work "$RTL_PATH/register_file.v"
vlog -work work "$RTL_PATH/wgr_v_max.v"

vlog -work work "$RTL_PATH/peripherals/debug_module.v"
vlog -work work "$RTL_PATH/peripherals/fifo.v"
vlog -work work "$RTL_PATH/peripherals/gpio.v"
vlog -work work "$RTL_PATH/peripherals/ws2812b.v"
vlog -work work "$RTL_PATH/peripherals/seq_divider.v"
vlog -work work "$RTL_PATH/peripherals/peripheral_bus.v"
vlog -work work "$RTL_PATH/peripherals/pwm_timer.v"
vlog -work work "$RTL_PATH/peripherals/spi.v"
vlog -work work "$RTL_PATH/peripherals/system_timer.v"
vlog -work work "$RTL_PATH/peripherals/uart.v"

vlog -work work ./ip/ram1p/ram1p.v

vlog -work work ./tb_sim/wgr_v_max_tb.v

vopt work.wgr_v_max_tb work.wgr_v_max work.alu work.cpu work.memory work.register_file \
     work.debug_module work.fifo work.gpio work.seq_divider \
     work.ws2812b work.peripheral_bus work.pwm_timer work.spi work.system_timer work.uart \
     work.ram1p -o wgr_v_max_opt -L altera_mf_ver -debugdb +acc

vsim -c wgr_v_max_opt -t 1ps -voptargs="+acc"

run 3000000ns

quit -f
