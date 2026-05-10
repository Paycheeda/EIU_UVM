class inp_monitor extends uvm_monitor;
  `uvm_component_utils(inp_monitor)

  function new(string name="inp_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  uvm_analysis_port#(tx_uart) mon_analysis_port; 
  virtual uart_tx_intf        vif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_tx_intf)::get(this, "", "uart_tx_intf", vif))
      `uvm_fatal("INP_MONITOR", "Could not get vif")
      
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask 

  task collect_data();
    tx_uart pkt; 
    
    forever begin
      @(posedge vif.clk);
      
      if (vif.data_start_pulse === 1'b1) begin
        
        pkt = tx_uart::type_id::create("pkt"); 
        
        pkt.baudrate        = vif.baudrate;
        pkt.data_width      = vif.data_width;
        pkt.data_in         = vif.data_in;
        pkt.parity_en       = vif.parity_en;
        pkt.parity_odd_even = vif.parity_odd_even;
        
        if (pkt.parity_en) begin
          // odd_even == 1 means EVEN parity
          if (pkt.parity_odd_even == 1'b1)
            pkt.expected_parity = ~(^pkt.data_in);
          else
            pkt.expected_parity = ^pkt.data_in;
        end else begin
            pkt.expected_parity = 1'b0; 
        end

        mon_analysis_port.write(pkt);
        
        begin
          string frame_str = "[0]_"; 
          
          frame_str = {frame_str, "["};
          for (int i = 0; i < pkt.data_width; i++) begin
            frame_str = {frame_str, $sformatf("%b", pkt.data_in[i])}; // DATA Bits (LSB first)
          end
          frame_str = {frame_str, "]"};

          if (pkt.parity_en == 1'b1) begin
            frame_str = {frame_str, "_[", $sformatf("%b", pkt.expected_parity), "]"}; // PARITY
          end

          frame_str = {frame_str, "_[1]"}; //  STOP Bit

          `uvm_info("TX_INP_MONITOR", $sformatf("Sampled Expected Frame: %s (Width: %0d, Baud: %0d)", 
                    frame_str, pkt.data_width, pkt.baudrate), UVM_LOW) 
        end
        
      end
    end
  endtask

endclass