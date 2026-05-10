////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart_tx_sequence.sv
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
//  stimulus sequence for uart TX
////////////////////////////////////////////////////////////////////////////////

class uart_tx_sequence extends uvm_sequence #(tx_uart);
  `uvm_object_utils(uart_tx_sequence)

  // This will be set by the Master Sequence
  int num_packets; 

  function new (string name = "uart_tx_sequence");
    super.new(name); 
  endfunction 

  virtual task body();
    `uvm_info("UART_TX_SEQ", $sformatf("Generating %0d Dynamic TX UART Packets...", num_packets), UVM_LOW)

    for (int i = 0; i < num_packets; i++) begin
      
      req = tx_uart::type_id::create("req");
      start_item(req);
      
      // ========================================================
      // PRO-SAN FIX: The sequence no longer needs to do the math!
      // We just call the custom function we built in tx_uart.sv
      // ========================================================
      req.randomize_packet(); 
            
      finish_item(req);  
      
    end
    
    `uvm_info("UART_TX_SEQ", $sformatf("Done generating %0d TX items", num_packets), UVM_LOW)
  endtask

endclass // uart_tx_sequence