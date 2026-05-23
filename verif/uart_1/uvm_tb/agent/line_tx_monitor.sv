class line_tx_monitor extends uvm_monitor;
  `uvm_component_utils(line_tx_monitor)

  uvm_analysis_port#(tx_uart) mon_analysis_port;
  virtual uart_unified_intf   vif;
  
  // ADDED: Handle for the dynamic configuration
  uart_config cfg;
  
  parameter clock_frequency = 32'd55_296_000;

  function new(string name="line_tx_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual uart_unified_intf)::get(this, "", "uart_unified_intf", vif))
            `uvm_fatal("LINE_TX_MONITOR", "Could not get unified vif")
            
        // ---> Verify this is "" and NOT "*" <---
        if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", cfg))
            `uvm_fatal("LINE_TX_MONITOR", "Could not get uart_cfg from DB!")
            
        mon_analysis_port = new ("mon_analysis_port", this);
    endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    collect_data();
  endtask 

  task collect_data();
    tx_uart pkt;
    int clock_delay;
    logic [31:0] shift_reg; 

    // FIXED: Use the dynamic configuration instead of hardcoded values!
    int local_baudrate   = cfg.baudrate;
    int local_data_width = cfg.data_width;
    bit local_parity_en  = cfg.parity_en;
    
    forever begin
      @(negedge vif.tx); // Wait for the Start Bit

      pkt = tx_uart::type_id::create("pkt");

      pkt.baudrate        = local_baudrate;
      pkt.data_width      = local_data_width;
      pkt.parity_en       = local_parity_en;
      pkt.parity_odd_even = cfg.parity_odd_even; // Sync this as well

      if (local_baudrate != 0) clock_delay = clock_frequency / local_baudrate; 
      else clock_delay = clock_frequency / 115200; // Failsafe

      // Wait half a bit period to sample in the middle of the Start Bit
      repeat(clock_delay / 2) @(posedge vif.clk);
      shift_reg = 0;

      // Sample Data Bits
      for (int i = 0; i < local_data_width; i++) begin
        repeat(clock_delay) @(posedge vif.clk);
        shift_reg[i] = vif.tx; 
      end

      pkt.data_in = shift_reg; 
      
      // Sample Parity 
      if (local_parity_en) begin
        repeat(clock_delay) @(posedge vif.clk);
        pkt.sampled_parity = vif.tx;
      end

      // Wait for Stop Bit
      repeat(clock_delay) @(posedge vif.clk);

      mon_analysis_port.write(pkt);

      begin
        string frame_str = "[0]_"; // START Bit
        
        frame_str = {frame_str, "["};
        for (int i = 0; i < local_data_width; i++) begin
          frame_str = {frame_str, $sformatf("%b", pkt.data_in[i])}; // DATA Bits
        end
        frame_str = {frame_str, "]"};

        if (local_parity_en == 1'b1) begin
          frame_str = {frame_str, "_[", $sformatf("%b", pkt.sampled_parity), "]"}; 
        end

        frame_str = {frame_str, "_[1]"}; // STOP Bit

        `uvm_info("LINE_TX_MONITOR", $sformatf("Deserialized Wire Frame: %s (Width: %0d, Baud: %0d)", 
                  frame_str, pkt.data_width, pkt.baudrate), UVM_LOW) // LOW LATER ON
      end
    end
  endtask

endclass