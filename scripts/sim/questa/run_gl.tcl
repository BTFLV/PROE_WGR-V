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

run 1000000ns

quit -f
