`timescale 1ns/1ps

import uvm_pkg::*; 
import eth_pkg::*; 
`include "uvm_macros.svh" 
`include "eth_if.sv"

module top_tb;
  // 1. Declarations First
  logic clk; 
  logic rst_n;

  // 2. Instantiations Second
  eth_if vif (.clk(clk), .rst_n(rst_n));

  eth_mac_tx u_mac (
    .clk(clk), 
    .rst_n(rst_n),
    .txd(vif.txd),
    .tx_ctl(vif.tx_ctl),
    .tx_c(vif.tx_c),
    .eth_tx_payload_ack(vif.eth_tx_payload_ack), 
    .eth_tx_start_pulse(vif.eth_tx_start_pulse),
    .dest_mac_in(vif.dest_mac_in), 
    .source_mac_in(vif.source_mac_in), 
    .source_ip_in(vif.source_ip_in), 
    .dest_ip_in(vif.dest_ip_in),
    .source_port_in(vif.source_port_in), 
    .dest_port_in(vif.dest_port_in), 
    .payload_length(vif.payload_length),
    .payload_fifo_rd_en(vif.ext_fifo_rd_en), 
    .payload_fifo_empty(vif.ext_fifo_empty), 
    .payload_fifo_data_out(vif.ext_fifo_data_out),
    .eth_tx_data_sent(vif.eth_tx_data_sent_pulse) 
  );

  // 3. Procedural Blocks Last
  initial begin 
    clk = 0; 
    forever #4 clk = ~clk; 
  end
  
  initial begin 
    rst_n = 0; 
    #100; 
    rst_n = 1; 
  end

  initial begin 
    uvm_config_db#(virtual eth_if)::set(null, "*", "vif", vif); 
    run_test("eth_base_test"); 
  end
endmodule