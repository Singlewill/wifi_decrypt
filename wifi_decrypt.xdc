## PERIOD
create_clock -period 10.000 -name Clk -waveform {0.000 5.000} [get_ports Clk]
#create_clock -period 20.000 -waveform {0.000 10.000} [get_pins U_PLL_50M/Clk_out]

## Clock Signal
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports Clk]
#key fifo clk

#create_clock -period 10.000 -waveform {0.000 5.000} [get_pins U_KEY_FIFO/rd_clk]

## Reset Signal
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS12} [get_ports Rst_n]
## UART
set_property -dict {PACKAGE_PIN AA19 IOSTANDARD LVCMOS33} [get_ports Tx_pin]
#set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports { Rx_pin }];

## SD card
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports SD_clk]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports SD_cd]
set_property -dict {PACKAGE_PIN W20 IOSTANDARD LVCMOS33} [get_ports SD_cmd]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {SD_dat[0]}]
set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS33} [get_ports {SD_dat[1]}]
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS33} [get_ports {SD_dat[2]}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {SD_dat[3]}]




