;# System max clk: 1 / 12 MHz = 83.333 ns
create_clock -name clk12mhz -period 83.333 [get_ports clk]

set_false_path -from [get_ports rst_n] -to [all_registers]

;# UART max clk: 1 / 115200 Hz = 8680 ns
create_clock -name uart_clk -period 8680 [get_ports uart_rx]
set_false_path -from [get_ports uart_rx] -to [all_registers]
set_false_path -to [get_ports uart_tx]

;# SPI max clk: 1 / 6 MHz = 166.666 ns
create_clock -name spi_clk -period 166.666 [get_ports spi_clk]
set_false_path -to [get_ports spi_mosi]
set_false_path -from [get_ports spi_miso] -to [all_registers]
set_false_path -to [get_ports spi_cs]

set_false_path -from [get_ports {rst_n}]
set_false_path -from * -to [get_ports {gpio_out*}]

derive_clock_uncertainty
