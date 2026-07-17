////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart_short_test.sv
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
//  short UVM test for UART verification
////////////////////////////////////////////////////////////////////////////////

class uart_short_test extends uart_base_test;
  `uvm_component_utils(uart_short_test)
  
  function new(string name = "uart_short_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     `uvm_info("UART_SHORT_TEST", "Starting UART short_test... overriding config.", UVM_MEDIUM)
     cfg.num_uart_packets = 5;
  endfunction
endclass
