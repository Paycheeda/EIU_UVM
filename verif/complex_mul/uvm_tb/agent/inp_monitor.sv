class inp_monitor extends uvm_monitor;
  `uvm_component_utils(inp_monitor)

  // =====================================================
  // Constructor
  // =====================================================
  function new(string name="inp_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  // =====================================================
  // Handles & Ports
  // =====================================================
  uvm_analysis_port#(inp_transaction) mon_analysis_port; // Analysis port to send observed transactions
  virtual complex_inp_intf vif;                          // Virtual interface handle
  txn                      tr;                           // Transaction handle

  // =====================================================
  // Build Phase
  // =====================================================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get virtual interface from config DB
    if (!uvm_config_db#(virtual complex_inp_intf)::get(this, "", "complex_in_intf", vif)) begin
      `uvm_fatal("INP_MONITOR", "Could not get vif from config DB")
    end

    // Create analysis port
    mon_analysis_port = new("mon_analysis_port", this);
  endfunction : build_phase

  // =====================================================
  // Main Phase
  // =====================================================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();   // Start collecting transactions
  endtask : main_phase

  // =====================================================
  // Collecting Data Task
  // =====================================================
  task collect_data;
    forever begin
      @(posedge vif.clk);

      // Capture inputs when valid is asserted
      if (vif.valid) begin
        // Create new transaction object
        tr = inp_transaction::type_id::create("mon_tr", this);

        // Sample DUT input signals into transaction fields
        tr.real_a = vif.real_a;
        tr.imag_a = vif.imag_a;
        tr.real_b = vif.real_b;
        tr.imag_b = vif.imag_b;

        mon_analysis_port.write(tr);

        // Optional: Display for debug
        tr.display("INPUT_MONITOR");
      end
    end
  endtask : collect_data

endclass : inp_monitor
