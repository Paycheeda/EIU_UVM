`ifndef ETH_SCOREBOARD_SV
`define ETH_SCOREBOARD_SV

class eth_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(eth_scoreboard)
  uvm_tlm_analysis_fifo #(eth_tx_seq_item) tx_fifo; uvm_tlm_analysis_fifo #(eth_rx_seq_item) rx_fifo;
  uvm_analysis_export #(eth_tx_seq_item) tx_export; uvm_analysis_export #(eth_rx_seq_item) rx_export;
  localparam bit [63:0] PREAMBLE = 64'h55_55_55_55_55_55_55_d5;
  int pkts_checked = 0; int pkts_passed = 0; int pkts_failed = 0;

  function new(string name="eth_scoreboard", uvm_component parent=null); super.new(name, parent); endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); tx_fifo = new("tx_fifo", this); rx_fifo = new("rx_fifo", this);
    tx_export = new("tx_export", this); rx_export = new("rx_export", this);
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase); tx_export.connect(tx_fifo.analysis_export); rx_export.connect(rx_fifo.analysis_export);
  endfunction

  virtual task run_phase(uvm_phase phase);
    eth_tx_seq_item tx_req; eth_rx_seq_item rx_req;
    bit [7:0] expected_packet[$]; bit [7:0] crc_data_q[$]; 
    bit [31:0] expected_crc; bit [15:0] exp_ip_chk; bit [15:0] exp_udp_chk; bit match; string exp_str, act_str;

    forever begin
      tx_fifo.get(tx_req); rx_fifo.get(rx_req);

      expected_packet.delete(); crc_data_q.delete(); 
      exp_ip_chk = calc_ipv4_checksum(tx_req); exp_udp_chk = calc_udp_checksum(tx_req);

      for (int i = 7; i >= 0; i--) expected_packet.push_back(PREAMBLE[i*8 +: 8]);
      for (int i = 5; i >= 0; i--) begin expected_packet.push_back(tx_req.dest_mac[i*8 +: 8]); crc_data_q.push_back(tx_req.dest_mac[i*8 +: 8]); end
      for (int i = 5; i >= 0; i--) begin expected_packet.push_back(tx_req.source_mac[i*8 +: 8]); crc_data_q.push_back(tx_req.source_mac[i*8 +: 8]); end
      for (int i = 1; i >= 0; i--) begin expected_packet.push_back(tx_req.eth_type[i*8 +: 8]); crc_data_q.push_back(tx_req.eth_type[i*8 +: 8]); end

      expected_packet.push_back({tx_req.version, tx_req.ihl}); crc_data_q.push_back({tx_req.version, tx_req.ihl});
      expected_packet.push_back(tx_req.tos); crc_data_q.push_back(tx_req.tos);
      expected_packet.push_back(tx_req.total_length[15:8]); crc_data_q.push_back(tx_req.total_length[15:8]);
      expected_packet.push_back(tx_req.total_length[7:0]); crc_data_q.push_back(tx_req.total_length[7:0]);
      expected_packet.push_back(tx_req.id[15:8]); crc_data_q.push_back(tx_req.id[15:8]);
      expected_packet.push_back(tx_req.id[7:0]); crc_data_q.push_back(tx_req.id[7:0]);
      expected_packet.push_back({tx_req.flags, tx_req.frag_offset[12:8]}); crc_data_q.push_back({tx_req.flags, tx_req.frag_offset[12:8]});
      expected_packet.push_back(tx_req.frag_offset[7:0]); crc_data_q.push_back(tx_req.frag_offset[7:0]);
      expected_packet.push_back(tx_req.ttl); crc_data_q.push_back(tx_req.ttl);
      expected_packet.push_back(tx_req.protocol); crc_data_q.push_back(tx_req.protocol);
      expected_packet.push_back(exp_ip_chk[15:8]); crc_data_q.push_back(exp_ip_chk[15:8]);
      expected_packet.push_back(exp_ip_chk[7:0]); crc_data_q.push_back(exp_ip_chk[7:0]);
      for (int i = 3; i >= 0; i--) begin expected_packet.push_back(tx_req.src_ip[i*8 +: 8]); crc_data_q.push_back(tx_req.src_ip[i*8 +: 8]); end
      for (int i = 3; i >= 0; i--) begin expected_packet.push_back(tx_req.dest_ip[i*8 +: 8]); crc_data_q.push_back(tx_req.dest_ip[i*8 +: 8]); end

      expected_packet.push_back(tx_req.source_port[15:8]); crc_data_q.push_back(tx_req.source_port[15:8]);
      expected_packet.push_back(tx_req.source_port[7:0]);  crc_data_q.push_back(tx_req.source_port[7:0]);
      expected_packet.push_back(tx_req.dest_port[15:8]);   crc_data_q.push_back(tx_req.dest_port[15:8]);
      expected_packet.push_back(tx_req.dest_port[7:0]);    crc_data_q.push_back(tx_req.dest_port[7:0]);
      expected_packet.push_back((tx_req.payload.size()+8) >> 8); crc_data_q.push_back((tx_req.payload.size()+8) >> 8);
      expected_packet.push_back((tx_req.payload.size()+8) & 8'hFF); crc_data_q.push_back((tx_req.payload.size()+8) & 8'hFF);
      expected_packet.push_back(exp_udp_chk[15:8]); crc_data_q.push_back(exp_udp_chk[15:8]);
      expected_packet.push_back(exp_udp_chk[7:0]);  crc_data_q.push_back(exp_udp_chk[7:0]);

      for (int i = 0; i < tx_req.payload.size(); i++) begin expected_packet.push_back(tx_req.payload[i]); crc_data_q.push_back(tx_req.payload[i]); end

      // 5. CRC-32 (LSB-First injection matching RTL Phase 3 decision!)
      expected_crc = calc_crc32(crc_data_q);
      for (int i = 0; i <= 3; i++) expected_packet.push_back(expected_crc[i*8 +: 8]);

      exp_str = ""; act_str = "";
      foreach(expected_packet[i]) exp_str = {exp_str, $sformatf("%02h ", expected_packet[i])};
      foreach(rx_req.packet_data[i]) act_str = {act_str, $sformatf("%02h ", rx_req.packet_data[i])};
      `uvm_info("SCB_HEX", $sformatf("\n[EXPECTED %0dB]: %s\n[RECEIVED %0dB]: %s", expected_packet.size(), exp_str, rx_req.packet_data.size(), act_str), UVM_NONE)
      
      `uvm_info("SCB_DISSECTION", $sformatf({
        "\n[Packet Dissection]:\n",
        "  --- Ethernet II ---\n  Destination MAC : %02h:%02h:%02h:%02h:%02h:%02h\n  Source MAC      : %02h:%02h:%02h:%02h:%02h:%02h\n  Type            : 0x%04h (IPv4)\n",
        "  --- IPv4 Header ---\n  Version         : %0d\n  Header Length   : %0d (%0d bytes)\n  Type of Service : 0x%02h\n  Total Length    : %0d\n  Identification  : 0x%04h\n  Flags           : 0x%01h\n  Fragment Offset : %0d\n  Time to Live    : %0d\n  Protocol        : %0d (UDP)\n  Header Checksum : 0x%04h\n  Source IP       : %0d.%0d.%0d.%0d\n  Destination IP  : %0d.%0d.%0d.%0d\n",
        "  --- UDP Header ---\n  Source Port     : %0d\n  Dest Port       : %0d\n  UDP Length      : %0d\n  UDP Checksum    : 0x%04h\n  Payload Size    : %0d Bytes\n",
        "  --- FCS ---\n  Frame CRC-32    : 0x%08h"
      }, 
      tx_req.dest_mac[47:40], tx_req.dest_mac[39:32], tx_req.dest_mac[31:24], tx_req.dest_mac[23:16], tx_req.dest_mac[15:8], tx_req.dest_mac[7:0],
      tx_req.source_mac[47:40], tx_req.source_mac[39:32], tx_req.source_mac[31:24], tx_req.source_mac[23:16], tx_req.source_mac[15:8], tx_req.source_mac[7:0], tx_req.eth_type,
      tx_req.version, tx_req.ihl, (tx_req.ihl * 4), tx_req.tos, tx_req.total_length, tx_req.id, tx_req.flags, tx_req.frag_offset, tx_req.ttl, tx_req.protocol, exp_ip_chk,
      tx_req.src_ip[31:24], tx_req.src_ip[23:16], tx_req.src_ip[15:8], tx_req.src_ip[7:0], tx_req.dest_ip[31:24], tx_req.dest_ip[23:16], tx_req.dest_ip[15:8], tx_req.dest_ip[7:0],
      tx_req.source_port, tx_req.dest_port, (tx_req.payload.size() + 8), exp_udp_chk, tx_req.payload.size(), expected_crc), UVM_NONE)

      match = 1'b1;
      if (expected_packet.size() != rx_req.packet_data.size()) match = 1'b0;
      else for (int i = 0; i < expected_packet.size(); i++) if (expected_packet[i] !== rx_req.packet_data[i]) match = 1'b0;

      if (match) begin `uvm_info("SCB_RESULT", "MATCH! MAC, ODDR, and Protocol Stack perfectly verified.\n", UVM_NONE); pkts_passed++; end 
      else begin `uvm_error("SCB_RESULT", "MISMATCH DETECTED.\n"); pkts_failed++; end
      pkts_checked++;
    end
  endtask

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_REP", $sformatf("\n==================================================\n             FINAL SCOREBOARD SUMMARY               \n==================================================\n  Total Packets Checked : %0d\n  Passed                : %0d\n  Failed                : %0d\n==================================================", pkts_checked, pkts_passed, pkts_failed), UVM_NONE)
  endfunction

  function bit [15:0] calc_ipv4_checksum(eth_tx_seq_item req);
    bit [31:0] sum = {req.version, req.ihl, req.tos} + req.total_length + req.id + {req.flags, req.frag_offset} + {req.ttl, req.protocol} + req.src_ip[31:16] + req.src_ip[15:0] + req.dest_ip[31:16] + req.dest_ip[15:0];
    sum = (sum & 32'hFFFF) + (sum >> 16); sum = (sum & 32'hFFFF) + (sum >> 16);
    return ~sum[15:0];
  endfunction

  function bit [15:0] calc_udp_checksum(eth_tx_seq_item req);
    bit [31:0] sum = req.src_ip[31:16] + req.src_ip[15:0] + req.dest_ip[31:16] + req.dest_ip[15:0] + {8'h00, req.protocol} + (req.payload.size() + 8) + req.source_port + req.dest_port + (req.payload.size() + 8);
    for(int i=0; i<req.payload.size(); i=i+2) sum += (i+1 < req.payload.size()) ? {req.payload[i], req.payload[i+1]} : {req.payload[i], 8'h00};
    sum = (sum & 32'hFFFF) + (sum >> 16); sum = (sum & 32'hFFFF) + (sum >> 16);
    return ~sum[15:0];
  endfunction

  function bit [31:0] calc_crc32(bit [7:0] dq[$]);
    bit [31:0] crc = 32'hFFFFFFFF; bit [31:0] poly = 32'hEDB88320;
    foreach(dq[i]) for(int j=0; j<8; j++) crc = ((crc[0] ^ dq[i][j]) == 1'b1) ? (crc >> 1) ^ poly : (crc >> 1);
    return ~crc;
  endfunction
endclass
`endif