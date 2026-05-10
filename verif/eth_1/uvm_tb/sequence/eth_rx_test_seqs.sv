`ifndef ETH_RX_TEST_SEQS_SV
`define ETH_RX_TEST_SEQS_SV

class eth_rx_master_seq extends uvm_sequence #(phy_rx_seq_item);
  `uvm_object_utils(eth_rx_master_seq)
  
  // Command Line Knobs
  int num_packets;
  int fault_prob;
  int en_crc;
  int en_er;
  int en_drop;

  int active_attacks[$]; 

  function new(string name="eth_rx_master_seq"); 
    super.new(name); 
  endfunction

  task pre_body();
    if (!$value$plusargs("num_pkts=%d", num_packets)) num_packets = 10;
    if (!$value$plusargs("fault_prob=%d", fault_prob)) fault_prob = 0; 
    if (!$value$plusargs("en_crc=%d", en_crc)) en_crc = 0;
    if (!$value$plusargs("en_er=%d", en_er)) en_er = 0;
    if (!$value$plusargs("en_drop=%d", en_drop)) en_drop = 0;

    if (en_crc)  active_attacks.push_back(0);
    if (en_er)   active_attacks.push_back(1);
    if (en_drop) active_attacks.push_back(2);

    `uvm_info("SEQ_CFG", $sformatf("Config: %0d Pkts | %0d%% Fault Chance | Pool Size: %0d", 
              num_packets, fault_prob, active_attacks.size()), UVM_NONE)
  endtask

  virtual task body();
    int dice_roll;
    int chosen_attack;

    for (int i = 0; i < num_packets; i++) begin
        req = phy_rx_seq_item::type_id::create("req"); 
        start_item(req);
        
        // ========================================================
        // 1. MANUALLY BUILD THE HEADERS (Bypassing the License)
        // ========================================================
        req.dest_mac    = {8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66};
        req.source_mac  = {8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hFF};
        req.eth_type    = 16'h0800; // IPv4

        req.version     = 4;
        req.ihl         = 5;
        req.tos         = 0;
        req.id          = $urandom();
        req.flags       = 3'b010; // Don't fragment
        req.frag_offset = 0;
        req.ttl         = 64;
        req.protocol    = 8'h11; // UDP
        req.src_ip      = 32'hC0A8010A; // 192.168.1.10
        req.dest_ip     = 32'hC0A80114; // 192.168.1.20

        req.source_port = $urandom_range(1024, 65535);
        req.dest_port   = $urandom_range(1024, 65535);

        req.payload = new[$urandom_range(20, 60)]; 
        foreach(req.payload[j]) req.payload[j] = $urandom();
        
        req.total_length = req.payload.size() + 28; // Total IP length

        // ========================================================
        // 2. SABOTAGE ROUTER
        // ========================================================
        req.inject_crc_error = 0;
        req.inject_rx_er_at_byte = 0;
        req.early_drop_at_byte = 0;

        dice_roll = $urandom_range(1, 100);

        if (dice_roll <= fault_prob && active_attacks.size() > 0) begin
            chosen_attack = active_attacks[$urandom_range(0, active_attacks.size() - 1)];
            
            if (chosen_attack == 0) begin
                req.inject_crc_error = 1;
            end 
            else if (chosen_attack == 1) begin
                req.inject_rx_er_at_byte = $urandom_range(15, 15 + req.payload.size());
            end 
            else if (chosen_attack == 2) begin
                req.early_drop_at_byte = $urandom_range(10, 10 + req.payload.size());
            end

            `uvm_info("SEQ_ROUTER", $sformatf("Packet %0d: FAULT ROLLED! Executing Attack Type %0d", i+1, chosen_attack), UVM_NONE)

        end else begin
            `uvm_info("SEQ_ROUTER", $sformatf("Packet %0d: CLEAN ROLLED.", i+1), UVM_NONE)
        end
        
        finish_item(req);
    end
  endtask
endclass

`endif