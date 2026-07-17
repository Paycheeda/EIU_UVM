////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_if_driver.sv
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
//  UVM driver for Ethernet RX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_RX_IF_DRIVER_SV
`define ETH_RX_IF_DRIVER_SV

class eth_rx_if_driver extends uvm_driver #(phy_rx_seq_item);
    `uvm_component_utils(eth_rx_if_driver)
    virtual eth_rx_if vif;

    function new(string name = "eth_rx_if_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual eth_rx_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual IF not found in RX Driver")
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("RX_DRV", "Driver starting... Waiting for reset.", UVM_LOW)
        vif.rxd <= 0; vif.rx_dv <= 0; vif.rx_er <= 0;
        wait(vif.rst_n == 1'b1);
        `uvm_info("RX_DRV", "Reset cleared! Entering main loop.", UVM_LOW)

        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("RX_DRV", "Received new packet from sequence. Generating Checksums and Driving...", UVM_HIGH)
            drive_packet(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_packet(phy_rx_seq_item req);
        bit [7:0] frame_data[$]; 
        bit [31:0] fcs;          
        bit [15:0] ip_chk, udp_chk;
        int ip_len, udp_len;
        int byte_idx = 0;
        byte unsigned current_byte;

        // ========================================================
        // 1. CALCULATE LENGTHS & CHECKSUMS
        // ========================================================
        udp_len = req.payload.size() + 8;
        ip_len  = udp_len + 20;

        req.total_length = ip_len;
        
        ip_chk = calc_ipv4_checksum(req);
        udp_chk = calc_udp_checksum(req, udp_len);

        // ========================================================
        // 2. ASSEMBLE PERFECT ETHERNET FRAME
        // ========================================================
        for (int i=5; i>=0; i--) frame_data.push_back(req.dest_mac[i*8 +: 8]);
        for (int i=5; i>=0; i--) frame_data.push_back(req.source_mac[i*8 +: 8]);
        for (int i=1; i>=0; i--) frame_data.push_back(req.eth_type[i*8 +: 8]);
        
        frame_data.push_back({req.version, req.ihl}); 
        frame_data.push_back(req.tos);
        frame_data.push_back(req.total_length[15:8]); frame_data.push_back(req.total_length[7:0]);
        frame_data.push_back(req.id[15:8]);           frame_data.push_back(req.id[7:0]);
        frame_data.push_back({req.flags, req.frag_offset[12:8]}); frame_data.push_back(req.frag_offset[7:0]);
        frame_data.push_back(req.ttl);                frame_data.push_back(req.protocol);
        frame_data.push_back(ip_chk[15:8]);           frame_data.push_back(ip_chk[7:0]);
        for (int i=3; i>=0; i--) frame_data.push_back(req.src_ip[i*8 +: 8]);
        for (int i=3; i>=0; i--) frame_data.push_back(req.dest_ip[i*8 +: 8]);

        frame_data.push_back(req.source_port[15:8]);  frame_data.push_back(req.source_port[7:0]);
        frame_data.push_back(req.dest_port[15:8]);    frame_data.push_back(req.dest_port[7:0]);
        frame_data.push_back(udp_len[15:8]);          frame_data.push_back(udp_len[7:0]);
        frame_data.push_back(udp_chk[15:8]);          frame_data.push_back(udp_chk[7:0]);
        
        foreach(req.payload[i]) frame_data.push_back(req.payload[i]);

        // ========================================================
        // 3. GENERATE CRC-32 (FCS)
        // ========================================================
        fcs = calc_crc32(frame_data);
        if (req.inject_crc_error) begin
            fcs = ~fcs; 
            `uvm_warning("RX_DRV", "FAULT INJECTED: Corrupted CRC!")
        end
        frame_data.push_back(fcs[7:0]);   frame_data.push_back(fcs[15:8]);
        frame_data.push_back(fcs[23:16]); frame_data.push_back(fcs[31:24]);

        // ========================================================
        // 4. TRUE DDR PHYSICAL TRANSMISSION (Phase-Shifted)
        // ========================================================
        `uvm_info("RX_DRV", "Driving TRUE DDR Preamble...", UVM_HIGH)
        
        // Setup for the very first POSEDGE (Change on Negedge)
        @(posedge vif.clk);
        vif.rx_dv <= 1'b1;
        vif.rxd   <= 4'h5; 
        
        // Setup for the very first NEGEDGE (Change on Posedge)
        @(negedge vif.clk);
        vif.rxd   <= 4'h5; 
        
        // Bytes 2 through 7 (6 bytes of 0x55)
        for(int i=0; i<6; i++) begin
           @(posedge vif.clk); vif.rxd <= 4'h5;
           @(negedge vif.clk); vif.rxd <= 4'h5;
        end
        
        // Byte 8: Start of Frame Delimiter (0xD5)
        @(posedge vif.clk); vif.rxd <= 4'h5; // Lower Nibble
        @(negedge vif.clk); vif.rxd <= 4'hD; // Upper Nibble

        `uvm_info("RX_DRV", $sformatf("Driving %0d bytes of DDR Frame Data...", frame_data.size()), UVM_HIGH)
        
        while(frame_data.size() > 0) begin
           current_byte = frame_data.pop_front();
           
           // Setup data to be stable for POSITIVE EDGE
           @(posedge vif.clk);
           if (req.early_drop_at_byte > 0 && byte_idx == req.early_drop_at_byte) begin
               vif.rx_dv <= 1'b0;
               break;
           end
           if (req.inject_rx_er_at_byte > 0 && byte_idx == req.inject_rx_er_at_byte) vif.rx_er <= 1'b1;
           else vif.rx_er <= 1'b0;
           
           vif.rxd <= current_byte[3:0]; 
           
           // Setup data to be stable for NEGATIVE EDGE
           @(negedge vif.clk);
           vif.rxd <= current_byte[7:4];
           
           byte_idx++;
        end

        // Close Frame
        @(posedge vif.clk);
        vif.rx_dv <= 1'b0;
        vif.rx_er <= 1'b0;
        vif.rxd   <= 4'h0;

        // Race condition timeout guard
        fork
            begin
                wait(vif.rx_transaction_done_pulse == 1'b1);
                `uvm_info("RX_DRV", "SUCCESS: RTL pulsed transaction done!", UVM_HIGH)
            end
            begin
                repeat(400) @(posedge vif.clk); 
                `uvm_error("RX_DRV_WATCHDOG", "FATAL HANG: RTL never pulsed rx_transaction_done_pulse! Checksum or Length mismatch.")
            end
        join_any
        disable fork; 
        
        @(negedge vif.clk);
    endtask

    // Checksum Utilities
    function bit [15:0] calc_ipv4_checksum(phy_rx_seq_item req);
        bit [31:0] sum = {req.version, req.ihl, req.tos} + req.total_length + req.id + {req.flags, req.frag_offset} + {req.ttl, req.protocol} + req.src_ip[31:16] + req.src_ip[15:0] + req.dest_ip[31:16] + req.dest_ip[15:0];
        sum = (sum & 32'hFFFF) + (sum >> 16); 
        sum = (sum & 32'hFFFF) + (sum >> 16);
        return ~sum[15:0];
    endfunction

    function bit [15:0] calc_udp_checksum(phy_rx_seq_item req, int udp_len);
        bit [31:0] sum = req.src_ip[31:16] + req.src_ip[15:0] + req.dest_ip[31:16] + req.dest_ip[15:0] + {8'h00, req.protocol} + udp_len + req.source_port + req.dest_port + udp_len;
        for(int i=0; i<req.payload.size(); i=i+2) begin
            sum += (i+1 < req.payload.size()) ? {req.payload[i], req.payload[i+1]} : {req.payload[i], 8'h00};
        end
        sum = (sum & 32'hFFFF) + (sum >> 16); 
        sum = (sum & 32'hFFFF) + (sum >> 16);
        if (~sum[15:0] == 16'h0000) return 16'hFFFF;
        return ~sum[15:0];
    endfunction

    function bit [31:0] calc_crc32(bit [7:0] dq[$]);
        bit [31:0] crc = 32'hFFFFFFFF; 
        bit [31:0] poly = 32'hEDB88320;
        foreach(dq[i]) begin
            for(int j=0; j<8; j++) begin
                crc = ((crc[0] ^ dq[i][j]) == 1'b1) ? (crc >> 1) ^ poly : (crc >> 1);
            end
        end
        return ~crc;
    endfunction
endclass

`endif