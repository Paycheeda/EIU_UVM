/*`ifndef ETH_TX_MONITOR_SV
`define ETH_TX_MONITOR_SV

class eth_tx_monitor extends uvm_monitor;
  `uvm_component_utils(eth_tx_monitor)
  virtual eth_if vif; uvm_analysis_port #(eth_tx_seq_item) mon_ap;

  function new(string name="eth_tx_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual eth_if)::get(this, "", "vif", vif)) `uvm_fatal("NO_VIF", "No VIF")
  endfunction

  virtual task run_phase(uvm_phase phase);
    eth_tx_seq_item item; bit rd_en_d1;
    wait(vif.rst_n == 1'b1);
    
    forever begin
      @(posedge vif.eth_tx_start_pulse);
      item = eth_tx_seq_item::type_id::create("item");
      
      // Capture dynamic metadata
      item.dest_mac = vif.dest_mac_in; item.source_mac = vif.source_mac_in; item.eth_type = vif.eth_type_in;
      item.version = vif.version_in; item.ihl = vif.header_length_in; item.tos = vif.type_of_service_in;
      item.total_length = vif.ipv4_total_length_in; item.id = vif.identification_in; item.flags = vif.flags_in;
      item.frag_offset = vif.fragment_offset_in; item.ttl = vif.time_to_live_in; item.protocol = vif.protocol_in;
      item.src_ip = vif.source_ip_in; item.dest_ip = vif.dest_ip_in;
      item.source_port = vif.source_port_in; item.dest_port = vif.dest_port_in;
      item.payload = new[0]; rd_en_d1 = 0;

      // Loop 1: Wait for the flag to CLEAR (from the previous packet)
      // We must capture payload bytes here because the Checksum FSM starts reading early!
      while(vif.eth_tx_data_sent_pulse == 1'b1) begin
         @(posedge vif.clk);
         if(rd_en_d1) begin
            item.payload = new[item.payload.size() + 1] (item.payload);
            item.payload[item.payload.size()-1] = vif.ext_fifo_data_out;
         end
         rd_en_d1 = vif.ext_fifo_rd_en; 
      end

      // Loop 2: Wait for the flag to SET (current packet transmission is finished)
      while(vif.eth_tx_data_sent_pulse == 1'b0) begin
         @(posedge vif.clk);
         if(rd_en_d1) begin
            item.payload = new[item.payload.size() + 1] (item.payload);
            item.payload[item.payload.size()-1] = vif.ext_fifo_data_out;
         end
         rd_en_d1 = vif.ext_fifo_rd_en; 
      end

      // Catch any final lingering byte on the very last clock cycle
      if(rd_en_d1) begin
         item.payload = new[item.payload.size() + 1] (item.payload);
         item.payload[item.payload.size()-1] = vif.ext_fifo_data_out;
      end

      mon_ap.write(item);
    end
  endtask
endclass
`endif*/ //COMMENTED OUT FOR LOOPBACK VERIFICATION
`ifndef ETH_TX_MONITOR_SV
`define ETH_TX_MONITOR_SV

class eth_tx_monitor extends uvm_monitor;
  `uvm_component_utils(eth_tx_monitor)
  
  virtual eth_tx_if vif;
  virtual fault_inject_if fi_vif; 
  
  uvm_analysis_port #(eth_tx_seq_item) mon_ap;

  function new(string name="eth_tx_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    
    if(!uvm_config_db#(virtual eth_tx_if)::get(this, "", "tx_vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF")
      
    if(!uvm_config_db#(virtual fault_inject_if)::get(this, "", "fi_vif", fi_vif)) 
      `uvm_fatal("NO_FI_VIF", "Fault Inject IF not found in TX Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    eth_tx_seq_item item;
    byte payload_q[$]; // Queue to safely collect bytes as they arrive

    wait(vif.rst_n == 1'b1);
    
    // Use a fork to run data collection and packaging concurrently
    fork
        // ---------------------------------------------------------
        // THREAD 1: THE BLACK-BOX SNOOPER
        // ---------------------------------------------------------
        // Constantly watch the input pins and grab bytes the moment 
        // they enter the external FIFO, completely independent of RTL timing.
        forever begin
            @(posedge vif.clk);
            if (vif.ext_tx_fifo_wr_en) begin
                payload_q.push_back(vif.ext_tx_fifo_data_in);
            end
        end

        // ---------------------------------------------------------
        // THREAD 2: THE PACKAGER
        // ---------------------------------------------------------
        // Wait for the start pulse, package the queued bytes, and send.
        forever begin
            @(posedge vif.eth_tx_start_pulse);
            `uvm_info("TX_MON", "Detected eth_tx_start_pulse. Packaging item...", UVM_LOW)
            
            item = eth_tx_seq_item::type_id::create("item");
            
            item.dest_mac    = vif.dest_mac; 
            item.source_mac  = vif.source_mac; 
            item.src_ip      = vif.source_ip; 
            item.dest_ip     = vif.dest_ip;
            item.source_port = vif.source_port; 
            item.dest_port   = vif.dest_port;
            
            item.eth_type    = 16'h0800;
            item.version     = 4'd4; 
            item.ihl         = 4'd5; 
            item.tos         = 8'd0;
            item.id          = 16'h0000; 
            item.flags       = 3'b010; 
            item.frag_offset = 13'd0; 
            item.ttl         = 8'd64; 
            item.protocol    = 8'd17;

            // Dump the captured queue into the payload array
            item.payload = new[payload_q.size()];
            foreach(payload_q[i]) begin
                item.payload[i] = payload_q[i];
            end
            payload_q.delete(); // Clear the queue for the next packet

            item.total_length = item.payload.size() + 28; 

            // Tag the packet with the physical fault state
            item.fault_type = fi_vif.fault_type;

            `uvm_info("TX_MON", $sformatf("Serialization Complete. Sent %0d-Byte Payload. Fault Tag: %s", item.payload.size(), item.fault_type.name()), UVM_LOW)
            
            // Hex Dump first 5 bytes for alignment checking
            for(int i = 0; i < item.payload.size(); i++) begin
               if (i < 5) `uvm_info("TX_MON_DUMP", $sformatf(" Payload Byte[%0d]: %h", i, item.payload[i]), UVM_DEBUG)
            end

            mon_ap.write(item);
        end
    join
  endtask
endclass
`endif
