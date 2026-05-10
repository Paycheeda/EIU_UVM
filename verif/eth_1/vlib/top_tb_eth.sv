/*`timescale 1ns/1ps

import uvm_pkg::*; 
import eth_pkg::*; 
`include "uvm_macros.svh" 

module top_tb_eth;
  logic clk;  
  logic rst_n;

  eth_tx_if     tx_vif (.clk(clk), .rst_n(rst_n));
  eth_rx_app_if rx_vif (.clk(clk), .rst_n(rst_n));

  // Instantiate Saboteur Interface
  fault_inject_if fi_if(.clk(clk));

  // =========================================================
  // THE PHYSICAL PHY LOOPBACK & SABOTEUR
  // =========================================================
  wire [3:0] txd_out;
  wire       tx_ctl_out;
  wire       tx_c_out;     

  wire [3:0] rxd_in;
  wire       rx_ctl_in;
  wire       rx_c_in;      

  // Real-time Nibble Tracker
  int nibble_count = 0;
  always @(posedge clk) begin
    if (tx_ctl_out) nibble_count++;
    else nibble_count = 0;
  end

  // --- THE MUTILATION LOGIC ---
  wire [3:0] saboteur_txd;
  wire       saboteur_ctl;

  // FAULT_CRC: Flip a data bit on exactly the 50th nibble
  assign saboteur_txd = (fi_if.fault_type == FAULT_CRC && nibble_count == 50) ? (txd_out ^ 4'b0100) : txd_out;

  // FAULT_PHY: Drop carrier valid low right in the middle of the payload (nibble 30)
  // FAULT_PREAMBLE: Hide the first 6 nibbles of the preamble from the RX MAC
  assign saboteur_ctl = (fi_if.fault_type == FAULT_PHY && nibble_count == 30) ? 1'b0 :
                        (fi_if.fault_type == FAULT_PREAMBLE && nibble_count > 0 && nibble_count <= 6) ? 1'b0 :
                        tx_ctl_out;

  assign rxd_in    = saboteur_txd;
  assign rx_ctl_in = saboteur_ctl;
  assign #2 rx_c_in = clk; 

  // =========================================================
  // PHYSICAL LAYER CCTV MONITOR
  // =========================================================
  always @(posedge clk) begin
    if (tx_ctl_out == 1'b1) begin // Only monitor during active transmission
      
      // Sniff for a Carrier Drop (PHY FAULT or PREAMBLE FAULT)
      if (saboteur_ctl != tx_ctl_out) begin
        `uvm_info("WIRE_TAP", $sformatf("\n!!! SABOTAGE DETECTED !!! [rx_ctl] forced LOW at Nibble %0d (Expected: 1)", nibble_count), UVM_NONE)
      end
      
      // Sniff for a Bit Flip (CRC FAULT)
      if (saboteur_txd != txd_out) begin
        `uvm_info("WIRE_TAP", $sformatf("\n!!! SABOTAGE DETECTED !!! [rxd] forced to %b at Nibble %0d (Expected: %b)", saboteur_txd, nibble_count, txd_out), UVM_NONE)
      end
      
    end
  end

  // =========================================================
  // PHYSICAL FIFOS & DUT
  // =========================================================
  dual_port_FIFO #(.PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE ("36Kb")) physical_tx_fifo (
    .rst_n(rst_n), .wr_clk(clk), .data_in(tx_vif.ext_tx_fifo_data_in), .wr_en(tx_vif.ext_tx_fifo_wr_en),
    .rd_clk(clk), .rd_en(tx_vif.tx_fifo_rd_en), .data_out(tx_vif.tx_fifo_data_out), .fifo_full(), .fifo_empty(tx_vif.tx_fifo_empty)
  );

  dual_port_FIFO #(.PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE ("36Kb")) physical_rx_fifo (
    .rst_n(rx_vif.rx_fifo_rst_n), .wr_clk(rx_c_in), .data_in(rx_vif.rx_fifo_data_in), .wr_en(rx_vif.rx_fifo_wr_en),
    .rd_clk(clk), .rd_en(rx_vif.ext_rx_fifo_rd_en), .data_out(rx_vif.ext_rx_fifo_data_out), .fifo_full(), .fifo_empty(rx_vif.ext_rx_fifo_empty)
  );

  eth u_dut (
    .tx_clk(clk), 
    .rx_clk(rx_c_in),  
    .rst_n(rst_n),
    
    // Config / Metadata
    .dest_mac(tx_vif.dest_mac), 
    .source_mac(tx_vif.source_mac), 
    .source_ip(tx_vif.source_ip), 
    .dest_ip(tx_vif.dest_ip),
    .source_port(tx_vif.source_port), 
    .dest_port(tx_vif.dest_port), 
    .tx_payload_length(tx_vif.payload_length[10:0]), // Added [10:0] to fix size warning
    
    // New Pipeline Pulses
    .config_done_pulse(tx_vif.config_done_pulse), 
    .eth_tx_start_pulse(tx_vif.eth_tx_start_pulse),
    
    // Internal TX FIFO Control
    .tx_fifo_rd_en(tx_vif.tx_fifo_rd_en), 
    .tx_fifo_empty(tx_vif.tx_fifo_empty), 
    .tx_fifo_data_out(tx_vif.tx_fifo_data_out),
    
    .eth_tx_data_sent(tx_vif.eth_tx_data_sent),
    
    // Physical Wires connected through Saboteur
    .txd(txd_out), 
    .tx_ctl(tx_ctl_out), 
    .tx_c(tx_c_out),   
    .rxd(rxd_in), 
    .rx_ctl(rx_ctl_in),
    
    // Internal RX FIFO Control
    .rx_fifo_wr_en(rx_vif.rx_fifo_wr_en), 
    .rx_fifo_data_in(rx_vif.rx_fifo_data_in), 
    .rx_fifo_rst_n(rx_vif.rx_fifo_rst_n),
    
    .rx_eth_corrupt_frame_count(rx_vif.rx_eth_corrupt_frame_count), 
    .eth_rx_data_valid(rx_vif.eth_rx_data_valid),
    .rx_eth_valid_bytes(rx_vif.rx_eth_valid_bytes)
  );

  // ==================================================
  // THE AUTOPSY MONITOR
  // ==================================================
  int clock_ticks_since_start = 0;
  bit mac_is_active = 0;
  int bytes_read_from_fifo = 0;
  int nibbles_sent_on_wire = 0;

  always @(posedge clk) begin
    if (tx_vif.eth_tx_start_pulse == 1'b1) begin
      mac_is_active = 1; clock_ticks_since_start = 0; bytes_read_from_fifo = 0; nibbles_sent_on_wire = 0;
    end
    if (mac_is_active) begin
      clock_ticks_since_start++;
      if (tx_vif.tx_fifo_rd_en) bytes_read_from_fifo++;
      if (tx_ctl_out) nibbles_sent_on_wire++;
      if (clock_ticks_since_start == 500) begin
         $display("==================================================");
         $display("[AUTOPSY REPORT] SIMULATION STALL DETECTED!");
         $display("==================================================");
      end
    end
    if (tx_vif.eth_tx_data_sent == 1'b1) mac_is_active = 0; 
  end

  initial begin clk = 0; forever #4 clk = ~clk; end
  initial begin rst_n = 0; #100; rst_n = 1; end

  initial begin 
    uvm_config_db#(virtual eth_tx_if)::set(null, "*", "tx_vif", tx_vif); 
    uvm_config_db#(virtual eth_rx_app_if)::set(null, "*", "rx_vif", rx_vif); 
    uvm_config_db#(virtual fault_inject_if)::set(null, "*", "fi_vif", fi_if);
    run_test("eth_loopback_base_test"); 
  end
endmodule*/
`timescale 1ns/1ps

import uvm_pkg::*; 
import eth_pkg::*; 
`include "uvm_macros.svh" 

module top_tb_eth;
  
  // =========================================================
  // 1. CLOCK GENERATION (Dual Domain)
  // =========================================================
  logic mac_clk;  // Fixed 125 MHz for RTL
  logic app_clk;  // Dynamic for UVM/Application
  logic rst_n;
  
  real app_freq_mhz = 64.0; // Default to 64 MHz
  real app_half_period;

  initial begin 
      mac_clk = 0; 
      forever #4 mac_clk = ~mac_clk; // 8ns period = 125 MHz
  end

  initial begin
      // Grab the dynamic clock speed from the terminal!
      if ($value$plusargs("APP_FREQ=%f", app_freq_mhz)) begin
          $display("==================================================");
          $display("[CLOCK DOMAIN] Setting UVM App Clock to %0f MHz", app_freq_mhz);
          $display("==================================================");
      end
      
      // Calculate half-period in nanoseconds: (1000 / freq) / 2
      app_half_period = 500.0 / app_freq_mhz; 
      
      app_clk = 0;
      forever #(app_half_period) app_clk = ~app_clk;
  end
  
  // ---> FIX 1: LUXURIOUS 2000ns RESET TO PREVENT 32MHz MACRO CRASH <---
  initial begin rst_n = 0; #2000; rst_n = 1; end

  // =========================================================
  // 2. INTERFACES (Split across domains)
  // =========================================================
  // The TX Driver operates in the App Clock domain
  eth_tx_if     tx_vif (.clk(app_clk), .rst_n(rst_n));
  
  // RX and Saboteur operate in the fast MAC domain
  eth_rx_app_if rx_vif (.clk(mac_clk), .rst_n(rst_n));
  fault_inject_if fi_if(.clk(mac_clk));


  // =========================================================
  // 3. THE PHYSICAL PHY LOOPBACK & SABOTEUR
  // =========================================================
  wire [3:0] txd_out;
  wire       tx_ctl_out;
  wire       tx_c_out;     

  wire [3:0] rxd_in;
  wire       rx_ctl_in;
  wire       rx_c_in;      

  // Real-time Nibble Tracker
  int nibble_count = 0;
  always @(posedge mac_clk) begin
    if (tx_ctl_out) nibble_count++;
    else nibble_count = 0;
  end

  // --- THE MUTILATION LOGIC ---
  wire [3:0] saboteur_txd;
  wire       saboteur_ctl;

  assign saboteur_txd = (fi_if.fault_type == FAULT_CRC && nibble_count == 50) ? (txd_out ^ 4'b0100) : txd_out;

  assign saboteur_ctl = (fi_if.fault_type == FAULT_PHY && nibble_count == 30) ? 1'b0 :
                        (fi_if.fault_type == FAULT_PREAMBLE && nibble_count > 0 && nibble_count <= 6) ? 1'b0 :
                        tx_ctl_out;

  assign rxd_in    = saboteur_txd;
  assign rx_ctl_in = saboteur_ctl;
  assign #2 rx_c_in = mac_clk; 

  // =========================================================
  // 4. PHYSICAL LAYER CCTV MONITOR
  // =========================================================
  always @(posedge mac_clk) begin
    if (tx_ctl_out == 1'b1) begin 
      if (saboteur_ctl != tx_ctl_out) begin
        `uvm_info("WIRE_TAP", $sformatf("\n!!! SABOTAGE DETECTED !!! [rx_ctl] forced LOW at Nibble %0d (Expected: 1)", nibble_count), UVM_NONE)
      end
      if (saboteur_txd != txd_out) begin
        `uvm_info("WIRE_TAP", $sformatf("\n!!! SABOTAGE DETECTED !!! [rxd] forced to %b at Nibble %0d (Expected: %b)", saboteur_txd, nibble_count, txd_out), UVM_NONE)
      end
    end
  end

  // =========================================================
  // 5. CDC FIFOS & DUT
  // =========================================================
  
  // ---> THE CLOCK DOMAIN CROSSING BOUNDARY <---
  // Write at App Clock (e.g., 64MHz), Read at MAC Clock (125MHz)
  dual_port_FIFO #(.PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE ("36Kb")) physical_tx_fifo (
    .rst_n(rst_n), 
    .wr_clk(app_clk),  .data_in(tx_vif.ext_tx_fifo_data_in), .wr_en(tx_vif.ext_tx_fifo_wr_en),
    .rd_clk(mac_clk),  .rd_en(tx_vif.tx_fifo_rd_en),         .data_out(tx_vif.tx_fifo_data_out), 
    .fifo_full(), .fifo_empty(tx_vif.tx_fifo_empty)
  );

  dual_port_FIFO #(.PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE ("36Kb")) physical_rx_fifo (
    .rst_n(rx_vif.rx_fifo_rst_n), 
    .wr_clk(rx_c_in), .data_in(rx_vif.rx_fifo_data_in),   .wr_en(rx_vif.rx_fifo_wr_en),
    .rd_clk(mac_clk), .rd_en(rx_vif.ext_rx_fifo_rd_en), .data_out(rx_vif.ext_rx_fifo_data_out), 
    .fifo_full(), .fifo_empty(rx_vif.ext_rx_fifo_empty)
  );

  eth u_dut (
    .tx_clk(mac_clk),  // RTL locked to 125 MHz
    .rx_clk(rx_c_in),  
    .rst_n(rst_n),
    
    // Config / Metadata
    .dest_mac(tx_vif.dest_mac), 
    .source_mac(tx_vif.source_mac), 
    .source_ip(tx_vif.source_ip), 
    .dest_ip(tx_vif.dest_ip),
    .source_port(tx_vif.source_port), 
    .dest_port(tx_vif.dest_port), 
    .tx_payload_length(tx_vif.payload_length[10:0]), 
    
    // New Pipeline Pulses
    .config_done_pulse(tx_vif.config_done_pulse), 
    .eth_tx_start_pulse(tx_vif.eth_tx_start_pulse),
    
    // Internal TX FIFO Control
    .tx_fifo_rd_en(tx_vif.tx_fifo_rd_en), 
    .tx_fifo_empty(tx_vif.tx_fifo_empty), 
    .tx_fifo_data_out(tx_vif.tx_fifo_data_out),
    
    .eth_tx_data_sent(tx_vif.eth_tx_data_sent),
    
    // Physical Wires connected through Saboteur
    .txd(txd_out), 
    .tx_ctl(tx_ctl_out), 
    .tx_c(tx_c_out),   
    .rxd(rxd_in), 
    .rx_ctl(rx_ctl_in),
    
    // Internal RX FIFO Control
    .rx_fifo_wr_en(rx_vif.rx_fifo_wr_en), 
    .rx_fifo_data_in(rx_vif.rx_fifo_data_in), 
    .rx_fifo_rst_n(rx_vif.rx_fifo_rst_n),
    
    .rx_eth_corrupt_frame_count(rx_vif.rx_eth_corrupt_frame_count), 
    .eth_rx_data_valid(rx_vif.eth_rx_data_valid),
    .rx_eth_valid_bytes(rx_vif.rx_eth_valid_bytes)
  );

  // ==================================================
  // 6. THE AUTOPSY MONITOR
  // ==================================================
  int clock_ticks_since_start = 0;
  bit mac_is_active = 0;

  always @(posedge mac_clk) begin
    if (tx_vif.eth_tx_start_pulse == 1'b1) begin
      mac_is_active = 1; clock_ticks_since_start = 0; 
    end
    if (mac_is_active) begin
      clock_ticks_since_start++;
      if (clock_ticks_since_start == 5000) begin
         $display("==================================================");
         $display("[AUTOPSY REPORT] SIMULATION STALL DETECTED!");
         $display("==================================================");
      end
    end
    if (tx_vif.eth_tx_data_sent == 1'b1) mac_is_active = 0; 
  end

  // ==================================================
  // 7. UVM LAUNCH
  // ==================================================
  initial begin 
    uvm_config_db#(virtual eth_tx_if)::set(null, "*", "tx_vif", tx_vif); 
    uvm_config_db#(virtual eth_rx_app_if)::set(null, "*", "rx_vif", rx_vif); 
    uvm_config_db#(virtual fault_inject_if)::set(null, "*", "fi_vif", fi_if);
    run_test("eth_loopback_base_test"); 
  end
endmodule