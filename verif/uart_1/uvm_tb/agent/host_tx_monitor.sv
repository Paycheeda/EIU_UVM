////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : host_tx_monitor.sv
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
//  UVM monitor for UART host TX verification
////////////////////////////////////////////////////////////////////////////////

class host_tx_monitor extends uvm_monitor;
  `uvm_component_utils(host_tx_monitor)

  function new(string name="host_tx_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  uvm_analysis_port#(tx_uart) mon_analysis_port; 
  virtual uart_unified_intf   vif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_unified_intf)::get(this, "", "uart_unified_intf", vif))
      `uvm_fatal("HOST_TX_MONITOR", "Could not get unified vif")
      
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask 

  task collect_data();
    tx_uart pkt; 
    
    forever begin
      @(posedge vif.clk);
      
      if (vif.send_data_tx === 1'b1) begin
        
        pkt = tx_uart::type_id::create("pkt"); 
        
        pkt.baudrate        = vif.baudrate;
        pkt.data_width      = vif.data_width;
        pkt.data_in         = vif.data_in_TX;
        pkt.parity_en       = vif.parity_en;
        pkt.parity_odd_even = vif.parity_odd_even;
        
        // Calculate expected parity based on sampled configuration
        if (pkt.parity_en) begin
          if (pkt.parity_odd_even == 1'b1)
            pkt.expected_parity = ~(^pkt.data_in);
          else
            pkt.expected_parity = ^pkt.data_in;
        end else begin
            pkt.expected_parity = 1'b0; 
        end

        // Send it out the analysis port to the Scoreboard
        mon_analysis_port.write(pkt);
        
        begin
          string frame_str = "[0]_"; 
          frame_str = {frame_str, "["};
          for (int i = 0; i < pkt.data_width; i++) begin
            frame_str = {frame_str, $sformatf("%b", pkt.data_in[i])}; 
          end
          frame_str = {frame_str, "]"};

          if (pkt.parity_en == 1'b1) begin
            frame_str = {frame_str, "_[", $sformatf("%b", pkt.expected_parity), "]"}; 
          end
          frame_str = {frame_str, "_[1]"}; 

          `uvm_info("HOST_TX_MONITOR", $sformatf("Sampled CPU Write: %s (Width: %0d, Baud: %0d)", 
                    frame_str, pkt.data_width, pkt.baudrate), UVM_LOW) 
        end
        
        wait(vif.send_data_tx === 1'b0);
      end
    end
  endtask

endclass