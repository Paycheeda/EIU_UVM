class line_rx_driver extends uvm_driver #(tx_uart);
  `uvm_component_utils(line_rx_driver)

  virtual uart_unified_intf vif;
  
  parameter clock_frequency = 32'd44_236_800;

  function new(string name = "line_rx_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_unified_intf)::get(this, "", "uart_unified_intf", vif))
      `uvm_fatal("LINE_RX_DRIVER", "Could not get unified vif")
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);

    vif.rx <= 1'b1;

    wait(vif.rst_n == 1'b1);

    forever begin
      seq_item_port.get_next_item(req); 
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask 

  virtual task drive_item(tx_uart drv_pkt); 
    int clock_delay;

    if (drv_pkt.baudrate != 0) clock_delay = clock_frequency / drv_pkt.baudrate;
    else                       clock_delay = clock_frequency / 115200; 

    repeat(20) @(posedge vif.clk);

    if (drv_pkt.baudrate != 0) clock_delay = clock_frequency / drv_pkt.baudrate;
    else                       clock_delay = clock_frequency / 115200;

    // ========================================================
    // 1. START BIT
    // ========================================================
    vif.rx <= 1'b0; 
    repeat(clock_delay) @(posedge vif.clk);

    // ========================================================
    // 2. DATA BITS (LSB First)
    // ========================================================
    for (int i = 0; i < drv_pkt.data_width; i++) begin
      vif.rx <= drv_pkt.data_in[i];
      repeat(clock_delay) @(posedge vif.clk);
    end

    // ========================================================
    // 3. PARITY BIT (If enabled)
    // ========================================================
    if (drv_pkt.parity_en) begin
      vif.rx <= drv_pkt.expected_parity; // Drive the correctly calculated parity
      repeat(clock_delay) @(posedge vif.clk);
    end

    // ========================================================
    // 4. STOP BIT & PACKET GAP
    // ========================================================
    vif.rx <= 1'b1; 
    
    repeat(clock_delay * 2) @(posedge vif.clk);
    
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

      `uvm_info("LINE_RX_DRIVER", $sformatf("Injected onto Wire: Width=%0d, Baud=%0d | Wire Frame: %s", 
                drv_pkt.data_width, drv_pkt.baudrate, frame_str), UVM_HIGH)
    end
    
  endtask 

endclass