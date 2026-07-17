////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fifo_item.sv
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
//  UVM sequence item for UART FIFO verification
////////////////////////////////////////////////////////////////////////////////

class fifo_item extends uvm_sequence_item;
  `uvm_object_utils(fifo_item)

  // Physical Data
  rand bit [8:0] data; 
  rand bit       corrupt;
  

  // Testbench Control: How many clock cycles to wait before writing/reading
  rand int       delay_cycles;

  // Most packets should be clean, but throw in a 5% chance of a corrupt flag
  constraint corrupt_c { corrupt dist {0 := 95, 1 := 5}; } 
  
  // Keep delays reasonable to cause bursts of traffic
  constraint delay_c   { delay_cycles inside {[0:10]}; }

  function new(string name = "fifo_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("Data: 0x%0h | Corrupt: %0b | Delay: %0d", data, corrupt, delay_cycles);
  endfunction

endclass