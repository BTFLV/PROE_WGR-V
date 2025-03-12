quit -sim
transcript file sim_log.txt
if {[file exists work]} {
    echo "Library 'work' already exists. Skipping vlib creation."
} else {
    vlib work
}
vmap work work

vlog -work work ./sim_output/wgr_v_max.vo
vlog -work work ./tb_sim/wgr_v_max_tb.v

vopt work.wgr_v_max_tb work.wgr_v_max -o wgr_v_max_opt \
     -L fiftyfivenm_ver -L altera_ver -L altera_mf_ver -L 220model_ver \
     -L sgate_ver -L altera_lnsim_ver -debugdb +acc

vsim -c wgr_v_max_opt -t 1ps -voptargs="+acc"

vcd file "../scripts/sim/questa/wgr_v_max_sim.vcd"

vcd on

vcd add /wgr_v_max_tb/tb_rst_n
vcd add /wgr_v_max_tb/tb_pwm_out
vcd add /wgr_v_max_tb/tb_ws_out
vcd add /wgr_v_max_tb/tb_spi_clk
vcd add /wgr_v_max_tb/tb_spi_cs
vcd add /wgr_v_max_tb/tb_spi_mosi
vcd add /wgr_v_max_tb/tb_spi_miso
vcd add /wgr_v_max_tb/tb_uart_tx
vcd add /wgr_v_max_tb/tb_uart_rx
vcd add /wgr_v_max_tb/tb_gpio_out[1:0]
vcd add /wgr_v_max_tb/tb_gpio_dir[1:0]

run 1000000ns

vcd off
vcd flush

quit -f
