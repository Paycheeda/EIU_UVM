`ifndef NRZ_MONITOR_SV
`define NRZ_MONITOR_SV

class nrz_monitor extends uvm_monitor;
    `uvm_component_utils(nrz_monitor)

    virtual nrz_intf vif;
    uvm_analysis_port #(nrz_out_item) ap; // Ensure nrz_out_item is defined in your sequence_item folder
    
    bit [7:0] byte_queue[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual nrz_intf)::get(this, "", "nrz_vif", vif))
            `uvm_fatal("NO_VIF", "Could not find nrz_vif in config DB!")
    endfunction

    task run_phase(uvm_phase phase);
        fork
            // THREAD 1: Capture Data into the FIFO (64MHz Domain)
            begin
                forever begin
                    @(posedge vif.clk_64mhz);
                    if (vif.fifo_wr_en) begin
                        byte_queue.push_back(vif.fifo_data_in);
                    end
                end
            end
            
            // THREAD 2: Packet Trigger (ETH TX Start Pulse)
            begin
                nrz_out_item out_item;
                forever begin
                    @(posedge vif.eth_tx_start_pulse);
                    
                    // FIXED: Wait exactly 1 clock cycle to avoid delta-cycle race conditions
                    @(posedge vif.clk_64mhz); 
                    
                    out_item = nrz_out_item::type_id::create("out_item");
                    out_item.unpacked_bytes = new[byte_queue.size()];
                    
                    foreach(byte_queue[i]) begin
                        out_item.unpacked_bytes[i] = byte_queue[i];
                    end
                    
                    `uvm_info("NRZ_MON", $sformatf("Captured NRZ Packet of %0d bytes.", byte_queue.size()), UVM_HIGH)
                    ap.write(out_item);
                    
                    byte_queue.delete();
                end
            end
        join
    endtask

endclass
`endif