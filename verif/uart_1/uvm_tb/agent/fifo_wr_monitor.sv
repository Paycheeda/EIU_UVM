class fifo_wr_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_wr_monitor)

  virtual fifo_intf_uart vif;
  uvm_analysis_port #(fifo_item) mon_ap;
  fifo_config cfg;

  function new(string name="fifo_wr_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_intf_uart)::get(this, "", "fifo_vif", vif))
      `uvm_fatal("FIFO_WR_MON", "Could not get virtual interface")
      
    if (!uvm_config_db#(fifo_config)::get(this, "", "fifo_cfg", cfg))
      `uvm_fatal("FIFO_WR_MON", "Could not get fifo_config")
      
    mon_ap = new("mon_ap", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    fifo_item item; 
    bit prev_full = 0; 
    
    fork
      // Transaction Capture 
      forever begin
        @(posedge vif.wr_clk);
        
        if (vif.wr_en === 1'b1) begin
            item = fifo_item::type_id::create("item");
            item.data = vif.data_in;
            
            mon_ap.write(item);
            
            `uvm_info("FIFO_WR_MON", $sformatf("Sampled Write: 0x%0h", item.data), UVM_LOW)
        end
      end

      // Synchronous FULL Edge Detector (For Debugging)
      forever begin
        @(posedge vif.wr_clk); 
        if (vif.fifo_full !== prev_full) begin
          if (vif.fifo_full === 1'b1)
            `uvm_info("FIFO_WR_MON", "[FLAG] FIFO FULL SIGNAL ASSERTED", UVM_LOW)
          else
            `uvm_info("FIFO_WR_MON", "[FLAG] FIFO FULL SIGNAL DE-ASSERTED", UVM_LOW)
          
          prev_full = vif.fifo_full;
        end
      end
    join 
  endtask
endclass