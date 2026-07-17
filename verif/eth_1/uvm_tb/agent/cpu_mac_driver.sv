////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cpu_mac_driver.sv
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
//  UVM driver for Ethernet CPU MAC verification
////////////////////////////////////////////////////////////////////////////////

`ifndef CPU_MAC_DRIVER_SV
`define CPU_MAC_DRIVER_SV

class cpu_mac_driver extends uvm_driver #(mac_rx_cpu_seq_item);
  `uvm_component_utils(cpu_mac_driver)
  virtual mac_rx_if vif; 

  function new(string name="cpu_mac_driver", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual mac_rx_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No Virtual Interface in CPU Driver")
  endfunction

  virtual task run_phase(uvm_phase phase);
    int frame_sizes[$]; // The Pipeline Queue
    
    vif.ext_fifo_rd_en <= 1'b0;
    wait(vif.rst_n == 1'b1);
    
    fork
        // Thread 1: Keep UVM Sequencer Happy
        forever begin
            seq_item_port.get_next_item(req);
            @(posedge vif.clk);
            seq_item_port.item_done();
        end
        
        // Thread 2: The Interrupt Catcher (Never misses an edge!)
        forever begin
            @(posedge vif.clk);
            if (vif.eth_rx_data_valid == 1'b1) begin
                frame_sizes.push_back(vif.valid_eth_frame);
            end
        end
        
        // Thread 3: The Slow Memory Reader
        forever begin
            wait(frame_sizes.size() > 0);
            begin
                int size = frame_sizes.pop_front();
                `uvm_info("CPU_DRV", $sformatf("Interrupt Received! Reading %0d bytes...", size), UVM_MEDIUM)
                
                for (int i = 0; i < size; i++) begin
                    vif.ext_fifo_rd_en <= 1'b1;
                    @(posedge vif.clk);
                end
                
                vif.ext_fifo_rd_en <= 1'b0;
                @(posedge vif.clk); // 1 cycle breather
            end
        end
    join
  endtask
endclass

`endif
/*`ifndef CPU_MAC_DRIVER_SV
`define CPU_MAC_DRIVER_SV

class cpu_mac_driver extends uvm_driver #(mac_rx_cpu_seq_item);
  `uvm_component_utils(cpu_mac_driver)
  virtual mac_rx_if vif; 

  function new(string name="cpu_mac_driver", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual mac_rx_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No Virtual Interface in CPU Driver")
  endfunction

  virtual task run_phase(uvm_phase phase);
    int frame_sizes[$]; 
    
    vif.ext_fifo_rd_en <= 1'b0;
    wait(vif.rst_n == 1'b1);
    
    fork
        // Thread 1: Keep UVM Sequencer Happy
        forever begin
            seq_item_port.get_next_item(req);
            @(posedge vif.clk);
            seq_item_port.item_done();
        end
        
        // Thread 2: The Interrupt Catcher
        forever begin
            @(posedge vif.clk);
            if (vif.eth_rx_data_valid == 1'b1) begin
                frame_sizes.push_back(vif.valid_eth_frame);
            end
        end
        
        // Thread 3: The Lightning-Fast Memory Reader (Zero-Delay)
        forever begin
            wait(frame_sizes.size() > 0);
            begin
                int size = frame_sizes.pop_front();
                `uvm_info("CPU_DRV", $sformatf("Interrupt Received! Reading %0d bytes instantly...", size), UVM_MEDIUM)
                
                // Assert Read Enable
                vif.ext_fifo_rd_en <= 1'b1;
                
                // Allow exactly 1 clock cycle for the RAM read latency to process
                @(posedge vif.clk); 
                
                // Instantly consume all bytes using delta cycles (no clock waits!)
                for (int i = 0; i < size; i++) begin
                    // We don't actually capture the data here, the Monitor handles that.
                    // We just need the loop to advance to satisfy the size requirement.
                    #0; // Yield to delta cycle
                end
                
                // Turn off Read Enable in the exact same clock cycle
                vif.ext_fifo_rd_en <= 1'b0;
            end
        end
    join
  endtask
endclass

`endif*/