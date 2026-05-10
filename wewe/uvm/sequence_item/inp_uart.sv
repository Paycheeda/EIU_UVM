class inp_uart extends uvm_sequence_item;

  function new(string name = "inp_uart");
    super.new(name);
  endfunction // new

/*-------------------------------------------------------------------------------
-- Interface, port, fields
-------------------------------------------------------------------------------*/

  rand bit       [8:0]   data_in;           // MUST be data_in
  rand bit          parity_en;
  rand bit          parity_odd_even;
  uart_config          uart_cfg ;


  `uvm_object_utils_begin(inp_cuboid)
    `uvm_field_int(data_in, UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(parity_en,  UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(parity_odd_even, UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_object_utils_end

  // constraint length_c { length inside{[40:60]};}
  // constraint width_c  { width  inside{[07:00]};}
  // constraint height_c { height <= width; }
  // ========================================
  // Create a new inp_cuboid and copy content
  // ========================================
  function inp_uart clone;
    inp_uart p;
    $cast(p, super.clone());
    return p;
  endfunction // clone

  // ==============================================================================================
  // 
  // ==============================================================================================
  virtual function void display_inp_cuboid(string name);
    string msg;
    
    msg = $sformatf("\n This is being displayed  from %s \n", name);
    msg = {msg, $sformatf("================================================================\n")};
    msg = {msg, $sformatf("Length = %h, Width = %h, Height =%h \n", length, width, height)};
    `uvm_info(name, msg, UVM_MEDIUM)
  endfunction // display_pkt

endclass // inp_cuboid

