`ifndef PHY_RX_MONITOR_SV
`define PHY_RX_MONITOR_SV

// We will reuse the fifo_out_seq_item structure to hold the raw bytes 
// for easy comparison in the Scoreboard.
class phy_rx_monitor extends uvm_monitor;
  `uvm_component_utils(phy_rx_monitor)
  virtual eth_rx_if vif; 
  uvm_analysis_port #(fifo_out_seq_item) mon_ap;

  function new(string name="phy_rx_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual eth_rx_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF in PHY Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    fifo_out_seq_item item; 
    bit [7:0] packet_q[$]; 
    int byte_cnt;
    bit saw_rx_er;

    wait(vif.rst_n == 1'b1);

    forever begin
      // Wait for Start of Frame
      wait(vif.rx_dv === 1'b1);
      byte_cnt = 0;
      saw_rx_er = 0;
      packet_q.delete();

      // Capture loop
      while(vif.rx_dv === 1'b1) begin
         @(posedge vif.clk);
         if (vif.rx_dv) begin
             // If rx_er asserts at ANY point during the valid window, flag it!
             if (vif.rx_er) saw_rx_er = 1'b1;

             // Skip the 8-byte preamble (7x 0x55, 1x 0xD5)
             if (byte_cnt >= 8) begin
                 packet_q.push_back(vif.rxd);
             end
             byte_cnt++;
         end
      end

      // End of Frame
      item = fifo_out_seq_item::type_id::create("item");
      item.fifo_data = new[packet_q.size()];
      foreach(packet_q[i]) item.fifo_data[i] = packet_q[i];
      item.is_corrupt = saw_rx_er; // We hijack this flag to tell the SCB if rx_er happened
      
      mon_ap.write(item);
      `uvm_info("PHY_MON", $sformatf("Captured %0d-byte Frame from PHY bus (saw_rx_er=%0b)", packet_q.size(), saw_rx_er), UVM_HIGH)
    end
  endtask
endclass

`endif