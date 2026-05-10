class uart_config_monitor extends uvm_monitor;
  `uvm_component_utils(uart_config_monitor)

  virtual uart_config_intf vif;
  uvm_analysis_port #(uart_config_item) mon_ap;

  function new(string name = "uart_config_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_config_intf)::get(this, "", "cfg_vif", vif))
      `uvm_fatal("CFG_MON", "Could not get virtual uart_config_intf")
      
    mon_ap = new("mon_ap", this);
  endfunction

virtual task run_phase(uvm_phase phase);
    uart_config_item item;
    bit prev_pulse = 0; 

    forever begin
      @(posedge vif.clk);
      
      if (vif.config_done_pulse === 1'b1 && prev_pulse === 1'b0) begin
        item = uart_config_item::type_id::create("item");
        
        item.baudrate        = vif.baudrate;
        item.parity_en       = vif.parity_en;
        item.parity_odd_even = vif.parity_odd_even;
        item.data_width      = vif.data_width;
        
        mon_ap.write(item);
        `uvm_info("CFG_MON", $sformatf("Detected Config Change: %s", item.convert2string()), UVM_HIGH)
      end
      
      prev_pulse = vif.config_done_pulse;
    end
  endtask
endclass