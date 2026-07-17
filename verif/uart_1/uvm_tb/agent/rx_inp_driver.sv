////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_inp_driver.sv
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
//  UVM driver for UART RX input verification
////////////////////////////////////////////////////////////////////////////////

class rx_inp_driver extends uvm_driver #(rx_uart);
  `uvm_component_utils(rx_inp_driver)

  virtual uart_rx_in_intf  in_vif;
  virtual uart_rx_out_intf out_vif;

  parameter clock_frequency = 32'd44_236_800;

  function new(string name = "rx_inp_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_rx_in_intf)::get(this, "", "uart_rx_in_intf", in_vif))
      `uvm_fatal("RX_INP_DRIVER", "Could not get input vif")
    if (!uvm_config_db#(virtual uart_rx_out_intf)::get(this, "", "uart_rx_out_intf", out_vif))
      `uvm_fatal("RX_INP_DRIVER", "Could not get output vif")
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);

    in_vif.data_rx <= 1'b1;
    in_vif.baudrate_valid <= 1'b0;

    wait(in_vif.rst_n == 1'b1);

    forever begin
      seq_item_port.get_next_item(req); 
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask 
  
  virtual task drive_item(rx_uart drv_pkt); 
    int clock_delay = clock_frequency / drv_pkt.baudrate;

    @(posedge in_vif.clk);
    in_vif.baudrate         <= drv_pkt.baudrate;
    in_vif.data_width       <= drv_pkt.data_width;
    in_vif.parity_en        <= drv_pkt.parity_en;
    in_vif.parity_odd_even  <= drv_pkt.parity_odd_even;
    in_vif.baudrate_valid   <= 1'b1;
    
    #10; 
    in_vif.baudrate_valid   <= 1'b0;

    repeat(clock_delay * 2) @(posedge in_vif.clk);

    // Drive START Bit 
    in_vif.data_rx <= 1'b0;
    repeat(clock_delay) @(posedge in_vif.clk);

    // Drive DATA Bits
    for (int i = 0; i < drv_pkt.data_width; i++) begin
      in_vif.data_rx <= drv_pkt.data_in[i];
      repeat(clock_delay) @(posedge in_vif.clk);
    end

    // Drive PARITY Bit
    if (drv_pkt.parity_en == 1'b1) begin
      in_vif.data_rx <= drv_pkt.expected_parity;
      repeat(clock_delay) @(posedge in_vif.clk);
    end

    // Drive STOP Bit 
    in_vif.data_rx <= 1'b1;
    repeat(clock_delay) @(posedge in_vif.clk);

    // Trailing idle time
    repeat(clock_delay * 2) @(posedge in_vif.clk);
    
      begin
      string frame_str = "[0]_"; // 1. START Bit
      
      frame_str = {frame_str, "["};
      for (int i = 0; i < drv_pkt.data_width; i++) begin
        frame_str = {frame_str, $sformatf("%b", drv_pkt.data_in[i])}; // 2. DATA Bits (LSB -> MSB)
      end
      frame_str = {frame_str, "]"};

      if (drv_pkt.parity_en == 1'b1) begin
        frame_str = {frame_str, "_[", $sformatf("%b", drv_pkt.expected_parity), "]"}; // 3. PARITY Bit
      end

      frame_str = {frame_str, "_[1]"}; // 4. STOP Bit

      // Print the masterpiece!
      `uvm_info("RX_INP_DRIVER", $sformatf("Sent Wire Frame: %s (Width: %0d, Baud: %0d)", 
                frame_str, drv_pkt.data_width, drv_pkt.baudrate), UVM_LOW)
    end
  endtask 
endclass