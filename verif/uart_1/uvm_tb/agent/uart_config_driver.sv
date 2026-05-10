class uart_config_driver extends uvm_driver #(uart_config_item);
  `uvm_component_utils(uart_config_driver)

  virtual uart_config_intf vif;

  function new(string name = "uart_config_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_config_intf)::get(this, "", "cfg_vif", vif))
      `uvm_fatal("CFG_DRV", "Could not get virtual uart_config_intf")
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.baudrate          = 32'd115200;
    vif.parity_en         = 1'b0;
    vif.parity_odd_even   = 1'b0;
    vif.data_width        = 4'd8;
    vif.config_done_pulse = 1'b0;

    @(posedge vif.rst_n);

    forever begin
      seq_item_port.get_next_item(req);
      drive_config(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_config(uart_config_item item);
    @(posedge vif.clk);
    
    vif.baudrate        <= item.baudrate;
    vif.parity_en       <= item.parity_en;
    vif.parity_odd_even <= item.parity_odd_even;
    vif.data_width      <= item.data_width;
    
    vif.config_done_pulse <= 1'b1;
    
    repeat(5) @(posedge vif.clk);
    
    vif.config_done_pulse <= 1'b0;
    
    `uvm_info("CFG_DRV", $sformatf("Applied New Config -> %s", item.convert2string()), UVM_LOW)
  endtask
endclass