////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : host_rx_monitor.sv
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
//  UVM monitor for UART host RX verification
////////////////////////////////////////////////////////////////////////////////

class host_rx_monitor extends uvm_monitor;
  `uvm_component_utils(host_rx_monitor)

  function new(string name="host_rx_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  uvm_analysis_port#(rx_uart) mon_analysis_port; 
  virtual uart_unified_intf   vif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_unified_intf)::get(this, "", "uart_unified_intf", vif))
      `uvm_fatal("HOST_RX_MONITOR", "Could not get unified vif")
      
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask 

  task collect_data();
    rx_uart pkt; 
    
    forever begin
      @(posedge vif.clk);
      
      if (vif.RX_DATA_RECEIVED === 1'b1) begin
        
        pkt = rx_uart::type_id::create("pkt"); 
        
        pkt.data_out            = vif.data_out_RX;
        pkt.flag_packet_corrupt = vif.flag_packet_RX_corrupt;

        pkt.baudrate        = vif.baudrate;
        pkt.data_width      = vif.data_width;
        pkt.parity_en       = vif.parity_en;
        pkt.parity_odd_even = vif.parity_odd_even;
        
        mon_analysis_port.write(pkt);
        
        begin
          string corrupt_str = pkt.flag_packet_corrupt ? "*CORRUPT*" : "CLEAN";
          
          `uvm_info("HOST_RX_MONITOR", $sformatf("CPU Read Interrupt: Data=0x%0h (Bin: %0b) | Status: %s | (Width: %0d, Baud: %0d)", 
                    pkt.data_out, pkt.data_out, corrupt_str, pkt.data_width, pkt.baudrate), UVM_LOW) 
        end
        
      end
    end
  endtask

endclass