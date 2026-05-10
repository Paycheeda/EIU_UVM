class rx_inp_monitor extends uvm_monitor;
  `uvm_component_utils(rx_inp_monitor)

  function new(string name="rx_inp_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  uvm_analysis_port#(rx_uart) mon_analysis_port; 
  virtual uart_rx_in_intf     vif;

  parameter clock_frequency = 32'd44_236_800;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_rx_in_intf)::get(this, "", "uart_rx_in_intf", vif))
      `uvm_fatal("RX_INP_MONITOR", "Could not get vif")
      
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask 

  task collect_data();
    rx_uart pkt; 
    int clock_delay;
    logic [31:0] shift_reg; 
    
    forever begin
      @(negedge vif.data_rx);
      
      pkt = rx_uart::type_id::create("pkt"); 
      
      pkt.baudrate        = vif.baudrate;
      pkt.data_width      = vif.data_width;
      pkt.parity_en       = vif.parity_en;
      pkt.parity_odd_even = vif.parity_odd_even;

      if (pkt.baudrate != 0) clock_delay = clock_frequency / pkt.baudrate;
      else                   clock_delay = clock_frequency / 115200; 

      repeat(clock_delay / 2) @(posedge vif.clk);
      shift_reg = 0; 

      // Sample Data
      for (int i = 0; i < pkt.data_width; i++) begin
        repeat(clock_delay) @(posedge vif.clk);
        shift_reg[i] = vif.data_rx;
      end
      
      pkt.data_in = shift_reg; 

      // Sample Parity
      if (pkt.parity_en) begin
        repeat(clock_delay) @(posedge vif.clk);
        pkt.sampled_parity = vif.data_rx;
      end

      // Move past STOP bit
      repeat(clock_delay) @(posedge vif.clk);
      begin
        string frame_str = "[0]_"; // 1. START Bit
        
        frame_str = {frame_str, "["};
        for (int i = 0; i < pkt.data_width; i++) begin
          frame_str = {frame_str, $sformatf("%b", pkt.data_in[i])}; // 2. DATA Bits
        end
        frame_str = {frame_str, "]"};

        if (pkt.parity_en == 1'b1) begin
          frame_str = {frame_str, "_[", $sformatf("%b", pkt.sampled_parity), "]"}; // 3. PARITY Bit
        end

        frame_str = {frame_str, "_[1]"}; // 4. STOP Bit

        // Print the masterpiece!
        `uvm_info("RX_INP_MONITOR", $sformatf("Rcvd Wire Frame: %s (Width: %0d, Baud: %0d)", 
                  frame_str, pkt.data_width, pkt.baudrate), UVM_LOW)
      end

      mon_analysis_port.write(pkt);
      
      `uvm_info("RX_INP_MONITOR", $sformatf("Sampled RX Wire: Data=%0h, Width=%0d, Baud=%0d", 
                pkt.data_in, pkt.data_width, pkt.baudrate), UVM_LOW)
    end
  endtask
endclass