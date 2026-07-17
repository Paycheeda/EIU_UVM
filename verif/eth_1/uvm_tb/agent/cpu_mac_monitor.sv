////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cpu_mac_monitor.sv
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
//  UVM monitor for Ethernet CPU MAC verification
////////////////////////////////////////////////////////////////////////////////

`ifndef CPU_MAC_MONITOR_SV
`define CPU_MAC_MONITOR_SV

class cpu_mac_monitor extends uvm_monitor;
  `uvm_component_utils(cpu_mac_monitor)
  virtual mac_rx_if vif; 
  uvm_analysis_port #(mac_rx_cpu_seq_item) mon_ap;

  function new(string name="cpu_mac_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual mac_rx_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF in CPU Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    mac_rx_cpu_seq_item item; 
    bit [7:0] captured_data[$];
    bit rd_en_d1 = 0;
    
    // Pipelined Queues
    typedef enum {CLEAN, CORRUPT} pkt_type_e;
    pkt_type_e pending_pkts[$];
    int pending_sizes[$];
    bit pending_rsts[$];
    
    int last_cc;
    bit rst_flag = 0;

    wait(vif.rst_n == 1'b1);
    last_cc = vif.corrupt_packet_counter;

    fork
        // Thread 1: Snooper (Blindly records all successful reads)
        forever begin
            @(posedge vif.clk);
            if (rd_en_d1) captured_data.push_back(vif.ext_fifo_data_out);
            rd_en_d1 = vif.ext_fifo_rd_en;
        end
        
        // Thread 2: Ext FIFO Reset Watcher
        forever begin
            @(negedge vif.rx_fifo_rst_n);
            rst_flag = 1'b1;
        end
        
        // Thread 3: RTL Event Catcher (Never misses an event!)
        forever begin
            @(posedge vif.clk);
            if (vif.corrupt_packet_counter > last_cc) begin
                last_cc = vif.corrupt_packet_counter;
                wait(vif.wb_iddr_rx_dv == 1'b0);
                pending_pkts.push_back(CORRUPT);
            end
            
            if (vif.eth_rx_data_valid == 1'b1) begin
                pending_pkts.push_back(CLEAN);
                pending_sizes.push_back(vif.valid_eth_frame);
                pending_rsts.push_back(rst_flag);
                rst_flag = 1'b0; // Clear flag for next packet
            end
        end
        
        // Thread 4: Data Processor
        forever begin
            wait(pending_pkts.size() > 0);
            item = mac_rx_cpu_seq_item::type_id::create("item");
            
            if (pending_pkts.pop_front() == CLEAN) begin
                int size = pending_sizes.pop_front();
                item.eth_rx_data_valid_seen = 1'b1;
                item.hw_valid_eth_frame = size;
                item.ext_rst_n_toggled = pending_rsts.pop_front();
                
                // Wait for the Snooper to catch enough bytes
                wait(captured_data.size() >= size);
                
                item.ext_fifo_data = new[size];
                for (int i = 0; i < size; i++) begin
                    item.ext_fifo_data[i] = captured_data.pop_front();
                end
            end else begin
                item.eth_rx_data_valid_seen = 1'b0;
                item.hw_valid_eth_frame = 0;
                item.ext_rst_n_toggled = 1'b0; 
                item.ext_fifo_data = new[0];
                // Short wait to ensure RTL flush clears memory
                repeat(5) @(posedge vif.clk); 
            end
            
            item.hw_corrupt_packet_counter = vif.corrupt_packet_counter;
            
            `uvm_info("CPU_MON", $sformatf("Audit Complete. Ext Bytes Written: %0d | RTL Calculated Frame: %0d | Ext Rst Toggled: %0b | HW Corrupt Counter: %0d", 
                      item.ext_fifo_data.size(), item.hw_valid_eth_frame, item.ext_rst_n_toggled, item.hw_corrupt_packet_counter), UVM_NONE)
            
            mon_ap.write(item);
        end
    join
  endtask
endclass

`endif

/*`ifndef CPU_MAC_MONITOR_SV
`define CPU_MAC_MONITOR_SV

class cpu_mac_monitor extends uvm_monitor;
  `uvm_component_utils(cpu_mac_monitor)
  virtual mac_rx_if vif; 
  uvm_analysis_port #(mac_rx_cpu_seq_item) mon_ap;

  function new(string name="cpu_mac_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual mac_rx_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF in CPU Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    mac_rx_cpu_seq_item item; 
    
    // Pipelined Queues
    typedef enum {CLEAN, CORRUPT} pkt_type_e;
    pkt_type_e pending_pkts[$];
    int pending_sizes[$];
    bit pending_rsts[$];
    
    int last_cc;
    bit rst_flag = 0;

    wait(vif.rst_n == 1'b1);
    last_cc = vif.corrupt_packet_counter;

    fork
        // Thread 1: Ext FIFO Reset Watcher
        forever begin
            @(negedge vif.rx_fifo_rst_n);
            rst_flag = 1'b1;
        end
        
        // Thread 2: RTL Event Catcher
        forever begin
            @(posedge vif.clk);
            if (vif.corrupt_packet_counter > last_cc) begin
                last_cc = vif.corrupt_packet_counter;
                wait(vif.wb_iddr_rx_dv == 1'b0);
                pending_pkts.push_back(CORRUPT);
            end
            
            if (vif.eth_rx_data_valid == 1'b1) begin
                pending_pkts.push_back(CLEAN);
                pending_sizes.push_back(vif.valid_eth_frame);
                pending_rsts.push_back(rst_flag);
                rst_flag = 1'b0; 
            end
        end
        
        // Thread 3: Data Processor (Lightning Fast)
        forever begin
            wait(pending_pkts.size() > 0);
            item = mac_rx_cpu_seq_item::type_id::create("item");
            
            if (pending_pkts.pop_front() == CLEAN) begin
                int size = pending_sizes.pop_front();
                item.eth_rx_data_valid_seen = 1'b1;
                item.hw_valid_eth_frame = size;
                item.ext_rst_n_toggled = pending_rsts.pop_front();
                
                // Wait for the Driver to assert read
                wait(vif.ext_fifo_rd_en == 1'b1);
                
                // Allow the 1 clock cycle RAM latency 
                @(posedge vif.clk); 
                
                item.ext_fifo_data = new[size];
                
                // Because this is simulation, and the RAM is a behavioral model,
                // we can cheat and pull the entire block of data instantly if the 
                // RAM model supports deep indexing. 
                // However, since we are constrained to the physical pins (data_out),
                // we must capture it exactly as the Driver "clocks" it.
                
                for (int i = 0; i < size; i++) begin
                     item.ext_fifo_data[i] = vif.ext_fifo_data_out;
                     #0; // Yield to delta cycle to match the Driver
                end
                
            end else begin
                item.eth_rx_data_valid_seen = 1'b0;
                item.hw_valid_eth_frame = 0;
                item.ext_rst_n_toggled = 1'b0; 
                item.ext_fifo_data = new[0];
            end
            
            item.hw_corrupt_packet_counter = vif.corrupt_packet_counter;
            
            `uvm_info("CPU_MON", $sformatf("Audit Complete. Ext Bytes Written: %0d | RTL Calculated Frame: %0d | Ext Rst Toggled: %0b | HW Corrupt Counter: %0d", 
                      item.ext_fifo_data.size(), item.hw_valid_eth_frame, item.ext_rst_n_toggled, item.hw_corrupt_packet_counter), UVM_NONE)
            
            mon_ap.write(item);
        end
    join
  endtask
endclass

`endif*/