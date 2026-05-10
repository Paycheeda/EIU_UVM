
class short_test extends cuboid_base_test;
  `uvm_component_utils(short_test)
  
  // =============================
  // Costructor Method
  // =============================
  function new(string name = "short_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // =============================
  // Build Phase Method
  // ============================= 
  function void build_phase(uvm_phase phase);
     super.build_phase(phase);
    `uvm_info("short_test", "Starting short_test.... ", UVM_MEDIUM)
  endfunction

endclass 

