class out_cuboid extends uvm_sequence_item;

  function new(string name = "out_cuboid");
    super.new(name);
  endfunction // new

/*-------------------------------------------------------------------------------
-- Interface, port, fields
-------------------------------------------------------------------------------*/

  bit           [32-1:0] area      ;
  bit           [32-1:0] volm      ;
  cuboid_config          cboid_cfg ;


  `uvm_object_utils_begin(out_cuboid)
    `uvm_field_int(area,   UVM_ALL_ON)
    `uvm_field_int(volm,   UVM_ALL_ON)
  `uvm_object_utils_end

  // constraint length_c { length inside{[40:60]};}
  // constraint width_c  { width  inside{[07:00]};}
  // constraint height_c { height <= width; }
  // ========================================
  // Create a new out_cuboid and copy content
  // ========================================
  function out_cuboid clone;
    out_cuboid p;
    $cast(p, super.clone());
    return p;
  endfunction // clone

  // ==============================================================================================
  // 
  // ==============================================================================================
  virtual function void display_out_cuboid(string name);
    string msg;
    
    msg = $sformatf("\n This is being displayed from %s \n", name);
    msg = {msg, $sformatf("================================================================\n")};
    msg = {msg, $sformatf("Area = %h, volm = %h \n", area, volm)};
    `uvm_info(name, msg, UVM_MEDIUM)
  endfunction // display_pkt

endclass // out_cuboid

