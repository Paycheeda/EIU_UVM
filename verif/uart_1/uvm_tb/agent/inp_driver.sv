////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : inp_driver.sv
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
//  UVM driver for UART input verification
////////////////////////////////////////////////////////////////////////////////

class inp_driver extends uvm_driver #(tx_uart);
  `uvm_component_utils(inp_driver)

  virtual uart_tx_intf  in_vif;
  virtual uart_out_intf out_vif;

  function new(string name = "inp_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_tx_intf)::get(this, "", "uart_tx_intf", in_vif))
      `uvm_fatal("INP_DRIVER", "Could not get input vif")
    if (!uvm_config_db#(virtual uart_out_intf)::get(this, "", "uart_out_intf", out_vif))
      `uvm_fatal("INP_DRIVER", "Could not get output vif")
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);

    // Initialize all inputs to safe idle states
    in_vif.data_start_pulse <= 1'b0;
    in_vif.baudrate_valid   <= 1'b0;
    in_vif.data_in          <= 0;

    wait(in_vif.rst_n == 1'b1);

    forever begin
      seq_item_port.get_next_item(req); 
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask 

  virtual task drive_item(tx_uart drv_pkt); 
    
    // ========================================================
    // STEP 1: CONFIGURE THE DYNAMIC HARDWARE PINS
    // ========================================================
    @(posedge in_vif.clk);
    in_vif.baudrate       <= drv_pkt.baudrate;
    in_vif.data_width     <= drv_pkt.data_width;
    in_vif.baudrate_valid <= 1'b1;
    
    @(posedge in_vif.clk);
    in_vif.baudrate_valid <= 1'b0;

    // Give the RTL state machine a few cycles to divide the clock 
    // and load the new clock_delay_param
    repeat(5) @(posedge in_vif.clk);

    // ========================================================
    // STEP 2: LOAD PAYLOAD AND FIRE START PULSE
    // ========================================================
    in_vif.data_in         <= drv_pkt.data_in; 
    in_vif.parity_en       <= drv_pkt.parity_en;
    in_vif.parity_odd_even <= drv_pkt.parity_odd_even;
    in_vif.data_start_pulse <= 1'b1; 
    
    @(posedge in_vif.clk);
    in_vif.data_start_pulse <= 1'b0;  
    
    // ========================================================
    // STEP 3: WAIT FOR COMPLETION
    // ========================================================
    wait(out_vif.data_ready_pulse == 1'b1);
    
    wait(out_vif.uart_tx_busy == 1'b0);

    repeat(50) @(posedge in_vif.clk);
    
    begin
      string frame_str = "[0]_"; // START Bit
      
      frame_str = {frame_str, "["};
      for (int i = 0; i < drv_pkt.data_width; i++) begin
        frame_str = {frame_str, $sformatf("%b", drv_pkt.data_in[i])}; // DATA Bits
      end
      frame_str = {frame_str, "]"};

      if (drv_pkt.parity_en == 1'b1) begin
        frame_str = {frame_str, "_[", $sformatf("%b", drv_pkt.expected_parity), "]"}; // PARITY
      end

      frame_str = {frame_str, "_[1]"}; // STOP Bit

      `uvm_info("TX_INP_DRIVER", $sformatf("Injected Config: Width=%0d, Baud=%0d | Payload Frame Expected: %s", 
                drv_pkt.data_width, drv_pkt.baudrate, frame_str), UVM_HIGH)
    end
    
  endtask 

endclass