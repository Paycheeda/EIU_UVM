// ==============================================================================
// THE VIRTUAL SEQUENCE (The Master Conductor)
// ==============================================================================
class coordinated_vseq extends uvm_sequence;
  `uvm_object_utils(coordinated_vseq)

  // Pointers to the physical sequencers in the agents
  uvm_sequencer #(tx_uart) host_tx_sqncr;
  uvm_sequencer #(tx_uart) line_rx_sqncr;
  int num_packets;

  function new (string name = "coordinated_vseq");
    super.new(name);
  endfunction

  virtual task body();
    tx_uart tx_req, rx_req;

    for (int i = 0; i < num_packets; i++) begin
       // 1. Generate ONE random baud rate for both agents to share
       int baud_choice = $urandom_range(0, 4);
       int shared_baud;
       if      (baud_choice == 0) shared_baud = 9600;
       else if (baud_choice == 1) shared_baud = 115200;
       else if (baud_choice == 2) shared_baud = 230400;
       else if (baud_choice == 3) shared_baud = 460800;
       else                       shared_baud = 1843200;

       tx_req = tx_uart::type_id::create("tx_req");
       rx_req = tx_uart::type_id::create("rx_req");

       // 2. Randomize payloads independently
       tx_req.randomize_packet();
       rx_req.randomize_packet();

       // 3. LOCK the configuration so RTL doesn't crash mid-packet
       tx_req.baudrate = shared_baud;
       rx_req.baudrate = shared_baud;

       // Sync the parity and width so the Host doesn't change them on the RX
       rx_req.data_width      = tx_req.data_width;
       rx_req.parity_en       = tx_req.parity_en;
       rx_req.parity_odd_even = tx_req.parity_odd_even;

       tx_req.data_in = tx_req.data_in & ((1 << tx_req.data_width) - 1);
       rx_req.data_in = rx_req.data_in & ((1 << rx_req.data_width) - 1);

       // Recalculate expected parity for RX packet
       if (rx_req.parity_en)
         rx_req.expected_parity = rx_req.parity_odd_even ? ~(^rx_req.data_in) : (^rx_req.data_in);
       else
         rx_req.expected_parity = 0;

       `uvm_info("VSEQ", $sformatf("Firing Packet %0d Concurrent Full-Duplex at %0d BAUD", i+1, shared_baud), UVM_NONE)

       // 4. Send both packets AT THE EXACT SAME TIME
       fork
         begin
           start_item(tx_req, -1, host_tx_sqncr);
           finish_item(tx_req);
         end
         begin
           start_item(rx_req, -1, line_rx_sqncr);
           finish_item(rx_req);
         end
       join

       // Wait for the RTL hardware to completely settle before changing baudrate again
       #50000; 
    end
  endtask
endclass

// ==============================================================================
// THE TEST
// ==============================================================================
class dynamic_duplex_test extends uvm_test;
  `uvm_component_utils(dynamic_duplex_test)

  unified_env  env;
  uart_config  cfg;

  function new(string name = "dynamic_duplex_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = unified_env::type_id::create("env", this);
    cfg = uart_config::type_id::create("cfg");
    
    cfg.num_uart_packets = 10;
    if($value$plusargs("num_uart_packets=%d", cfg.num_uart_packets)) begin end
    
    cfg.watchdog_timer = 50000000; // 50ms is plenty of time if nothing hangs
    uvm_config_db#(uart_config)::set(this, "*", "uart_cfg", cfg);
  endfunction

  virtual task run_phase(uvm_phase phase);
    coordinated_vseq vseq;
    phase.raise_objection(this);

    `uvm_info("TEST", "Hardware Resetting...", UVM_NONE)
    #200; 

    // 1. Create the Virtual Sequence
    vseq = coordinated_vseq::type_id::create("vseq");
    vseq.num_packets = cfg.num_uart_packets;

    // 2. Connect the virtual sequence to the physical sequencers inside your Agents
    vseq.host_tx_sqncr = env.host_tx_agnt.sqncr;
    vseq.line_rx_sqncr = env.line_rx_agnt.sqncr;

    // 3. Launch the master conductor! (runs outside of any specific agent)
    vseq.start(null); 

    phase.drop_objection(this);
  endtask
endclass