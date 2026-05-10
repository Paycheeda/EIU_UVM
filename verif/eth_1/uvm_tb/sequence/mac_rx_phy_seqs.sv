`ifndef MAC_RX_PHY_SEQS_SV
`define MAC_RX_PHY_SEQS_SV

class mac_rx_phy_seqs extends uvm_sequence #(mac_rx_phy_seq_item);
  `uvm_object_utils(mac_rx_phy_seqs)

  int num_packets;
  int bad_crc_prob;
  int rx_er_prob;

  function new(string name="mac_rx_phy_seqs"); 
    super.new(name); 
  endfunction

  task pre_body();
    if (!$value$plusargs("num_pkts=%d", num_packets)) num_packets = 5;
    if (!$value$plusargs("bad_crc_prob=%d", bad_crc_prob)) bad_crc_prob = 0;
    if (!$value$plusargs("rx_er_prob=%d", rx_er_prob)) rx_er_prob = 0;
    
    `uvm_info("PHY_SEQ", $sformatf("Config: %0d Packets | Bad CRC Prob: %0d%% | RX_ER Prob: %0d%%", 
              num_packets, bad_crc_prob, rx_er_prob), UVM_NONE)
  endtask

  virtual task body();
    int dice_crc, dice_rxer;

    for (int i = 0; i < num_packets; i++) begin
        req = mac_rx_phy_seq_item::type_id::create("req"); 
        start_item(req);
        
        dice_crc = $urandom_range(1, 100);
        dice_rxer = $urandom_range(1, 100);

        // Packet Randomization
        req.payload_length = $urandom_range(46, 1500);
        
        req.inject_bad_crc     = (dice_crc <= bad_crc_prob) ? 1'b1 : 1'b0;
        req.inject_rx_er_spike = (dice_rxer <= rx_er_prob) ? 1'b1 : 1'b0;
        req.rx_er_spike_location = $urandom_range(8, req.payload_length + 40); 
        req.post_randomize();
        
        finish_item(req); 
        
        `uvm_info("PHY_SEQ", $sformatf("Packet %0d Generated | Payload: %0d | Bad CRC: %0b | RX_ER: %0b (Loc: %0d)", 
                 i+1, req.payload_length, req.inject_bad_crc, req.inject_rx_er_spike, req.rx_er_spike_location), UVM_NONE)

        // ========================================================
        // ---> THE UVM BAND-AID (IPG DELAY) <---
        // This delay ensures the MAC FSM (eth_rx_fifo_IF) finishes 
        // copying data to external memory before the next packet arrives.
        // Without this, back-to-back pulses are missed by the RTL.
        // ========================================================
        #100000ns; 
    end
  endtask
endclass

`endif