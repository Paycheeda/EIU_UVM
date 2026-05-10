`ifndef RX_FIFO_IN_DRIVER_SV
`define RX_FIFO_IN_DRIVER_SV

class rx_fifo_in_driver extends uvm_driver #(rx_fifo_in_seq_item);
  `uvm_component_utils(rx_fifo_in_driver)
  virtual eth_rx_fifo_if vif;

  function new(string name = "rx_fifo_in_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual eth_rx_fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Virtual IF not found in IN Driver")
  endfunction

  virtual task run_phase(uvm_phase phase);
    `uvm_info("IN_DRV", "Driver starting...", UVM_NONE)
    
    // Initialize standard state
    vif.payload_length <= 0;
    vif.rx_transaction_done_pulse <= 0;
    vif.packet_received_corrupt_pulse <= 0;
    vif.invalid_bytes <= 0;
    vif.int_fifo_data_out <= 0;
    
    wait(vif.rst_n == 1'b1);

    forever begin
      seq_item_port.get_next_item(req);
      drive_ram_transaction(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_ram_transaction(rx_fifo_in_seq_item req);
    int ram_idx = 0;
    
    // 1. Load the Configuration
    vif.payload_length <= req.payload_length;
    vif.invalid_bytes  <= req.invalid_bytes;
    
    // 2. Pulse the Triggers (Mimicking the PHY module's output)
    @(posedge vif.clk);
    vif.rx_transaction_done_pulse     <= 1'b1;
    vif.packet_received_corrupt_pulse <= req.is_corrupt;
    
    @(posedge vif.clk);
    vif.rx_transaction_done_pulse     <= 1'b0;
    vif.packet_received_corrupt_pulse <= 1'b0;
    
    `uvm_info("IN_DRV", $sformatf("Triggered DMA. Corrupt: %0b | RAM Size Loaded: %0d", req.is_corrupt, req.internal_ram_data.size()), UVM_NONE)

    // 3. Act as Reactive RAM until the DMA finishes
    fork
        begin
            // RAM Thread: Feed data whenever rd_en is high
            forever begin
                @(posedge vif.clk);
                if (vif.int_fifo_rd_en) begin
                    if (ram_idx < req.internal_ram_data.size()) begin
                        vif.int_fifo_data_out <= req.internal_ram_data[ram_idx];
                        `uvm_info("IN_DRV_RAM", $sformatf("RTL Read Index [%0d] | Data: 8'h%02h", ram_idx, req.internal_ram_data[ram_idx]), UVM_NONE)
                        ram_idx++;
                    end else begin
                        vif.int_fifo_data_out <= 8'h00; // Out of bounds read protection
                    end
                end
            end
        end
        begin
            // Completion Thread: Wait for the RTL to finish its task
            if (!req.is_corrupt) begin
                wait(vif.eth_rx_data_valid == 1'b1);
                `uvm_info("IN_DRV", "RTL finished Clean Transfer. Cleaning up...", UVM_NONE)
                @(posedge vif.clk); 
            end else begin
                // ALIGNMENT FIX: The Driver MUST wait longer than the Monitors (+20) 
                // so they have time to loop back and arm themselves for the next trigger!
                repeat(req.invalid_bytes + 30) @(posedge vif.clk); 
                `uvm_info("IN_DRV", "RTL finished Corrupt Flush. Cleaning up...", UVM_NONE)
            end
        end
    join_any
    disable fork; // Kill the RAM thread so it resets for the next packet
    
    vif.int_fifo_data_out <= 8'h00;
    @(posedge vif.clk);
  endtask
endclass

`endif