/*`ifndef KRD_DRIVER_SV
`define KRD_DRIVER_SV

class krd_driver extends uvm_driver #(krd_item);
    `uvm_component_utils(krd_driver)
    virtual krd_intf vif;
    
    // We broadcast the injected data to the Scoreboard here!
    uvm_analysis_port #(krd_item) ap_inject; 

    // Persistent storage for the counters so they don't drop to 0
    logic [10:0] p_uart1_vbc = 0, p_uart2_vbc = 0, p_uart3_vbc = 0;
    logic [10:0] p_eth1_vbc = 0,  p_eth2_vbc = 0,  p_eth3_vbc = 0,  p_eth4_vbc = 0;
    logic [10:0] p_uart1_cbc = 0, p_eth1_cbc = 0;

    function new(string name, uvm_component parent); 
        super.new(name, parent); 
        ap_inject = new("ap_inject", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual krd_intf)::get(this, "", "krd_vif", vif)) `uvm_fatal("NO_VIF", "No krd_vif")
    endfunction

    task run_phase(uvm_phase phase);
        vif.rx_fifo_wr_en_uart1 <= 0; vif.rx_fifo_wr_en_uart2 <= 0; vif.rx_fifo_wr_en_uart3 <= 0;
        vif.rx_fifo_wr_en_eth1 <= 0; vif.rx_fifo_wr_en_eth2 <= 0; vif.rx_fifo_wr_en_eth3 <= 0; vif.rx_fifo_wr_en_eth4 <= 0;

        wait(vif.rst_n == 1'b1);
        repeat(150) @(posedge vif.clk); 

        // =========================================================
        // THE FIX: BACKGROUND PHY THREADS
        // We constantly drive the counters natively on their own clocks!
        // =========================================================
        fork
            forever begin 
                @(posedge vif.clk_uart); 
                vif.rx_valid_byte_count_uart1 <= p_uart1_vbc; 
                vif.rx_corrupt_byte_count_uart1 <= p_uart1_cbc;
            end
            forever begin 
                @(posedge vif.clk_eth1); 
                vif.rx_eth_valid_bytes_eth1 <= p_eth1_vbc;  
                vif.rx_eth_corrupt_frame_count_eth1 <= p_eth1_cbc;
            end
            // (Replicate for ETH 2-4 and UART 2-3 as you scale up)
        join_none

        forever begin
            seq_item_port.get_next_item(req);
            
            // Calculate EXACTLY how many new packets the network is trying to inject
            int new_uart1 = (req.rx_valid_byte_count_uart1 > p_uart1_vbc) ? (req.rx_valid_byte_count_uart1 - p_uart1_vbc) : 0;
            int new_eth1  = (req.rx_eth_valid_bytes_eth1 > p_eth1_vbc) ? (req.rx_eth_valid_bytes_eth1 - p_eth1_vbc) : 0;

            // Update persistent counters
            p_uart1_vbc = req.rx_valid_byte_count_uart1;
            p_eth1_vbc  = req.rx_eth_valid_bytes_eth1;

            fork
                // ----------------------------------------
                // DOMAIN 1: UART (44.2368 MHz)
                // ----------------------------------------
                begin
                    if (new_uart1 > 0) begin
                        repeat(new_uart1) begin
                            @(posedge vif.clk_uart);
                            vif.rx_fifo_data_in_uart1 <= req.rx_fifo_data_out_uart1;
                            vif.rx_fifo_wr_en_uart1 <= 1;
                        end
                        @(posedge vif.clk_uart); // Pull down after the burst
                        vif.rx_fifo_wr_en_uart1 <= 0;
                    end
                end

                // ----------------------------------------
                // DOMAIN 2: ETH1 (125 MHz)
                // ----------------------------------------
                begin
                    if (new_eth1 > 0) begin
                        repeat(new_eth1) begin
                            @(posedge vif.clk_eth1);
                            vif.rx_fifo_data_in_eth1 <= req.rx_fifo_data_out_eth1;
                            vif.rx_fifo_wr_en_eth1 <= 1;
                        end
                        @(posedge vif.clk_eth1); // Pull down after the burst
                        vif.rx_fifo_wr_en_eth1 <= 0;
                    end
                end

                // ----------------------------------------
                // DOMAIN 6: SYSTEM FLAGS (64 MHz)
                // ----------------------------------------
                begin
                    @(posedge vif.clk);
                    vif.tx_fifo_full_uart1 <= req.tx_fifo_full_uart1; 
                    vif.tx_fifo_empty_uart1 <= req.tx_fifo_empty_uart1; 
                    vif.tx_fifo_full_eth1 <= req.tx_fifo_full_eth1; 
                    vif.tx_fifo_empty_eth1 <= req.tx_fifo_empty_eth1; 
                    // ... (keep rest of static flags here)
                end
            join

            ap_inject.write(req); 
            seq_item_port.item_done();
        end
    endtask
endclass
`endif*/

`ifndef KRD_DRIVER_SV
`define KRD_DRIVER_SV

class krd_driver extends uvm_driver #(krd_item);
    `uvm_component_utils(krd_driver)
    virtual krd_intf vif;
    
    uvm_analysis_port #(krd_item) ap_inject; 

    // Persistent storage for the counters so they don't drop to 0
    logic [10:0] p_uart1_vbc = 0, p_uart2_vbc = 0, p_uart3_vbc = 0;
    logic [10:0] p_eth1_vbc = 0,  p_eth2_vbc = 0,  p_eth3_vbc = 0,  p_eth4_vbc = 0;
    logic [10:0] p_uart1_cbc = 0, p_eth1_cbc = 0;

    function new(string name, uvm_component parent); 
        super.new(name, parent); 
        ap_inject = new("ap_inject", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual krd_intf)::get(this, "", "krd_vif", vif)) `uvm_fatal("NO_VIF", "No krd_vif")
    endfunction

    task run_phase(uvm_phase phase);
        // STRICT SV RULE: Declare variables at the top of the task!
        int new_uart1;
        int new_eth1;

        vif.rx_fifo_wr_en_uart1 <= 0; vif.rx_fifo_wr_en_uart2 <= 0; vif.rx_fifo_wr_en_uart3 <= 0;
        vif.rx_fifo_wr_en_eth1 <= 0; vif.rx_fifo_wr_en_eth2 <= 0; vif.rx_fifo_wr_en_eth3 <= 0; vif.rx_fifo_wr_en_eth4 <= 0;

        wait(vif.rst_n == 1'b1);
        repeat(150) @(posedge vif.clk); 

        fork
            forever begin 
                @(posedge vif.clk_uart); 
                vif.rx_valid_byte_count_uart1 <= p_uart1_vbc; 
                vif.rx_corrupt_byte_count_uart1 <= p_uart1_cbc;
            end
            forever begin 
                @(posedge vif.clk_eth1); 
                vif.rx_eth_valid_bytes_eth1 <= p_eth1_vbc;  
                vif.rx_eth_corrupt_frame_count_eth1 <= p_eth1_cbc;
            end
        join_none

        forever begin
            seq_item_port.get_next_item(req);
            
            // Calculate EXACTLY how many new packets the network is trying to inject
            new_uart1 = (req.rx_valid_byte_count_uart1 > p_uart1_vbc) ? (req.rx_valid_byte_count_uart1 - p_uart1_vbc) : 0;
            new_eth1  = (req.rx_eth_valid_bytes_eth1 > p_eth1_vbc) ? (req.rx_eth_valid_bytes_eth1 - p_eth1_vbc) : 0;

            // Update persistent counters
            p_uart1_vbc = req.rx_valid_byte_count_uart1;
            p_eth1_vbc  = req.rx_eth_valid_bytes_eth1;

            fork
                begin
                    if (new_uart1 > 0) begin
                        repeat(new_uart1) begin
                            @(posedge vif.clk_uart);
                            vif.rx_fifo_data_in_uart1 <= req.rx_fifo_data_out_uart1;
                            vif.rx_fifo_wr_en_uart1 <= 1;
                        end
                        @(posedge vif.clk_uart);
                        vif.rx_fifo_wr_en_uart1 <= 0;
                    end
                end

                begin
                    if (new_eth1 > 0) begin
                        repeat(new_eth1) begin
                            @(posedge vif.clk_eth1);
                            vif.rx_fifo_data_in_eth1 <= req.rx_fifo_data_out_eth1;
                            vif.rx_fifo_wr_en_eth1 <= 1;
                        end
                        @(posedge vif.clk_eth1);
                        vif.rx_fifo_wr_en_eth1 <= 0;
                    end
                end

                begin
                    @(posedge vif.clk);
                    vif.tx_fifo_full_uart1 <= req.tx_fifo_full_uart1; 
                    vif.tx_fifo_empty_uart1 <= req.tx_fifo_empty_uart1; 
                    vif.tx_fifo_full_eth1 <= req.tx_fifo_full_eth1; 
                    vif.tx_fifo_empty_eth1 <= req.tx_fifo_empty_eth1; 
                end
            join

            ap_inject.write(req); 
            seq_item_port.item_done();
        end
    endtask
endclass
`endif