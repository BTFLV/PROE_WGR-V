;# System max clk: 1 / 12 MHz = 83.333 ns
create_clock -name clk12mhz -period 83.333 [get_ports clk]

set_false_path -from [get_ports rst_n] -to [all_registers]

;# UART max clk: 1 / 115200 Hz = 8680 ns
create_clock -name uart_clk -period 8680 [get_ports uart_rx]
set_false_path -from [get_ports uart_rx] -to [all_registers]
set_false_path -to [get_ports uart_tx]

;# I2C max clk: 1 / 400 kHz = 2500 ns
create_clock -name i2c_clk -period 2500 [get_ports i2c_scl]
set_false_path -from [get_ports i2c_sda] -to [all_registers]
set_false_path -to [get_ports i2c_sda]
set_false_path -to [get_ports i2c_scl]

;# SPI max clk: 1 / 6 MHz = 166.666 ns
create_clock -name spi_clk -period 166.666 [get_ports spi_clk]
set_false_path -to [get_ports spi_mosi]
set_false_path -from [get_ports spi_miso] -to [all_registers]
set_false_path -to [get_ports spi_cs]

set_false_path -to [get_ports testdata]
set_false_path -to [get_ports testdata2]
set_false_path -to [get_ports debug_misc]
set_false_path -to [get_ports debug]

derive_clock_uncertainty
