// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.1 (win64) Build 1846317 Fri Apr 14 18:55:03 MDT 2017
// Date        : Wed Jan  3 09:35:46 2018
// Host        : DoubleL running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               d:/workdir/vivado_project/wifi_decrypt/wifi_decrypt/wifi_decrypt.srcs/sources_1/ip/pmk_fifo/pmk_fifo_stub.v
// Design      : pmk_fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tsbg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_1_4,Vivado 2017.1" *)
module pmk_fifo(clk, srst, din, wr_en, rd_en, dout, full, almost_full, 
  empty, almost_empty, valid)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[767:0],wr_en,rd_en,dout[767:0],full,almost_full,empty,almost_empty,valid" */;
  input clk;
  input srst;
  input [767:0]din;
  input wr_en;
  input rd_en;
  output [767:0]dout;
  output full;
  output almost_full;
  output empty;
  output almost_empty;
  output valid;
endmodule
