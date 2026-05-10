class uart_tx_sequence extends uvm_sequence #(tx_uart);
  `uvm_object_utils(uart_tx_sequence)

  // This will be set by the Master Sequence
  int num_packets; 

  function new (string name = "uart_tx_sequence");
    super.new(name); 
  endfunction 

  virtual task body();
    `uvm_info("UART_TX_SEQ", $sformatf("Generating %0d UART Packets...", num_packets), UVM_MEDIUM)

    for (int i = 0; i < num_packets; i++) begin
      
      // CRITICAL FIX: Create the new item INSIDE the loop!
      // 'req' is a built-in variable in uvm_sequence, so we use it directly.
      req = tx_uart::type_id::create("req");
      
      start_item(req);
      
      // Randomize the packet using the 'rand' tags in your uart class
      if (!req.randomize()) begin
        `uvm_fatal("UART_TX_SEQ", "UART Packet Randomization Failed");
      end
      
      // (Optional) Print the packet so you can see it in the log
      // req.display_uart("UART_TX_SEQ");
            
      finish_item(req);  
      
    end 
    
    `uvm_info("UART_TX_SEQ", $sformatf("Done generating %0d UART items", num_packets), UVM_LOW)
  endtask

endclass // uart_tx_sequence