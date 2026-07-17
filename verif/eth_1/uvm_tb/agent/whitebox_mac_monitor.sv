////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : whitebox_mac_monitor.sv
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
//  UVM monitor for Ethernet whitebox MAC verification
////////////////////////////////////////////////////////////////////////////////

`ifndef WHITEBOX_MAC_MONITOR_SV
`define WHITEBOX_MAC_MONITOR_SV

class whitebox_mac_monitor extends uvm_monitor;
  `uvm_component_utils(whitebox_mac_monitor)
  virtual mac_rx_if vif; 

  // State Enums for pretty printing
  string rx_if_state_str[4] = '{"IDLE", "CRC_CAPTURE", "CRC_CHECK", "ACQ_DONE"};
  string gatekeeper_state_str[8] = '{"IDLE", "INVALID_BYTE_CHECK", "INVALID_BYTE_WAIT", "INVALID_BYTE_COUNT", "RST_STATE", "WAIT_STATE", "BYTE_ACQ_STATE", "ACQ_DONE"};

  function new(string name="whitebox_mac_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    if(!uvm_config_db#(virtual mac_rx_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF in Whitebox Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [1:0] prev_rx_if_state = 2'b00;
    bit [2:0] prev_gk_state = 3'b000;
    
    wait(vif.rst_n == 1'b1);

    `uvm_info("WHITEBOX", "Passive Probe Armed and Watching FSMs...", UVM_NONE)

    forever begin
      @(posedge vif.clk);
      
      // 1. Watch for Physical Layer Error Spikes
      if (vif.wb_iddr_rx_er == 1'b1 && vif.wb_iddr_rx_dv == 1'b1) begin
          `uvm_warning("WHITEBOX_PHY", "HARDWARE FAULT DETECTED: rx_er spike on the IDDR line!")
      end

      // 2. Watch the First FSM (eth_rx_IF)
      if (vif.wb_rx_if_state != prev_rx_if_state) begin
          `uvm_info("WHITEBOX_MAC", $sformatf("FSM Transition: %s ---> %s", 
                    rx_if_state_str[prev_rx_if_state], rx_if_state_str[vif.wb_rx_if_state]), UVM_HIGH)
          prev_rx_if_state = vif.wb_rx_if_state;
      end
      
      // 3. Watch the Second FSM (eth_rx_fifo_IF)
      if (vif.wb_rx_fifo_if_state != prev_gk_state) begin
          `uvm_info("WHITEBOX_GK", $sformatf("Gatekeeper Transition: %s ---> %s", 
                    gatekeeper_state_str[prev_gk_state], gatekeeper_state_str[vif.wb_rx_fifo_if_state]), UVM_HIGH)
          prev_gk_state = vif.wb_rx_fifo_if_state;
      end
      
    end
  endtask
endclass

`endif