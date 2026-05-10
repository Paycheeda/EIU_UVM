`ifndef KST_DRIVER_SV
`define KST_DRIVER_SV

class kst_driver extends uvm_driver; // No sequence item parameter needed!
    `uvm_component_utils(kst_driver)

    virtual kst_intf vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual kst_intf)::get(this, "", "kst_vif", vif))
            `uvm_fatal("NO_VIF", "Could not get kst_vif from config DB!")
    endfunction

    task run_phase(uvm_phase phase);
        // Initialize read enables to 0
        vif.rd_en_uart1 <= 0;
        vif.rd_en_uart2 <= 0;
        vif.rd_en_uart3 <= 0;

        `uvm_info("KST_DRV", "Starting Reactive UART Consumer Threads...", UVM_LOW)

        // Run 3 independent physical threads
        fork
            process_uart1();
            process_uart2();
            process_uart3();
        join
    endtask

    // =========================================================
    // Independent UART Threads
    // =========================================================
    task process_uart1();
        forever begin
            @(posedge vif.clk_uart);
            // If the kernel says "Acquire Data" and the FIFO isn't empty...
            if (vif.rst_n && vif.tx_acq_start_uart1 && !vif.fifo_empty_uart1) begin
                
                // 1. Simulate UART Baud Rate Delay (Wait a random few cycles to transmit a byte)
                repeat($urandom_range(5, 15)) @(posedge vif.clk_uart);

                // 2. Pulse the Read Enable to pop one byte out of the physical FIFO
                vif.rd_en_uart1 <= 1'b1;
                @(posedge vif.clk_uart);
                vif.rd_en_uart1 <= 1'b0;

                `uvm_info("KST_DRV", "UART1 consumed 1 byte from physical FIFO.", UVM_HIGH)
            end
        end
    endtask

    task process_uart2();
        forever begin
            @(posedge vif.clk_uart);
            if (vif.rst_n && vif.tx_acq_start_uart2 && !vif.fifo_empty_uart2) begin
                repeat($urandom_range(5, 15)) @(posedge vif.clk_uart);
                vif.rd_en_uart2 <= 1'b1;
                @(posedge vif.clk_uart);
                vif.rd_en_uart2 <= 1'b0;
                `uvm_info("KST_DRV", "UART2 consumed 1 byte from physical FIFO.", UVM_HIGH)
            end
        end
    endtask

    task process_uart3();
        forever begin
            @(posedge vif.clk_uart);
            if (vif.rst_n && vif.tx_acq_start_uart3 && !vif.fifo_empty_uart3) begin
                repeat($urandom_range(5, 15)) @(posedge vif.clk_uart);
                vif.rd_en_uart3 <= 1'b1;
                @(posedge vif.clk_uart);
                vif.rd_en_uart3 <= 1'b0;
                `uvm_info("KST_DRV", "UART3 consumed 1 byte from physical FIFO.", UVM_HIGH)
            end
        end
    endtask

endclass

`endif