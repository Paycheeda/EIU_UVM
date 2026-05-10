`ifndef RX_FIFO_OUT_MONITOR_SV
`define RX_FIFO_OUT_MONITOR_SV

class rx_fifo_out_monitor extends uvm_monitor;
  `uvm_component_utils(rx_fifo_out_monitor)
  
  virtual eth_rx_fifo_if vif; 
  uvm_analysis_port #(rx_fifo_out_seq_item) mon_ap;

  function new(string name="rx_fifo_out_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual eth_rx_fifo_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF in Output Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    rx_fifo_out_seq_item item; 
    bit [7:0] captured_data[$];
    bit rst_seen;
    bit is_corrupt_txn;

    wait(vif.rst_n == 1'b1);

    forever begin
      captured_data.delete();
      rst_seen = 1'b0;
      
      // Wait for the DMA to be triggered
      wait(vif.rx_transaction_done_pulse == 1'b1);
      is_corrupt_txn = vif.packet_received_corrupt_pulse;
      
      item = rx_fifo_out_seq_item::type_id::create("item");
      
      if (!is_corrupt_txn) begin
          // ========================================================
          // CLEAN PATH: Audit the Memory Transfer
          // ========================================================
          fork
              begin
                  // Thread 1: Wait for completion pulse
                  wait(vif.eth_rx_data_valid == 1'b1);
                  item.eth_rx_data_valid_seen = 1'b1;
              end
              begin
                  // Thread 2: Snoop the Data written to External RAM
                  forever begin
                      @(posedge vif.clk);
                      if (vif.rx_fifo_wr_en) begin
                          captured_data.push_back(vif.rx_fifo_data_in);
                          `uvm_info("OUT_MON_BUS", $sformatf("EXT_FIFO WRITE [%0d] | Data: 8'h%02h", captured_data.size()-1, vif.rx_fifo_data_in), UVM_NONE)
                      end
                  end
              end
              begin
                  // Thread 3: Ensure the External FIFO was properly reset
                  forever begin
                      @(posedge vif.clk);
                      if (vif.ext_fifo_rst_n == 1'b0) rst_seen = 1'b1;
                  end
              end
          join_any
          disable fork; // Kill the snooper threads when data_valid fires
          
          @(posedge vif.clk); // Wait one cycle to let counters settle
          
      end else begin
          // ========================================================
          // CORRUPT PATH: Audit the Memory Firewall
          // ========================================================
          // The DMA should be flushing data internally. 
          // We watch the external pins to ensure ABSOLUTELY NOTHING is written.
          
          int delay_cycles = vif.invalid_bytes + 20; // Give RTL time to flush
          
          fork
              begin
                  repeat(delay_cycles) @(posedge vif.clk);
              end
              begin
                  forever begin
                      @(posedge vif.clk);
                      if (vif.rx_fifo_wr_en) begin
                          captured_data.push_back(vif.rx_fifo_data_in);
                          `uvm_error("OUT_MON_FIREWALL", "FATAL: RTL wrote to external FIFO during a CORRUPT packet flush!")
                      end
                  end
              end
              begin
                  forever begin
                      @(posedge vif.clk);
                      if (vif.ext_fifo_rst_n == 1'b0) rst_seen = 1'b1;
                  end
              end
          join_any
          disable fork;
          
          item.eth_rx_data_valid_seen = 1'b0;
          
          if (rst_seen) `uvm_error("OUT_MON_FIREWALL", "FATAL: RTL reset the external FIFO during a CORRUPT packet flush!")
      end

      // Package the final audit report
      item.ext_rst_n_toggled = rst_seen;
      item.ext_fifo_data = new[captured_data.size()];
      foreach(captured_data[i]) item.ext_fifo_data[i] = captured_data[i];
      
      // Grab the hardware corrupt counter value
      item.corrupt_packet_counter_val = vif.corrupt_packet_counter;
      item.valid_eth_frame_val = vif.valid_eth_frame;
      
      mon_ap.write(item);
      
      `uvm_info("OUT_MON", $sformatf("Output Audit Complete. Ext Bytes Written: %0d | RTL Calculated Frame: %0d | Ext Rst Toggled: %0b | HW Corrupt Counter: %0d", 
            item.ext_fifo_data.size(), item.valid_eth_frame_val, item.ext_rst_n_toggled, item.corrupt_packet_counter_val), UVM_NONE)      
      
      @(posedge vif.clk);
    end
  endtask
endclass

`endif