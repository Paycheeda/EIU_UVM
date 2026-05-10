/*class inp_monitor extends uvm_monitor;
  `uvm_component_utils(inp_monitor)

  // =============================
  // Constructor Method
  // =============================
  function new(string name="inp_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction // new

  uvm_analysis_port#(inp_uart) mon_analysis_port;
  virtual uart_tx_intf vif   ;
  
  tx_uart                  pkt ;
  
  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_tx_intf)::get(this, "", "uart_tx_intf", vif))
      `uvm_fatal("INP_MONITOR", "Could not get vif")
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction // build_phase

  // =============================
  // Main Phase Method
  // =============================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask // main_phase

  // =============================
  // Collecting data
  // =============================
  task collect_data ;
    forever begin
      //======================================================//
      // collecting inp_cuboid at valid                           //
      //======================================================//
      if (vif.valid) begin
        uart        = inp_uart::type_id::create("INP Monitor Pkt"); // change this for uart tx
        uart.data_in = in_vif.data_in;
        uart.parity_en  = in_vif.parity_en ;
        cboid.parity_odd_even = in_vif.parity_odd_even;
        uart.data_start_pulse = in_vif.data_start_pulse;
        mon_analysis_port.write(uart);
        cboid.display_inp_cuboid("INPUT_MONITOR");       
      end
      @(posedge vif.clk);
    end
  endtask

endclass */

class inp_monitor extends uvm_monitor;
  `uvm_component_utils(inp_monitor)

  // =============================
  // Constructor Method
  // =============================
  function new(string name="inp_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  // Standardize on tx_uart to match your driver and agent
  uvm_analysis_port#(tx_uart) mon_analysis_port; 
  virtual uart_tx_intf        vif;
  
  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_tx_intf)::get(this, "", "uart_tx_intf", vif))
      `uvm_fatal("INP_MONITOR", "Could not get vif")
      
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction 

  // =============================
  // Main Phase Method
  // =============================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask 

  // =============================
  // Collecting data
  // =============================
  task collect_data();
    tx_uart pkt; // Local handle for the transaction
    
    forever begin
      @(posedge vif.clk);
      
      // We know a new packet is being sent when data_start_pulse goes HIGH
      if (vif.data_start_pulse === 1'b1) begin
        
        // 1. Create a new sequence item
        pkt = tx_uart::type_id::create("pkt"); 
        
        // 2. Sample the interface signals at this exact clock edge
        pkt.data_in         = vif.data_in;
        pkt.parity_en       = vif.parity_en;
        pkt.parity_odd_even = vif.parity_odd_even;
        
        // 3. Send it out the analysis port to the Scoreboard/Coverage
        mon_analysis_port.write(pkt);
        
        // Optional: Print a nice debug message so you can see it in the log
        `uvm_info("INP_MONITOR", $sformatf("Sampled TX Inputs: Data=%0h, Parity_En=%0b", pkt.data_in, pkt.parity_en), UVM_LOW)
        
      end
    end
  endtask

endclass
