`ifndef ETH_TX_DRIVER_SV
`define ETH_TX_DRIVER_SV

class eth_tx_driver extends uvm_driver #(eth_tx_seq_item);
  `uvm_component_utils(eth_tx_driver)
  virtual eth_tx_if vif;
  virtual fault_inject_if fi_vif;

  // ---> NEW: Performance Profiling Variables <---
  int pkt_num = 0; 
  real start_time_ns;
  real end_time_ns;
  real diff_us;
  real throughput_mbps; // Holds the calculated Mbps

  function new(string name = "eth_tx_driver", uvm_component parent = null); 
    super.new(name, parent); 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual eth_tx_if)::get(this, "", "tx_vif", vif)) 
      `uvm_fatal("NO_VIF", "Virtual IF not found")
    if(!uvm_config_db#(virtual fault_inject_if)::get(this, "", "fi_vif", fi_vif)) 
      `uvm_fatal("NO_FI_VIF", "Fault Inject IF not found")
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.config_done_pulse  <= 0; 
    vif.eth_tx_start_pulse <= 0; 
    vif.ext_tx_fifo_wr_en  <= 0;
    vif.ext_tx_fifo_data_in <= 0;
    
    fi_vif.fault_type <= FAULT_NONE;
    
    wait(vif.rst_n == 1'b1);
    repeat(50) @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(req);
      
      // Increment packet counter for the log
      pkt_num++; 
      
      // =========================================================
      // STEP 1: DRIVE METADATA
      // =========================================================
      vif.dest_mac       <= req.dest_mac; 
      vif.source_mac     <= req.source_mac; 
      vif.source_ip      <= req.src_ip; 
      vif.dest_ip        <= req.dest_ip;
      vif.source_port    <= req.source_port; 
      vif.dest_port      <= req.dest_port;
      vif.payload_length <= req.payload.size();
      
      // =========================================================
      // STEP 2: WRITE PAYLOAD 
      // =========================================================
      `uvm_info("DRV_DBG", $sformatf("Bursting %0d bytes into Physical TX FIFO...", req.payload.size()), UVM_LOW)
      if (req.payload.size() > 0) begin
        foreach(req.payload[i]) begin
          vif.ext_tx_fifo_wr_en   <= 1'b1;
          vif.ext_tx_fifo_data_in <= req.payload[i];
          @(posedge vif.clk);
        end
        vif.ext_tx_fifo_wr_en <= 1'b0; 
        
        wait(vif.tx_fifo_empty == 1'b0);
        @(posedge vif.clk); 
      end
      
      fi_vif.fault_type <= req.fault_type;

      // =========================================================
      // STEP 3: TRIGGER MAC & MEASURE PERFORMANCE
      // =========================================================
      `uvm_info("DRV_DBG", "Payload written. Firing config_done AND tx_start simultaneously!", UVM_LOW)
      
      // ---> CLICK! Start the stopwatch right as the pulse fires <---
      start_time_ns = $realtime;
      
      vif.config_done_pulse  <= 1'b1;
      vif.eth_tx_start_pulse <= 1'b1;
      repeat(3) @(posedge vif.clk); 
      vif.config_done_pulse  <= 1'b0;
      vif.eth_tx_start_pulse <= 1'b0;

      `uvm_info("DRV_DBG", "Transmission authorized. Waiting for MAC to return eth_tx_data_sent...", UVM_LOW)
      
      if (vif.eth_tx_data_sent == 1'b1) begin
          while (vif.eth_tx_data_sent == 1'b1) @(posedge vif.clk);
      end
      while (vif.eth_tx_data_sent == 1'b0) @(posedge vif.clk);

      // ---> CLICK! Stop the stopwatch the exact cycle the MAC finishes <---
      end_time_ns = $realtime;

      // Calculate time in microseconds (us)
      diff_us = (end_time_ns - start_time_ns) / 1000.0;

      // Calculate Wire-Level Throughput in Mbps
      // (Bits / us = Megabits / sec)
      throughput_mbps = (real'(req.payload.size() + 54) * 8.0) / diff_us;

      // ---> PRINT THE METRIC <---
      `uvm_info("THROUGHPUT", 
                $sformatf("Packet %0d | Payload: %0d Bytes | TX Time: %0.3f us | Speed: %0.2f Mbps", 
                          pkt_num, req.payload.size(), diff_us, throughput_mbps), 
                UVM_NONE)

      repeat(12) @(posedge vif.clk);

      `uvm_info("DRV_DBG", "MAC finished sending! Packet complete.", UVM_LOW)
      
      fi_vif.fault_type <= FAULT_NONE;
      seq_item_port.item_done();
    end
  endtask
endclass
`endif