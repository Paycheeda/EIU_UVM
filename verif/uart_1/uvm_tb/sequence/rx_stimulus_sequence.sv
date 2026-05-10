////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_stimulus_sequence.sv
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
//  stimulus sequence for uart RX
////////////////////////////////////////////////////////////////////////////////

class rx_stimulus_sequence extends uvm_sequence #(rx_uart);
  `uvm_object_utils(rx_stimulus_sequence)

  int num_packets; // Set by the main sequence

  function new(string name = "rx_stimulus_sequence");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < num_packets; i++) begin
      req = rx_uart::type_id::create("req");
      
      start_item(req);

      // Call our custom manual randomizer!
      req.randomize_packet(); 

      finish_item(req); 
    end
  endtask
endclass