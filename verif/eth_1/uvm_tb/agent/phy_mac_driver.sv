`ifndef PHY_MAC_DRIVER_SV
`define PHY_MAC_DRIVER_SV

class phy_mac_driver extends uvm_driver #(mac_rx_phy_seq_item);
  `uvm_component_utils(phy_mac_driver)
  virtual mac_rx_if vif; 

  function new(string name="phy_mac_driver", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual mac_rx_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No Virtual Interface in PHY Driver")
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.rxd_parallel    = 8'b0;
    vif.rx_ctl_parallel = 1'b0;
    vif.rx_er_parallel  = 1'b0;
    
    wait(vif.rst_n == 1'b1);
    
    forever begin
      seq_item_port.get_next_item(req);
      repeat(20) @(posedge vif.clk);

      `uvm_info("PHY_DRV", $sformatf("Starting Parallel Transmission of %0d bytes...", req.raw_frame.size()), UVM_HIGH)

      for (int i = 0; i < req.raw_frame.size(); i++) begin
          @(posedge vif.clk); 
          vif.rxd_parallel    = req.raw_frame[i];
          vif.rx_ctl_parallel = 1'b1;
          vif.rx_er_parallel  = (req.inject_rx_er_spike && (i == req.rx_er_spike_location)) ? 1'b1 : 1'b0;
      end
      
      @(posedge vif.clk);
      vif.rxd_parallel    = 8'b0;
      vif.rx_ctl_parallel = 1'b0;
      vif.rx_er_parallel  = 1'b0;

      `uvm_info("PHY_DRV", "Transmission Complete. Going back to IDLE.", UVM_HIGH)
      seq_item_port.item_done();
    end
  endtask
endclass

`endif