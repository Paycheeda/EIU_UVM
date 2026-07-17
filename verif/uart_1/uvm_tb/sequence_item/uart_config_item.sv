////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart_config_item.sv
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
//  UVM sequence item for UART verification
////////////////////////////////////////////////////////////////////////////////

class uart_config_item extends uvm_sequence_item;
  `uvm_object_utils(uart_config_item)

  // Configuration Variables
  rand bit [31:0] baudrate;
  rand bit        parity_en;
  rand bit        parity_odd_even;
  rand bit [3:0]  data_width;

  // Real-world Hardware Constraints
  // 1. Only allow standard baud rates supported by your RTL's clock divider
  constraint c_baudrate {
    baudrate inside {9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600};
  }

  // 2. Your RTL parameters dictate max width is 9. Let's test standard 8 and 9.
  constraint c_data_width {
    data_width inside {4'd8, 4'd9};
  }

  function new(string name = "uart_config_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("Baud: %0d | Width: %0d | Parity_EN: %0b | Odd/Even: %0b", 
                     baudrate, data_width, parity_en, parity_odd_even);
  endfunction
endclass