`timescale 1ns/1ps

import uvm_pkg::*; 
import mac_rx_pkg::*; 
`include "uvm_macros.svh"
`include "mac_rx_base_test.sv"

module top_tb_mac_rx;

  // ---> 1. SYSTEM CLOCKS & RESET <---
  logic clk; 
  logic clk_270; // Phase-shifted clock for ODDR hardware emulation
  logic rst_n;

  // ---> 2. INTERFACE INSTANTIATION <---
  mac_rx_if vif (.clk(clk), .rst_n(rst_n));

  // Dummy interfaces for unused ports
  eth_if         tx_dummy_if       (.clk(clk), .rst_n(rst_n));
  eth_rx_if      rx_dummy_if       (.clk(clk), .rst_n(rst_n));
  eth_rx_fifo_if rx_fifo_dummy_if  (.clk(clk), .rst_n(rst_n));

  // ---> 3. HARDWARE-IN-THE-LOOP ODDR EMULATION <---
  // Converts UVM Driver's 8-bit parallel data into perfect physical 4-bit DDR signals
  genvar i;
  generate
      for (i = 0; i < 4; i = i + 1) begin : gen_oddr_data
          ODDR #(
              .DDR_CLK_EDGE("SAME_EDGE"), 
              .INIT(1'b0),
              .SRTYPE("SYNC")
          ) ODDR_data_inst (
              .Q(vif.rxd[i]),
              .C(clk_270),                // Driven by phase-shifted clock
              .CE(1'b1),
              .D1(vif.rxd_parallel[i]),   // GMII Lower nibble
              .D2(vif.rxd_parallel[i+4]), // GMII Upper nibble
              .R(~rst_n),
              .S(1'b0)
          );
      end
  endgenerate

  // RGMII Control Signal Logic (RX_CTL on posedge, RX_CTL XOR RX_ER on negedge)
  logic ctl_falling_edge;
  assign ctl_falling_edge = vif.rx_ctl_parallel ^ vif.rx_er_parallel;

  ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"),
      .INIT(1'b0),
      .SRTYPE("SYNC")
  ) ODDR_ctl_inst (
      .Q(vif.rx_ctl),
      .C(clk_270),
      .CE(1'b1),
      .D1(vif.rx_ctl_parallel),
      .D2(ctl_falling_edge),
      .R(~rst_n),
      .S(1'b0)
  );

  // ---> 4. DUT INSTANTIATION (The MAC) <---
  eth_mac_rx u_dut (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .rxd                    (vif.rxd),
    .rx_ctl                 (vif.rx_ctl),
    .rx_fifo_wr_en          (vif.rx_fifo_wr_en),
    .rx_fifo_rst_n          (vif.rx_fifo_rst_n),
    .rx_fifo_data_in        (vif.rx_fifo_data_in),
    .eth_rx_data_valid      (vif.eth_rx_data_valid),
    .corrupt_packet_counter (vif.corrupt_packet_counter),
    .valid_eth_frame        (vif.valid_eth_frame)
  );

  // ---> 5. EXTERNAL MEMORY INSTANTIATION (BEHAVIORAL MOCK FIFO) <---
  tb_mock_fifo #(
    .PARAM_DATA_WIDTH(8),
    .PARAM_FIFO_SIZE ("18Kb")
  ) u_ext_fifo (
    .rst_n      (vif.rx_fifo_rst_n),  // Raw RTL reset
    .wr_clk     (clk),
    .data_in    (vif.rx_fifo_data_in),
    .wr_en      (vif.rx_fifo_wr_en),  // Raw RTL wr_en
    .rd_clk     (clk),
    .rd_en      (vif.ext_fifo_rd_en), // Raw RTL rd_en
    .data_out   (vif.ext_fifo_data_out),
    .fifo_full  (),
    .fifo_empty (vif.ext_fifo_empty)
  );

  // ---> 6. WHITEBOX PROBES <---
  assign vif.wb_iddr_rx_dv       = u_dut.rx_dv;
  assign vif.wb_iddr_rx_er       = u_dut.rx_er;
  assign vif.wb_rx_if_state      = u_dut.u_eth_rx_IF.state;
  assign vif.wb_rx_fifo_if_state = u_dut.u_eth_rx_fifo_IF.state;

  // ---> 7. UNIFIED TIMING & BOOTSTRAP <---
  
  // Block 1: The Clock Generators (Starts at Time 0)
  initial begin 
    clk     = 0;
    clk_270 = 0;
    fork
        forever #4 clk = ~clk;
        begin
            #6; // Shift 270 degrees
            forever #4 clk_270 = ~clk_270;
        end
    join_none
  end

  // Block 2: System Reset (Starts at Time 0, runs in parallel)
  initial begin
    rst_n = 0;
    #100;
    @(negedge clk);
    rst_n = 1;
  end

  // Block 3: UVM Entry Point (MUST be at Time 0)
  initial begin 
    uvm_config_db#(virtual mac_rx_if)::set(null, "*", "vif", vif); 
    run_test("mac_rx_base_test"); 
  end

endmodule

// ========================================================
// TESTBENCH MOCK FIFO (Bypasses Xilinx simulation crashes)
// ========================================================
module tb_mock_fifo #(
    parameter integer PARAM_DATA_WIDTH = 8,
    parameter PARAM_FIFO_SIZE = "18Kb"
)(
    input  rst_n,
    input  wr_clk,
    input  [PARAM_DATA_WIDTH-1:0] data_in,
    input  wr_en,
    input  rd_clk,
    input  rd_en,
    output reg [PARAM_DATA_WIDTH-1:0] data_out,
    output logic fifo_full,
    output logic fifo_empty
);
    logic [7:0] mem [0:4095];
    logic [11:0] wr_ptr = 0;
    logic [11:0] rd_ptr = 0;
    logic [12:0] count = 0;

    assign fifo_full = (count == 4096);
    assign fifo_empty = (count == 0);

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !fifo_full) begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            data_out <= 0;
        end else if (rd_en && !fifo_empty) begin
            data_out <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            if (wr_en && !rd_en && !fifo_full) count <= count + 1;
            else if (!wr_en && rd_en && !fifo_empty) count <= count - 1;
        end
    end
endmodule