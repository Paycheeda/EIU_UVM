`ifndef ETH_TX_BASE_SEQUENCE_SV
`define ETH_TX_BASE_SEQUENCE_SV

class eth_tx_base_sequence extends uvm_sequence #(eth_tx_seq_item);
  `uvm_object_utils(eth_tx_base_sequence)
  
  int num_packets;
  int user_payload_size;

  function new(string name = "eth_tx_base_sequence"); 
    super.new(name); 
  endfunction

  virtual task body();
    // Default to 10 packets if not specified
    if (!$value$plusargs("num_pkts=%d", num_packets)) begin
      num_packets = 10; 
    end
    
    `uvm_info("SEQ", $sformatf("Generating %0d Dynamic UDP Packets", num_packets), UVM_NONE)
    
    for (int i = 0; i < num_packets; i++) begin
      req = eth_tx_seq_item::type_id::create("req");
      start_item(req);
      
      // --- DYNAMIC PAYLOAD SIZING ---
      if ($value$plusargs("payload_size=%d", user_payload_size)) begin
        req.payload = new[user_payload_size];
      end else begin
        req.payload = new[$urandom_range(10, 1472)];
      end
      
      foreach(req.payload[j]) req.payload[j] = $urandom();

      // Ethernet Setup
      req.dest_mac   = {$urandom(), $urandom()}; 
      req.source_mac = {$urandom(), $urandom()}; 
      req.eth_type   = 16'h0800; // IPv4
      
      // IPv4 Setup
      req.version     = 4'd4; 
      req.ihl         = 4'd5; 
      req.tos         = 8'd0; 
      req.id          = 16'h0000; //$urandom(); 
      req.flags       = 3'b010; // Don't Fragment
      req.frag_offset = 13'd0; 
      req.ttl         = 8'd64; 
      req.protocol    = 8'd17;  // UDP
      req.src_ip      = $urandom(); 
      req.dest_ip     = $urandom();
      
      // UDP Setup
      req.source_port = $urandom(); 
      req.dest_port   = $urandom();

      // Dynamic Math Calculation
      req.total_length = req.payload.size() + 8 + 20; // Payload + UDP Header + IPv4 Header
      
      finish_item(req);
    end
  endtask
endclass

`endif