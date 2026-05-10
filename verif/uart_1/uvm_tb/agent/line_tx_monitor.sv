class line_tx_monitor extends uvm_monitor;
  `uvm_component_utils(line_tx_monitor)

  uvm_analysis_port#(tx_uart) mon_analysis_port;
  virtual uart_unified_intf   vif;
  
  parameter clock_frequency = 32'd44_236_800;

  function new(string name="line_tx_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(virtual uart_unified_intf)::get(this, "", "uart_unified_intf", vif))
      `uvm_fatal("LINE_TX_MONITOR", "Could not get unified vif")
      
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask 

  task collect_data();
    tx_uart pkt;
    int clock_delay;
    logic [31:0] shift_reg; 

    forever begin
      @(negedge vif.tx);

      pkt = tx_uart::type_id::create("pkt");

      pkt.baudrate        = vif.baudrate;
      pkt.data_width      = vif.data_width;
      pkt.parity_en       = vif.parity_en;
      pkt.parity_odd_even = vif.parity_odd_even;

      if (pkt.baudrate != 0) clock_delay = clock_frequency / pkt.baudrate;
      else                   clock_delay = clock_frequency / 115200; 

      repeat(clock_delay / 2) @(posedge vif.clk);
      shift_reg = 0;

      for (int i = 0; i < pkt.data_width; i++) begin
        repeat(clock_delay) @(posedge vif.clk);
        shift_reg[i] = vif.tx; // Sample LSB first
      end

      pkt.data_in = shift_reg; 
      
      if (pkt.parity_en) begin
        repeat(clock_delay) @(posedge vif.clk);
        pkt.sampled_parity = vif.tx;
      end

      repeat(clock_delay) @(posedge vif.clk);

      mon_analysis_port.write(pkt);

      begin
        string frame_str = "[0]_"; // START Bit
        
        frame_str = {frame_str, "["};
        for (int i = 0; i < pkt.data_width; i++) begin
          frame_str = {frame_str, $sformatf("%b", pkt.data_in[i])}; // DATA Bits
        end
        frame_str = {frame_str, "]"};

        if (pkt.parity_en == 1'b1) begin
          frame_str = {frame_str, "_[", $sformatf("%b", pkt.sampled_parity), "]"}; // PARITY Bit
        end

        frame_str = {frame_str, "_[1]"}; // STOP Bit

        `uvm_info("LINE_TX_MONITOR", $sformatf("Deserialized Wire Frame: %s (Width: %0d, Baud: %0d)", 
                  frame_str, pkt.data_width, pkt.baudrate), UVM_LOW)
      end
    end
  endtask

endclass