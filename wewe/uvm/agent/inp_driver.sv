/*class inp_driver extends uvm_driver #(uart_tx);
  `uvm_component_utils(inp_driver)

  // =============================
  // Constructor Method
  // =============================
  function new(string name = "inp_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual uart_tx_intf  vif      ;
  tx_uart               pkt    ;
  // uvm_sequencer #(cuboid)  sqncr    ;     // Sequencer Handle

  // =============================
  // Build Phase Method
  // =============================  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cboid = uart_tx::type_id::create("uart_tx", this);
    // sqncr = uvm_sequencer#(cuboid)::type_id::create("sqncr", this);
    if (!uvm_config_db#(virtual uart_tx_intf)::get(this, "", "uart_tx_intf", vif))
      `uvm_fatal("INP_DRIVER", "Could not get vif")
   endfunction // build_phase

  // =============================
  // Main Phase Method
  // =============================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
 
    forever begin
      seq_item_port.get_next_item(pkt);
      drive_item(pkt);
      seq_item_port.item_done();
    end

  endtask // main_phase

  // =============================
  // Driver Item
  // =============================
  virtual task drive_item(tx_uart drv_pkt); //change this for 8 bit thingy
    vif.data_in  <= 1 ;
    vif.parity_en <= drv_pkt. ;
    vif.parity_odd_even  <= drv_pkt.  ;
    vif.data_start_pulse <= drv_pkt. ;
    vif.rst_n <= drv_pkt. ;
    @(posedge vif.clk);
    vif.data_in  <= 0 ;
    vif.parity_en <= 0 ;
    vif.parity_odd_even  <= 0 ;
    vif.data_start_pulse <= 0 ;  
    vif.rst_n <= 1 ;

  endtask // drive_item  

endclass// inp_driver */

// Make sure the parameter matches your sequence item class name!
class inp_driver extends uvm_driver #(tx_uart);
  `uvm_component_utils(inp_driver)

  // Declare handles for BOTH interfaces
  virtual uart_tx_intf    in_vif;
  virtual uart_out_intf out_vif;

  function new(string name = "inp_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get the Input Interface
    if (!uvm_config_db#(virtual uart_tx_intf)::get(this, "", "uart_tx_intf", in_vif))
      `uvm_fatal("INP_DRIVER", "Could not get input vif")
      
    // Get the Output Interface (Needed for the ready pulse!)
    if (!uvm_config_db#(virtual uart_out_intf)::get(this, "", "uart_out_intf", out_vif))
      `uvm_fatal("INP_DRIVER", "Could not get output vif")
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);

    wait(in_vif.rst_n == 1'b1);

    forever begin
      seq_item_port.get_next_item(req); 
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask 

  virtual task drive_item(tx_uart drv_pkt); 
    @(posedge in_vif.clk);
    
    // Drive inputs using in_vif
    in_vif.data_in          <= drv_pkt.data_in; 
    in_vif.parity_en        <= drv_pkt.parity_en;
    in_vif.parity_odd_even  <= drv_pkt.parity_odd_even;
    in_vif.data_start_pulse <= 1'b1; 
    
    @(posedge in_vif.clk);
    in_vif.data_start_pulse <= 1'b0;  
    
    // Check outputs using out_vif!
    // Wait for the RTL to finish transmitting before exiting
    wait(out_vif.data_ready_pulse == 1'b1);
    
  endtask 

endclass