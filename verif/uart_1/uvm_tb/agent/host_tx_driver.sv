class host_tx_driver extends uvm_driver #(tx_uart);
  `uvm_component_utils(host_tx_driver)

  virtual uart_unified_intf vif;

  function new(string name = "host_tx_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_unified_intf)::get(this, "", "uart_unified_intf", vif))
      `uvm_fatal("HOST_TX_DRIVER", "Could not get unified vif")
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);

    vif.send_data_tx    <= 1'b0;
    vif.baudrate        <= 32'd115200;
    vif.data_width      <= 4'd8;
    vif.parity_en       <= 1'b0;
    vif.parity_odd_even <= 1'b0;
    vif.data_in_TX      <= 0;

    wait(vif.rst_n == 1'b1);

    forever begin
      seq_item_port.get_next_item(req); 
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask 

  virtual task drive_item(tx_uart drv_pkt); 
    
    // ========================================================
    // CPU Write
    // ========================================================
    @(posedge vif.clk);
    vif.baudrate        <= drv_pkt.baudrate;
    vif.data_width      <= drv_pkt.data_width;
    vif.parity_en       <= drv_pkt.parity_en;
    vif.parity_odd_even <= drv_pkt.parity_odd_even;
    vif.data_in_TX      <= drv_pkt.data_in; 

    repeat(20) @(posedge vif.clk);
    
    // ========================================================
    // COMMAND PULSE
    // ========================================================
    vif.send_data_tx <= 1'b1; 
    
    @(posedge vif.clk);
    vif.send_data_tx <= 1'b0;  
    
    // ========================================================
    // WAIT FOR HARDWARE TO COMPLETE
    // ========================================================
    wait(vif.uart_tx_busy == 1'b1);
    
    wait(vif.uart_tx_busy == 1'b0);

    repeat(50) @(posedge vif.clk);
    
    begin
      string frame_str = "[0]_"; 
      frame_str = {frame_str, "["};
      for (int i = 0; i < drv_pkt.data_width; i++) begin
        frame_str = {frame_str, $sformatf("%b", drv_pkt.data_in[i])}; 
      end
      frame_str = {frame_str, "]"};

      if (drv_pkt.parity_en == 1'b1) begin
        frame_str = {frame_str, "_[", $sformatf("%b", drv_pkt.expected_parity), "]"}; 
      end
      frame_str = {frame_str, "_[1]"}; 

      `uvm_info("HOST_TX_DRIVER", $sformatf("Injected via CPU Bus: Width=%0d, Baud=%0d | Expected Wire Frame: %s", 
                drv_pkt.data_width, drv_pkt.baudrate, frame_str), UVM_HIGH)
    end
    
  endtask 

endclass