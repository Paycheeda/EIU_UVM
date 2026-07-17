////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_out_monitor.sv
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
//  UVM monitor for UART RX output verification
////////////////////////////////////////////////////////////////////////////////

class rx_out_monitor extends uvm_monitor;
  `uvm_component_utils(rx_out_monitor)

  uvm_analysis_port#(rx_uart) mon_analysis_port;
  virtual uart_rx_out_intf    vif;

  // =============================
  // Constructor Method
  // ============================= 
  function new(string name="rx_out_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  // =============================
  // Build Phase Method
  // ============================= 
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(virtual uart_rx_out_intf)::get(this, "", "uart_rx_out_intf", vif))
      `uvm_fatal("RX_OUT_MONITOR", "Could not get out vif")
      
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction 

  // =============================
  // Main Phase Method
  // ============================= 
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask 

  // =============================
  // The Collector Task
  // ============================= 
  task collect_data();
    rx_uart pkt; 
    forever begin
      @(posedge vif.clk);
      
      if (vif.data_ready_pulse === 1'b1) begin
        
        if (vif.uart_rx_busy !== 1'b0) begin
          `uvm_error("RX_PROTOCOL_ERR", "RTL fired data_ready_pulse but uart_rx_busy is still HIGH! State machine violation.")
        end

        pkt = rx_uart::type_id::create("pkt"); 
        
        pkt.data_out            = vif.data_out;
        pkt.flag_packet_corrupt = vif.flag_packet_corrupt;
        
        pkt.data_width          = vif.data_width;
        pkt.baudrate            = vif.baudrate;
        pkt.parity_en           = vif.parity_en;
        pkt.parity_odd_even     = vif.parity_odd_even;

        mon_analysis_port.write(pkt);
        
        `uvm_info("RX_OUT_MONITOR", $sformatf("Sampled Parallel Output: 0x%0h (Bin: %0b) | Corrupt Flag: %0b", 
                  pkt.data_out, pkt.data_out, pkt.flag_packet_corrupt), UVM_LOW)
      end
    end
  endtask

endclass