////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_fifo_scoreboard.sv
//  Author        : Ahmed Ali
//  Creation Date : 16/04/2026
//
//  Copyright 2026 Avant Labs PVT LTD. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    First Floor, Jumaira Arcade,
//    Fateh Jang Road,
//    Sector F-17, Islamabad, 45230
//
//  All information contained in this document is Avant Labs PVT LTD
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  UVM scoreboard for Ethernet RX FIFO verification
////////////////////////////////////////////////////////////////////////////////

`ifndef RX_FIFO_SCOREBOARD_SV
`define RX_FIFO_SCOREBOARD_SV

class rx_fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(rx_fifo_scoreboard)

  // FIFOs to hold incoming transactions from the two monitors
  uvm_tlm_analysis_fifo #(rx_fifo_in_seq_item)  in_fifo;
  uvm_tlm_analysis_fifo #(rx_fifo_out_seq_item) out_fifo;

  int pkts_checked = 0;
  int pkts_passed  = 0;
  int pkts_failed  = 0;

  function new(string name="rx_fifo_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    in_fifo  = new("in_fifo", this);
    out_fifo = new("out_fifo", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    rx_fifo_in_seq_item  in_item;
    rx_fifo_out_seq_item out_item;
    bit packet_passed;

    forever begin
      in_fifo.get(in_item);
      out_fifo.get(out_item);
      
      packet_passed = 1'b1;
      pkts_checked++;

      // ========================================================
      // 1. CORRUPT PATH AUDIT (The Firewall)
      // ========================================================
      if (in_item.is_corrupt) begin
          if (out_item.ext_fifo_data.size() > 0) begin
              `uvm_error("SCB_FAIL", $sformatf("FIREWALL BREACH! Corrupt packet leaked %0d bytes to external memory!", out_item.ext_fifo_data.size()))
              packet_passed = 1'b0;
          end
          if (out_item.ext_rst_n_toggled == 1'b1) begin
              `uvm_error("SCB_FAIL", "RTL toggled external reset during a corrupt flush!")
              packet_passed = 1'b0;
          end
          if (out_item.eth_rx_data_valid_seen == 1'b1) begin
              `uvm_error("SCB_FAIL", "RTL asserted eth_rx_data_valid for a corrupt packet!")
              packet_passed = 1'b0;
          end
          
          if (packet_passed) begin
              `uvm_info("SCB_PASS", $sformatf("Packet %0d (CORRUPT) - Firewall held perfectly. %0d bytes safely flushed internally.", pkts_checked, in_item.invalid_bytes), UVM_NONE)
          end
          
      // ========================================================
      // 2. CLEAN PATH AUDIT (The Transfer)
      // ========================================================
      end else begin
          int expected_size = in_item.payload_length + 42;

          if (out_item.valid_eth_frame_val != expected_size) begin
              `uvm_error("SCB_FAIL", $sformatf("HW Math Error! RTL calculated valid_eth_frame as %0d, but expected %0d", out_item.valid_eth_frame_val, expected_size))
              packet_passed = 1'b0;
          end
          
          if (out_item.ext_fifo_data.size() != expected_size) begin
              `uvm_error("SCB_FAIL", $sformatf("Size Mismatch! Expected: %0d bytes, Output array captured: %0d bytes", expected_size, out_item.ext_fifo_data.size()))
              packet_passed = 1'b0;
          end
          if (out_item.ext_rst_n_toggled == 1'b0) begin
              `uvm_error("SCB_FAIL", "RTL failed to toggle external reset before clean transfer!")
              packet_passed = 1'b0;
          end
          if (out_item.eth_rx_data_valid_seen == 1'b0) begin
              `uvm_error("SCB_FAIL", "RTL failed to assert eth_rx_data_valid at end of transfer!")
              packet_passed = 1'b0;
          end
          
          // If size matches, verify data integrity byte-by-byte
          if (packet_passed) begin
              for (int i = 0; i < expected_size; i++) begin
                  if (in_item.internal_ram_data[i] !== out_item.ext_fifo_data[i]) begin
                      `uvm_error("SCB_FAIL", $sformatf("Data Mismatch at index %0d! Expected: 8'h%02h, Got: 8'h%02h", i, in_item.internal_ram_data[i], out_item.ext_fifo_data[i]))
                      packet_passed = 1'b0;
                      break;
                  end
              end
          end
          
          if (packet_passed) begin
              `uvm_info("SCB_PASS", $sformatf("Packet %0d (CLEAN) - Perfect transfer of %0d bytes.", pkts_checked, expected_size), UVM_NONE)
          end
      end

      if (packet_passed) pkts_passed++;
      else pkts_failed++;
    end
  endtask

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_FINAL_RESULTS", $sformatf({
       "\n==================================================",
       "\n  SMART DMA GATEKEEPER RESULTS",
       "\n==================================================",
       "\n  Total Packets Checked : %0d",
       "\n  Packets PASSED        : %0d",
       "\n  Packets FAILED        : %0d",
       "\n=================================================="
    }, pkts_checked, pkts_passed, pkts_failed), UVM_NONE)
  endfunction

endclass

`endif