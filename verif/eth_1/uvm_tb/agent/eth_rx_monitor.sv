`ifndef ETH_RX_MONITOR_SV
`define ETH_RX_MONITOR_SV

class eth_rx_monitor extends uvm_monitor;
  `uvm_component_utils(eth_rx_monitor)
  virtual eth_if vif; 
  uvm_analysis_port #(eth_rx_seq_item) mon_ap;

  function new(string n="eth_rx_monitor", uvm_component p=null); 
    super.new(n, p); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual eth_if)::get(this, "", "vif", vif)) `uvm_fatal("NO_VIF", "No VIF")
  endfunction

  virtual task run_phase(uvm_phase phase);
    eth_rx_seq_item item; 
    bit [7:0] packet_q[$]; 
    bit [3:0] lower_nibble, upper_nibble;
    int byte_count = 0;

    wait(vif.rst_n == 1'b1);

    forever begin
      @(posedge vif.tx_c); 

      if (vif.tx_ctl === 1'b1) begin
        
        if (byte_count == 0) begin
            `uvm_info("PHY_MON", "\n>>> [tx_ctl HIGH] START OF FRAME DETECTED ON PHY BUS <<<", UVM_NONE)
        end

        
        lower_nibble = vif.txd;
        
        @(negedge vif.tx_c);
        upper_nibble = vif.txd;
        
        packet_q.push_back({upper_nibble, lower_nibble});

        `uvm_info("PHY_TRACE", $sformatf("Byte %03d | tx_c Posedge txd: 4'h%0h | tx_c Negedge txd: 4'h%0h | Reconstructed: 8'h%02h", 
                                        byte_count, lower_nibble, upper_nibble, {upper_nibble, lower_nibble}), UVM_NONE)
        
        byte_count++;
      end 
      else if (packet_q.size() > 0) begin
        `uvm_info("PHY_MON", "<<< [tx_ctl LOW] END OF FRAME DETECTED ON PHY BUS >>>\n", UVM_NONE)

        item = eth_rx_seq_item::type_id::create("item");
        item.packet_data = new[packet_q.size()];
        foreach(packet_q[i]) item.packet_data[i] = packet_q[i];
        
        mon_ap.write(item);
        `uvm_info("RX_MON", $sformatf("Forwarded %0d-byte Frame to Scoreboard!", packet_q.size()), UVM_NONE)
        
        packet_q.delete(); 
        byte_count = 0;
      end
    end
  endtask
endclass

`endif