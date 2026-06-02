`ifndef ETH_TX_MONITOR_SV
`define ETH_TX_MONITOR_SV

class eth_tx_monitor extends uvm_monitor;
  `uvm_component_utils(eth_tx_monitor)
  
  virtual eth_tx_if vif;
  uvm_analysis_port #(eth_tx_seq_item) mon_ap;

  function new(string name="eth_tx_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    
    if(!uvm_config_db#(virtual eth_tx_if)::get(this, "", "tx_vif", vif)) 
      `uvm_fatal("NO_VIF", "Physical ETH TX Interface not found in TX Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    eth_tx_seq_item item;
    byte unsigned raw_packet[$]; 
    bit [3:0] nibble_pos;
    bit [3:0] nibble_neg;
    byte unsigned current_byte;
    int idx;
    bit [31:0] received_crc;

    wait(vif.rst_n == 1'b1);
    
    forever begin
        // Wait for the exact posedge where tx_ctl goes HIGH
        @(posedge vif.tx_c);
        if (vif.tx_ctl == 1'b1) begin
            raw_packet.delete();
            `uvm_info("TX_MON", "tx_ctl went HIGH! Start of Frame detected. Sampling DDR pins...", UVM_LOW)

            // Sample Pos Edge (Add 10ps to avoid race condition)
            #10ps;
            nibble_pos = vif.txd;

            // Sample Neg Edge
            @(negedge vif.tx_c);
            #10ps;
            nibble_neg = vif.txd;

            current_byte = {nibble_neg, nibble_pos};
            raw_packet.push_back(current_byte);

            // Capture the rest of the packet
            while (1) begin
                @(posedge vif.tx_c);
                #10ps;
                if (vif.tx_ctl == 1'b0) break; // Packet finished
                nibble_pos = vif.txd;
                
                @(negedge vif.tx_c);
                #10ps;
                nibble_neg = vif.txd;

                current_byte = {nibble_neg, nibble_pos};
                raw_packet.push_back(current_byte);
            end

            `uvm_info("TX_MON", $sformatf("tx_ctl went LOW. Captured %0d bytes from physical pins.", raw_packet.size()), UVM_LOW)

            // PACKET PARSER
            // Accept small but valid IPv4/UDP frames too.  ETH2/3/4 were previously
            // silently ignored when misconfigured to payload length 0 because those
            // frames are only ~54 physical bytes including preamble and FCS.
            if (raw_packet.size() >= 50) begin
                item = eth_tx_seq_item::type_id::create("item");
                idx = 0;

                // Strip Preamble & SFD
                while (idx < raw_packet.size() && raw_packet[idx] == 8'h55) idx++;
                if (idx < raw_packet.size() && raw_packet[idx] == 8'hD5) idx++;

                // Extract MAC Header
                item.dest_mac   = {raw_packet[idx], raw_packet[idx+1], raw_packet[idx+2], raw_packet[idx+3], raw_packet[idx+4], raw_packet[idx+5]}; idx+=6;
                item.source_mac = {raw_packet[idx], raw_packet[idx+1], raw_packet[idx+2], raw_packet[idx+3], raw_packet[idx+4], raw_packet[idx+5]}; idx+=6;
                item.eth_type   = {raw_packet[idx], raw_packet[idx+1]}; idx+=2;

                if (item.eth_type == 16'h0800) begin // IPv4
                    item.version      = raw_packet[idx] >> 4;
                    item.ihl          = raw_packet[idx] & 4'hF; idx++;
                    item.tos          = raw_packet[idx++];
                    item.total_length = {raw_packet[idx], raw_packet[idx+1]}; idx+=2;
                    item.id           = {raw_packet[idx], raw_packet[idx+1]}; idx+=2;
                    item.flags        = raw_packet[idx] >> 5;
                    item.frag_offset  = {raw_packet[idx] & 3'h1f, raw_packet[idx+1]}; idx+=2;
                    item.ttl          = raw_packet[idx++];
                    item.protocol     = raw_packet[idx++]; 
                    idx+=2; // Checksum
                    item.src_ip       = {raw_packet[idx], raw_packet[idx+1], raw_packet[idx+2], raw_packet[idx+3]}; idx+=4;
                    item.dest_ip      = {raw_packet[idx], raw_packet[idx+1], raw_packet[idx+2], raw_packet[idx+3]}; idx+=4;
                    
                    if (item.protocol == 8'd17) begin // UDP
                        item.source_port = {raw_packet[idx], raw_packet[idx+1]}; idx+=2;
                        item.dest_port   = {raw_packet[idx], raw_packet[idx+1]}; idx+=2;
                        idx+=2; // UDP Len
                        idx+=2; // UDP Chksum
                        
                        // Extract Payload.  A zero-length UDP payload is legal and
                        // should still be broadcast so missing ETH configuration is
                        // visible instead of being hidden by this monitor.
                        if (raw_packet.size() >= idx + 4) begin
                            int payload_len = raw_packet.size() - idx - 4;
                            item.payload = new[payload_len];
                            for (int i = 0; i < payload_len; i++) begin
                                item.payload[i] = raw_packet[idx++];
                            end
                            
                            // Extract hardware-generated CRC
                            received_crc = {raw_packet[idx], raw_packet[idx+1], raw_packet[idx+2], raw_packet[idx+3]};
                            
                            `uvm_info("TX_MON", $sformatf("Parsed UDP Payload (%0d bytes). Extracted hardware CRC: 0x%0h. Broadcasting to Scoreboard!", payload_len, received_crc), UVM_LOW)
                            mon_ap.write(item);
                        end
                    end
                end
            end
        end
    end
  endtask
endclass
`endif