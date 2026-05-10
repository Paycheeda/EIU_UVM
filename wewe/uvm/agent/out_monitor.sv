/*class out_monitor extends uvm_monitor;
  `uvm_component_utils(out_monitor)

  // =============================
  // Constructor Method
  // =============================
  function new(string name="out_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction // new

  uvm_analysis_port#(out_uartx) mon_analysis_port;
  virtual uart_out_intf    vif   ;
  
  out_uartx    pkt      ;
  
  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_tx_intf)::get(this, "", "uart_tx_intf", vif))
      `uvm_fatal("OUT_MONITOR", "Could not get vif")
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction // build_phase


  // =============================
  // Main Phase Method
  // =============================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    fork
      collect_data();
    join_none
    
  endtask // main_phase

  // =============================
  // Collecting data
  // =============================
  task collect_data ;
    forever begin
      //======================================================//
      // collecting out_cuboid at valid                           //
      //======================================================//
      if (vif.valid) begin
        pkt       = out_uart::type_id::create("Output Monitor Pkt");
      if (vif.data_ready_pulse === 1'b1) begin
        
        // 1. Create a new sequence item
        pkt = tx_uart::type_id::create("pkt"); 
        
        // 2. Sample the interface signals at this exact clock edge
        pkt.data_tx         = vif.data_tx;
        // 3. Send it out the analysis port to the Scoreboard/Coverage
        pkt.display_out_uart("OUTPUT_MONITOR");      
        mon_analysis_port.write(pkt);
      end
      @(posedge vif.clk);
    end
  endtask

endclass */

class out_monitor extends uvm_monitor;
  `uvm_component_utils(out_monitor)

  uvm_analysis_port#(tx_uart) mon_analysis_port;
  virtual uart_out_intf       vif;
  
  parameter clock_frequency = 32'd50_000_000;
  parameter PARAM_BAUD_RATE = 32'd115200;
  parameter clock_delay_param = (clock_frequency/PARAM_BAUD_RATE);

  function new(string name="out_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(virtual uart_out_intf)::get(this, "", "uart_out_intf", vif))
      `uvm_fatal("OUT_MONITOR", "Could not get out vif")
      
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask 

  task collect_data();
    tx_uart pkt;
    integer clock_counter;
    integer bit_counter;
    logic [8:0] shift_reg;

    forever begin
      // 1. Wait for the START bit (data_tx dropping to 0)
      wait(vif.data_tx === 1'b0);

      // 2. Wait half a baud period to align our sampling to the MIDDLE of the bit
      for (clock_counter = 0; clock_counter < (clock_delay_param/2); clock_counter++) begin
        @(posedge vif.clk);
      end

      // 3. Loop through and sample the 9 Data Bits
      for (bit_counter = 0; bit_counter < 9; bit_counter++) begin
        for (clock_counter = 0; clock_counter < clock_delay_param; clock_counter++) begin
          @(posedge vif.clk);
        end
        shift_reg[bit_counter] = vif.data_tx;
      end

      // 4. Create the sequence item
      pkt = tx_uart::type_id::create("pkt");
      pkt.data_in = shift_reg; 
      
      // Pass the interface config to the packet so the Scoreboard knows what to check
      pkt.parity_en = vif.parity_en;
      pkt.parity_odd_even = vif.parity_odd_even;

      // CRITICAL FIX: Sample the Parity Bit if enabled!
      if (vif.parity_en === 1'b1) begin
        // Wait a full baud period to get to the middle of the parity bit
        for (clock_counter = 0; clock_counter < clock_delay_param; clock_counter++) begin
          @(posedge vif.clk);
        end
        // Sample it!
        pkt.sampled_parity = vif.data_tx;
      end

      // 5. Send it to the Scoreboard!
      mon_analysis_port.write(pkt);
      `uvm_info("OUT_MONITOR", $sformatf("Deserialized TX Data: %0h", pkt.data_in), UVM_LOW)

      // 6. Wait for the RTL to finish its state machine before hunting for the next start bit
      wait(vif.data_ready_pulse === 1'b1);
      @(posedge vif.clk);
    end
  endtask

endclass
