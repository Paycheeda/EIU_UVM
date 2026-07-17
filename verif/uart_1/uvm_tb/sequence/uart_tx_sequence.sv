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
//  UVM sequence for UART TX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef UART_TX_SEQUENCE_SV
`define UART_TX_SEQUENCE_SV

class uart_tx_sequence extends uvm_sequence #(tx_uart);
    `uvm_object_utils(uart_tx_sequence)

    int num_packets = 10;
    
    // Dynamic Config Variables
    int req_width = 8;
    int parity_en = 0;
    int parity_oe = 0;

    function new(string name = "uart_tx_sequence");
        super.new(name);
    endfunction

    virtual task body();
        // Fetch Plusargs directly into the sequence
        $value$plusargs("NUM_PKTS=%d", num_packets);
        $value$plusargs("UART_WIDTH=%d", req_width);
        $value$plusargs("UART_PARITY_EN=%d", parity_en);
        $value$plusargs("UART_PARITY_OE=%d", parity_oe);

        `uvm_info("UART_TX_SEQ", $sformatf("Generating %0d Packets | Width: %0d | Parity EN: %0d | Parity OE: %0d", 
                  num_packets, req_width, parity_en, parity_oe), UVM_LOW)

        for (int i = 0; i < num_packets; i++) begin
            req = tx_uart::type_id::create("req");
            start_item(req);
            
            req.baudrate        = 115200; // Driver dynamically overrides this via cfg anyway
            req.data_width      = req_width;  
            req.parity_en       = parity_en;  
            req.parity_odd_even = parity_oe;
            
            // Constrain random data to EXACTLY the data width (e.g., 8-bit = max 255, 9-bit = max 511)
            req.data_in = $urandom_range(0, (1 << req_width) - 1);
            
            // Mathematically calculate the parity bit for the Driver to send
            if (parity_en == 1) begin
                bit calc_p = ^req.data_in; // XOR reduction gives Even Parity
                if (parity_oe == 1) calc_p = ~calc_p; // Invert for Odd Parity
                
                req.sampled_parity = calc_p;
                req.expected_parity = calc_p;
            end
            
            finish_item(req);
        end
    endtask
endclass

`endif