`ifndef ETH_RX_IF_DRIVER_SV
`define ETH_RX_IF_DRIVER_SV

class eth_rx_if_driver extends uvm_driver #(phy_rx_seq_item);
  `uvm_component_utils(eth_rx_if_driver)
  virtual eth_rx_if vif;

  function new(string name = "eth_rx_if_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual eth_rx_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Virtual IF not found in RX Driver")
  endfunction

  virtual task run_phase(uvm_phase phase);
    `uvm_info("RX_DRV", "Driver starting... Waiting for reset.", UVM_NONE)
    vif.rxd <= 0; vif.rx_dv <= 0; vif.rx_er <= 0;
    wait(vif.rst_n == 1'b1);
    `uvm_info("RX_DRV", "Reset cleared! Entering main loop.", UVM_NONE)

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info("RX_DRV", "Received new packet from sequence. Driving now...", UVM_NONE)
      drive_packet(req);
      seq_item_port.item_done();
      `uvm_info("RX_DRV", "Packet fully processed. Requesting next...", UVM_NONE)
    end
  endtask

  task drive_packet(phy_rx_seq_item req);
    bit [7:0] frame_data[$]; 
    bit [31:0] fcs;          
    bit [15:0] ip_chk, udp_chk;
    int byte_idx = 0;

    // 1. Calculate Checksums
    ip_chk = calc_ipv4_checksum(req);
    udp_chk = calc_udp_checksum(req);

    // 2. Pack the Frame (MAC, IP, UDP, Payload) into the Queue
    for (int i=5; i>=0; i--) frame_data.push_back(req.dest_mac[i*8 +: 8]);
    for (int i=5; i>=0; i--) frame_data.push_back(req.source_mac[i*8 +: 8]);
    for (int i=1; i>=0; i--) frame_data.push_back(req.eth_type[i*8 +: 8]);
    
    frame_data.push_back({req.version, req.ihl}); frame_data.push_back(req.tos);
    frame_data.push_back(req.total_length[15:8]); frame_data.push_back(req.total_length[7:0]);
    frame_data.push_back(req.id[15:8]);           frame_data.push_back(req.id[7:0]);
    frame_data.push_back({req.flags, req.frag_offset[12:8]}); frame_data.push_back(req.frag_offset[7:0]);
    frame_data.push_back(req.ttl);                frame_data.push_back(req.protocol);
    frame_data.push_back(ip_chk[15:8]);           frame_data.push_back(ip_chk[7:0]);
    for (int i=3; i>=0; i--) frame_data.push_back(req.src_ip[i*8 +: 8]);
    for (int i=3; i>=0; i--) frame_data.push_back(req.dest_ip[i*8 +: 8]);

    frame_data.push_back(req.source_port[15:8]);  frame_data.push_back(req.source_port[7:0]);
    frame_data.push_back(req.dest_port[15:8]);    frame_data.push_back(req.dest_port[7:0]);
    frame_data.push_back((req.payload.size()+8) >> 8); frame_data.push_back((req.payload.size()+8) & 8'hFF);
    frame_data.push_back(udp_chk[15:8]);          frame_data.push_back(udp_chk[7:0]);
    
    foreach(req.payload[i]) frame_data.push_back(req.payload[i]);

    // 3. Calculate Frame Check Sequence (CRC-32)
    fcs = calc_crc32(frame_data);
    if (req.inject_crc_error) begin
        fcs = ~fcs; 
        `uvm_info("RX_DRV", "FAULT INJECTED: Corrupted CRC!", UVM_NONE)
    end
    for (int i=0; i<=3; i++) frame_data.push_back(fcs[i*8 +: 8]);

    // ========================================================
    // PHYSICAL TRANSMISSION
    // ========================================================
    `uvm_info("RX_DRV", "Driving Preamble...", UVM_NONE)
    
    // ALIGNMENT FIX: Wait for clock edge BEFORE asserting rx_dv!
    @(posedge vif.clk);
    vif.rx_dv <= 1'b1;
    vif.rxd <= 8'h55; // First preamble byte goes out exactly WITH rx_dv
    
    for(int i=0; i<6; i++) begin // Loop is now 6 instead of 7
       @(posedge vif.clk); vif.rxd <= 8'h55;
    end
    @(posedge vif.clk); vif.rxd <= 8'hd5; // SFD

    `uvm_info("RX_DRV", $sformatf("Driving %0d bytes of Frame Data...", frame_data.size()), UVM_NONE)
    while(frame_data.size() > 0) begin
       @(posedge vif.clk);
       if (req.early_drop_at_byte > 0 && byte_idx == req.early_drop_at_byte) begin
           vif.rx_dv <= 1'b0;
           break;
       end
       if (req.inject_rx_er_at_byte > 0 && byte_idx == req.inject_rx_er_at_byte) vif.rx_er <= 1'b1;
       else vif.rx_er <= 1'b0;

       vif.rxd <= frame_data.pop_front();
       byte_idx++;
    end

    @(posedge vif.clk);
    vif.rx_dv <= 1'b0;
    vif.rx_er <= 1'b0;
    vif.rxd <= 8'h00;

    `uvm_info("RX_DRV", "Transmission complete. Waiting for RTL transaction_done_pulse...", UVM_NONE) 
    // --> THE WATCHDOG TIMER <--
    // Instead of waiting forever and hanging, we will race the wait statement against a clock!
    fork
        begin
            wait(vif.rx_transaction_done_pulse == 1'b1);
            `uvm_info("RX_DRV", "SUCCESS: RTL pulsed transaction done!", UVM_NONE)
        end
        begin
            repeat(200) @(posedge vif.clk); // Wait for 200 clock cycles maximum
            `uvm_error("RX_DRV_WATCHDOG", "FATAL HANG: RTL never pulsed rx_transaction_done_pulse! The FSM is stuck!")
        end
    join_any
    disable fork; // Kill whichever process didn't finish
    
    @(posedge vif.clk);
  endtask

  function bit [15:0] calc_ipv4_checksum(phy_rx_seq_item req);
    bit [31:0] sum = {req.version, req.ihl, req.tos} + req.total_length + req.id + {req.flags, req.frag_offset} + {req.ttl, req.protocol} + req.src_ip[31:16] + req.src_ip[15:0] + req.dest_ip[31:16] + req.dest_ip[15:0];
    sum = (sum & 32'hFFFF) + (sum >> 16); sum = (sum & 32'hFFFF) + (sum >> 16);
    return ~sum[15:0];
  endfunction

  function bit [15:0] calc_udp_checksum(phy_rx_seq_item req);
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