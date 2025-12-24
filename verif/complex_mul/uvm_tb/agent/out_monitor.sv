class out_monitor extends uvm_monitor;
  `uvm_component_utils(out_monitor)

  // =====================================================
  // Constructor
  // =====================================================
  function new(string name="out_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  // =====================================================
  // Handles
  // =====================================================
  uvm_analysis_port#(out_transaction) mon_analysis_port;  
  virtual complex_out_intf vif;   // DUT output interface

  out_transaction trx;  // transaction for sampled outputs

  // =====================================================
  // Build Phase
  // =====================================================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get virtual interface
    if (!uvm_config_db#(virtual complex_out_intf)::get(this, "", "complex_out_vif", vif))
      `uvm_fatal("OUT_MONITOR", "Could not get complex_out_intf")

    // Create analysis port
    mon_analysis_port = new("mon_analysis_port", this);
  endfunction : build_phase

  // =====================================================
  // Main Phase
  // =====================================================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);

    fork
      collect_data();
    join_none
  endtask : main_phase

  // =====================================================
  // Collect Data
  // =====================================================
  task collect_data;
    forever begin
      // Wait until DUT drives valid outputs
      if (vif.valid) begin
        // Create new transaction
        trx = out_transaction::type_id::create("out_trx", this);

        // Sample DUT outputs
        trx.y = vif.y;   // multiplication real
        trx.z = vif.z;   // multiplication imag
        trx.w = vif.w;   // addition real
        trx.x = vif.x;   // addition imag

        // Optional debug display
        trx.display("OUTPUT_MONITOR");

        // Send sampled transaction to scoreboard via analysis port
        mon_analysis_port.write(trx);
      end
      @(posedge vif.clk);
    end
  endtask : collect_data

endclass : out_monitor
