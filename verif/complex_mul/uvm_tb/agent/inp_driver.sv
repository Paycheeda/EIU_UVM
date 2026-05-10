class inp_driver extends uvm_driver #(txn);
  `uvm_component_utils(inp_driver)

  // =====================================================
  // Constructor
  // =====================================================
  function new(string name="inp_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  // =====================================================
  // Handles & Interface
  // =====================================================
  virtual complex_inp_intf  vif     ; // Virtual interface handle
  txn                       tr      ; // Input transaction handle

  // =====================================================
  // Build Phase
  // =====================================================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create transaction object
    tr = txn::type_id::create("tr", this);

    // Get virtual interface from config DB
    if (!uvm_config_db#(virtual complex_inp_intf)::get(this, "", "complex_in_intf", vif)) begin
      `uvm_fatal("INP_DRIVER", "Could not get virtual interface from config DB")
    end
  endfunction : build_phase

  // =====================================================
  // Main Phase
  // =====================================================
  virtual task main_phase(uvm_phase phase);
    `uvm_info("inp_driver", "Starting main phase", UVM_LOW)
    super.main_phase(phase);

    forever begin
      // Get next transaction from sequencer
      seq_item_port.get_next_item(tr);

      // Drive the DUT inputs
      drive_item(tr);

      // Indicate transaction completion
      seq_item_port.item_done();
    end
  endtask : main_phase

  // =====================================================
  // Drive Item Task
  // =====================================================
  virtual task drive_item(inp_transaction drv_tr);
    // Apply input complex numbers (real & imaginary parts)
    vif.valid  <= 1;
    vif.real_a <= drv_tr.real_a;
    vif.imag_a <= drv_tr.imag_a;
    vif.real_b <= drv_tr.real_b;
    vif.imag_b <= drv_tr.imag_b;

    // Wait for 1 clock cycle
    @(posedge vif.clk);

    // Deassert after one cycle
    vif.valid  <= 0;
    vif.real_a <= 0;
    vif.imag_a <= 0;
    vif.real_b <= 0;
    vif.imag_b <= 0;
  endtask : drive_item

endclass : inp_driver
