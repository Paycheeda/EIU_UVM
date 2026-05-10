class uart_physical_monitor extends uvm_monitor;
  `uvm_component_utils(uart_physical_monitor)

  virtual serial_line_intf vif;
  virtual uart_config_intf cfg_vif;

  localparam real CLK_FREQ = 44236800.0;

  function new(string name = "uart_physical_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual serial_line_intf)::get(this, "", "serial_vif", vif))
      `uvm_fatal("PHYS_MON", "Could not get virtual serial_line_intf")
      
    if (!uvm_config_db#(virtual uart_config_intf)::get(this, "", "cfg_vif", cfg_vif))
      `uvm_fatal("PHYS_MON", "Could not get virtual uart_config_intf")
  endfunction

  virtual task run_phase(uvm_phase phase);
    int bit_ticks;
    int half_bit_ticks;
    logic [8:0] payload;
    logic rx_parity;
    logic calc_parity;
    string parity_str;
    
    int current_width;
    int current_baud;
    logic [8:0] mask;

    `uvm_info("PHYS_MON", "Physical Wire Snooper is ALIVE! Waiting for Reset...", UVM_LOW)

    @(posedge vif.rst_n);
    
    `uvm_info("PHYS_MON", "Reset dropped. Waiting for IDLE line (High)...", UVM_LOW)

    forever begin
      // 1. Wait for IDLE line (High)
      wait(vif.serial_line === 1'b1);
      
      // 2. Wait for START BIT (Falling Edge)
      @(negedge vif.serial_line);

      // --- FAIL-SAFES: Grab data and prevent Divide-by-Zero at Time 0 ---
      current_width = cfg_vif.data_width;
      current_baud  = cfg_vif.baudrate;
      
      if (current_width == 0 || current_width === 4'hx) current_width = 8;
      if (current_baud == 0 || current_baud === 'x)     current_baud = 115200;

      bit_ticks = int'(CLK_FREQ / current_baud);
      half_bit_ticks = bit_ticks / 2;

      // 3. Wait half a bit period to sample the middle of the start bit
      repeat(half_bit_ticks) @(posedge vif.clk);
      if (vif.serial_line !== 1'b0) continue; // False start glitch, ignore

      // 4. Sample DATA BITS
      payload = 0;
      for (int i = 0; i < current_width; i++) begin
        repeat(bit_ticks) @(posedge vif.clk);
        payload[i] = vif.serial_line;
      end

      // 5. Sample PARITY BIT (if enabled)
      if (cfg_vif.parity_en) begin
        repeat(bit_ticks) @(posedge vif.clk);
        rx_parity = vif.serial_line;
        
        mask = (1 << current_width) - 1;
        calc_parity = cfg_vif.parity_odd_even ? ~(^(payload & mask)) : 
                                                 ^(payload & mask);
                                                 
        parity_str = (rx_parity == calc_parity) ? 
                     $sformatf("RX: %0b (Calc: %0b) -> MATCH", rx_parity, calc_parity) : 
                     $sformatf("RX: %0b (Calc: %0b) -> ERROR!", rx_parity, calc_parity);
      end else begin
        parity_str = "DISABLED";
      end

      // 6. Sample STOP BIT
      repeat(bit_ticks) @(posedge vif.clk);

      // 7. PRINT THE REPORT
      `uvm_info("PHYSICAL_LINE", "\n------------------------------------------------------", UVM_NONE)
      `uvm_info("PHYSICAL_LINE", "📡 SERIAL LINE PACKET DETECTED!", UVM_NONE)
      `uvm_info("PHYSICAL_LINE", $sformatf(" ► Payload   : 0x%0h (%0d-bit)", payload, current_width), UVM_NONE)
      `uvm_info("PHYSICAL_LINE", $sformatf(" ► Baudrate  : %0d bps", current_baud), UVM_NONE)
      if (cfg_vif.parity_en)
        `uvm_info("PHYSICAL_LINE", $sformatf(" ► Parity Cfg: ENABLED (%s)", cfg_vif.parity_odd_even ? "ODD" : "EVEN"), UVM_NONE)
      else
        `uvm_info("PHYSICAL_LINE", " ► Parity Cfg: DISABLED", UVM_NONE)
      `uvm_info("PHYSICAL_LINE", $sformatf(" ► Parity Chk: %s", parity_str), UVM_NONE)
      `uvm_info("PHYSICAL_LINE", "------------------------------------------------------\n", UVM_NONE)
    end
  endtask
endclass