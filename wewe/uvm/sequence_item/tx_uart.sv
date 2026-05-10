class tx_uart extends uvm_sequence_item;

  function new(string name = "tx_uart");
    super.new(name);
  endfunction // new

/*-------------------------------------------------------------------------------
-- Payload Fields
-------------------------------------------------------------------------------*/

  rand bit [8:0] data_in;         
  rand bit       parity_en;
  rand bit       parity_odd_even; // 0 = Odd, 1 = Even
  bit            expected_parity; // Calculated automatically
  bit            sampled_parity;  // Stored by Output Monitor
  
  // (Optional) Configuration handle if you are using one
  // uart_config uart_cfg; 

  // CRITICAL FIX: The macro now matches the class name exactly
  `uvm_object_utils_begin(tx_uart)
    `uvm_field_int(data_in,         UVM_ALL_ON)
    `uvm_field_int(parity_en,       UVM_ALL_ON)
    `uvm_field_int(parity_odd_even, UVM_ALL_ON)
    `uvm_field_int(expected_parity, UVM_ALL_ON)
    `uvm_field_int(sampled_parity,  UVM_ALL_ON)
  `uvm_object_utils_end
  
  // Automatically calculate expected parity when sequence randomizes it!
  function void post_randomize();
    if (parity_odd_even == 1'b1) 
      expected_parity = ^data_in;    // Even Parity
    else                         
      expected_parity = ~(^data_in); // Odd Parity
  endfunction

  // ========================================
  // Create a new tx_uart packet and copy content
  // ========================================
  function tx_uart clone();
    tx_uart p;
    $cast(p, super.clone());
    return p;
  endfunction // clone

  // ==============================================================================================
  // Display Method
  // ==============================================================================================
  virtual function void display_uart(string name);
    string msg;
    
    msg = $sformatf("\n This is being displayed from %s \n", name);
    msg = {msg, $sformatf("================================================================\n")};
    msg = {msg, $sformatf("Data In         = %0h (Bin: %0b)\n", data_in, data_in)};
    msg = {msg, $sformatf("Parity Enable   = %0b\n", parity_en)};
    msg = {msg, $sformatf("Parity Odd/Even = %0b\n", parity_odd_even)};
    msg = {msg, $sformatf("Expected Parity = %0b\n", expected_parity)};
    `uvm_info(name, msg, UVM_MEDIUM)
  endfunction 

endclass // tx_uart