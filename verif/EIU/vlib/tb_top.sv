`timescale 1ns/100fs
`ifndef TB_TOP_SV
`define TB_TOP_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import eiu_pkg::*;

module tb_top;

    // =========================================================
    // 1. PHYSICAL CLOCK GENERATORS & DUMMY WIRES
    // =========================================================
    logic clk_64MHz      = 0;
    logic clk_44_2368MHz = 0;
    logic clk1_125MHz    = 0;
    logic clk2_125MHz    = 0;
    logic clk3_125MHz    = 0;
    logic clk4_125MHz    = 0;
    logic clk_nrz_125MHz = 0;
    logic clk_20MHz      = 0;

    always #7.8125  clk_64MHz      = ~clk_64MHz;
    always #9.0422 clk_44_2368MHz = ~clk_44_2368MHz;
    always #4.0     clk1_125MHz    = ~clk1_125MHz;
    always #4.0     clk2_125MHz    = ~clk2_125MHz;
    always #4.0     clk3_125MHz    = ~clk3_125MHz;
    always #4.0     clk4_125MHz    = ~clk4_125MHz;
    always #4.0     clk_nrz_125MHz = ~clk_nrz_125MHz;
    always #25.0    clk_20MHz      = ~clk_20MHz;

    logic rx_c_eth1 = 0, rx_c_eth2 = 0, rx_c_eth3 = 0, rx_c_eth4 = 0;
    always #4.0 rx_c_eth1 = ~rx_c_eth1;
    always #4.0 rx_c_eth2 = ~rx_c_eth2;
    always #4.0 rx_c_eth3 = ~rx_c_eth3;
    always #4.0 rx_c_eth4 = ~rx_c_eth4;

    logic rst_n;
    initial begin rst_n = 1'b0; #200; rst_n = 1'b1; end

    logic [3:0] txd_eth[5];
    logic       tx_c_eth[5];
    logic       tx_ctl_eth[5];

    // =========================================================
    // 2. Interface Instantiations (The "Probes")
    // =========================================================
    bkp_intf bkp_if(.clk(clk_20MHz), .rst_n(rst_n));
    nrz_intf nrz_if(.clk_20mhz(clk_20MHz), .clk_64mhz(clk_64MHz));

    uart_unified_intf uart_rx_if[3](.clk(clk_44_2368MHz));
    uart_unified_intf uart_tx_if[3](.clk(clk_44_2368MHz));

    // ---> NEW: Bridge the Reset to the UART Interfaces <---
    generate
        for (genvar i = 0; i < 3; i++) begin : uart_bridge
            assign uart_rx_if[i].rst_n = rst_n;
            assign uart_tx_if[i].rst_n = rst_n;
        end
    endgenerate

    // ---> FIXED: BOTH ETH RX INTERFACES ARE INSTANTIATED <---
    mac_rx_if eth_rx_if[4](.clk(clk1_125MHz), .rst_n(rst_n));      // For the Monitor & DUT
    eth_rx_if eth_rx_drv_if[4](.clk(clk1_125MHz), .rst_n(rst_n));  // For the UVM Driver

    // =========================================================
    // ---> NEW: BRIDGE THE UVM DRIVER TO THE DUT PINS <---
    // =========================================================
    generate
        for (genvar i = 0; i < 4; i++) begin : eth_bridge
            // Map the UVM 8-bit driver to the DUT 4-bit PHY
            assign eth_rx_if[i].rxd    = eth_rx_drv_if[i].rxd[3:0]; 
            assign eth_rx_if[i].rx_ctl = eth_rx_drv_if[i].rx_dv;

            // Fake the transaction_done pulse to prevent the FATAL HANG!
            logic rx_dv_q = 0;
            always @(posedge clk1_125MHz) begin
                rx_dv_q <= eth_rx_drv_if[i].rx_dv;
                // Pulse high for exactly 1 clock cycle when rx_dv falls (packet ends)
                eth_rx_drv_if[i].rx_transaction_done_pulse <= (rx_dv_q && !eth_rx_drv_if[i].rx_dv);
            end
        end
    endgenerate

    
    eth_tx_if eth_tx_if[5](.clk(clk1_125MHz), .rst_n(rst_n));
    fault_inject_if fi_if[5](.clk(clk1_125MHz));

    // ---> ADD THIS BLOCK RIGHT HERE <---
    // Map the physical EIU_TOP wires into the UVM interface
    generate
        for(genvar i=0; i<5; i++) begin : eth_tx_assigns
            assign eth_tx_if[i].txd    = txd_eth[i];
            assign eth_tx_if[i].tx_ctl = tx_ctl_eth[i];
            assign eth_tx_if[i].tx_c   = tx_c_eth[i];
        end
    endgenerate
    // ----------------------------------

    // =========================================================
    // 2. DUT INSTANTIATION
    // =========================================================
    EIU_TOP DUT (
        .clk_64MHz              (clk_64MHz),
        .clk_125MHz_eth1             (clk1_125MHz), // Using clk1 for the unified clk_125MHz
        .clk_125MHz_eth2        (clk2_125MHz),
        .clk_125MHz_eth3        (clk3_125MHz),
        .clk_125MHz_eth4        (clk4_125MHz),
        .clk_125MHz_eth_nrz     (clk_nrz_125MHz),
        .clk_uart_55_296MHz     (clk_44_2368MHz), // Assuming this is the intended connection

        // UART1
        .uart1_rx               (uart_rx_if[0].rx),
        .uart1_tx               (uart_tx_if[0].tx),

        // UART2
        .uart2_rx               (uart_rx_if[1].rx),
        .uart2_tx               (uart_tx_if[1].tx),
        
        // UART3
        .uart3_rx               (uart_rx_if[2].rx),
        .uart3_tx               (uart_tx_if[2].tx),

        // ETH1 RGMII
        .rx_c_eth1                 (rx_c_eth1),
        .rxd_eth1                 (eth_rx_if[0].rxd),
        .rx_ctl_eth1               (eth_rx_if[0].rx_ctl),
        .txd_eth1                  (txd_eth[0]),
        .tx_ctl_eth1               (tx_ctl_eth[0]),
        .tx_c_eth1                 (tx_c_eth[0]),

        // ETH2 RGMII
        .rx_c_eth2                 (rx_c_eth2),
        .rxd_eth2                  (eth_rx_if[1].rxd),
        .rx_ctl_eth2               (eth_rx_if[1].rx_ctl),
        .txd_eth2                  (txd_eth[1]),
        .tx_ctl_eth2               (tx_ctl_eth[1]),
        .tx_c_eth2                 (tx_c_eth[1]),

        // ETH3 RGMII
        .rx_c_eth3                 (rx_c_eth3),
        .rxd_eth3                  (eth_rx_if[2].rxd),
        .rx_ctl_eth3               (eth_rx_if[2].rx_ctl),
        .txd_eth3                  (txd_eth[2]),
        .tx_ctl_eth3               (tx_ctl_eth[2]),
        .tx_c_eth3                 (tx_c_eth[2]),

        // ETH4 RGMII
        .rx_c_eth4                 (rx_c_eth4),
        .rxd_eth4                  (eth_rx_if[3].rxd),
        .rx_ctl_eth4               (eth_rx_if[3].rx_ctl),
        .txd_eth4                  (txd_eth[3]),
        .tx_ctl_eth4               (tx_ctl_eth[3]),
        .tx_c_eth4                 (tx_c_eth[3]),

        // ETH5 (NRZ) RGMII TX ONLY
        .txd_eth_nrz                  (txd_eth[4]),
        .tx_ctl_eth_nrz               (tx_ctl_eth[4]),
        .tx_c_eth_nrz                 (tx_c_eth[4]),

        // Backplane CPU Interface
        .rst_n                  (rst_n),
        .bkp_config_wr_pulse    (bkp_if.bkp_config_wr_pulse),
        .word_start_strobe_pulse(bkp_if.word_start_strobe),
        .bkp_address            (bkp_if.bkp_address),
        .bkp_data_dir           (bkp_if.bkp_data_dir),
        .bkp_prg_mode_on           (bkp_if.program_mode),
        .bkp_card_id            (bkp_if.bkp_card_id),
        .fpga_card_id           (bkp_if.fpga_card_id),
        .bkp_data_bus           (bkp_if.bkp_data),
        //rst_n

        // NRZ Telemetry Input
        .clk_20MHz              (nrz_if.clk_20mhz),
        .data_in_nrz            (nrz_if.data_in_nrz)
    );

    // =========================================================
    // 4. Start UVM Test
    // =========================================================
    initial begin
        uvm_config_db#(virtual bkp_intf)::set(null, "*", "bkp_vif", bkp_if);
        uvm_config_db#(virtual nrz_intf)::set(null, "*", "nrz_vif", nrz_if);

        uvm_config_db#(virtual uart_unified_intf)::set(null, "*", "uart_rx_vif_0", uart_rx_if[0]);
        uvm_config_db#(virtual uart_unified_intf)::set(null, "*", "uart_rx_vif_1", uart_rx_if[1]);
        uvm_config_db#(virtual uart_unified_intf)::set(null, "*", "uart_rx_vif_2", uart_rx_if[2]);

        uvm_config_db#(virtual uart_unified_intf)::set(null, "*", "uart_tx_vif_0", uart_tx_if[0]);
        uvm_config_db#(virtual uart_unified_intf)::set(null, "*", "uart_tx_vif_1", uart_tx_if[1]);
        uvm_config_db#(virtual uart_unified_intf)::set(null, "*", "uart_tx_vif_2", uart_tx_if[2]);

        uvm_config_db#(virtual mac_rx_if)::set(null, "*", "eth_rx_vif_0", eth_rx_if[0]);
        uvm_config_db#(virtual mac_rx_if)::set(null, "*", "eth_rx_vif_1", eth_rx_if[1]);
        uvm_config_db#(virtual mac_rx_if)::set(null, "*", "eth_rx_vif_2", eth_rx_if[2]);
        uvm_config_db#(virtual mac_rx_if)::set(null, "*", "eth_rx_vif_3", eth_rx_if[3]);

        uvm_config_db#(virtual eth_rx_if)::set(null, "*", "eth_rx_drv_vif_0", eth_rx_drv_if[0]);
        uvm_config_db#(virtual eth_rx_if)::set(null, "*", "eth_rx_drv_vif_1", eth_rx_drv_if[1]);
        uvm_config_db#(virtual eth_rx_if)::set(null, "*", "eth_rx_drv_vif_2", eth_rx_drv_if[2]);
        uvm_config_db#(virtual eth_rx_if)::set(null, "*", "eth_rx_drv_vif_3", eth_rx_drv_if[3]);

        uvm_config_db#(virtual eth_tx_if)::set(null, "*", "eth_tx_vif_0", eth_tx_if[0]);
        uvm_config_db#(virtual eth_tx_if)::set(null, "*", "eth_tx_vif_1", eth_tx_if[1]);
        uvm_config_db#(virtual eth_tx_if)::set(null, "*", "eth_tx_vif_2", eth_tx_if[2]);
        uvm_config_db#(virtual eth_tx_if)::set(null, "*", "eth_tx_vif_3", eth_tx_if[3]);
        uvm_config_db#(virtual eth_tx_if)::set(null, "*", "eth_tx_vif_4", eth_tx_if[4]);

        uvm_config_db#(virtual fault_inject_if)::set(null, "*", "fi_vif_0", fi_if[0]);
        uvm_config_db#(virtual fault_inject_if)::set(null, "*", "fi_vif_1", fi_if[1]);
        uvm_config_db#(virtual fault_inject_if)::set(null, "*", "fi_vif_2", fi_if[2]);
        uvm_config_db#(virtual fault_inject_if)::set(null, "*", "fi_vif_3", fi_if[3]);
        uvm_config_db#(virtual fault_inject_if)::set(null, "*", "fi_vif_4", fi_if[4]);

        run_test();
    end

    // =========================================================
    // 5. Dummy Interfaces
    // =========================================================
    eth_rx_fifo_if   dummy_eth_rx_fifo_if();
    eth_rx_app_if    dummy_eth_rx_app_if();
    eth_if           dummy_eth_if();
    fifo_intf        dummy_fifo_if();
    fifo_intf_uart   dummy_fifo_uart_if();
    uart_config_intf dummy_uart_config_if();
    uart_out_intf    dummy_uart_out_if();
    uart_rx_in_intf  dummy_uart_rx_in_if();
    uart_rx_out_intf dummy_uart_rx_out_if();
    uart_tx_intf     dummy_uart_tx_intf();
    out_intf         dummy_out_if();
    kwr_intf         dummy_kwr_if();
    krd_intf         dummy_krd_if();
    kst_intf         dummy_kst_if();

    // =========================================================
    // 6. RAW PHYSICAL PIN DEBUG MONITORS (Bypasses UVM entirely)
    // =========================================================
    
    // PROBE A: See exactly what the Backplane asserts to the EIU
    always @(posedge clk_20MHz) begin
        if (bkp_if.word_start_strobe) begin
            $display("[PIN_PROBE_BKP] @%0t: BKP %s -> Addr: %0d | Data: 0x%0h",
                     $time, bkp_if.bkp_data_dir ? "WRITE" : "READ", bkp_if.bkp_address, bkp_if.bkp_data);
        end
    end

    // PROBE B: RAW HEX DUMP OF TRANSMITTED ETH1 BYTES
    int eth1_tx_byte_count = 0;
    bit eth1_tx_active = 0;
    bit [3:0] eth1_lower_nibble;

    always @(posedge eth_tx_if[0].tx_c) begin
        if (eth_tx_if[0].tx_ctl) begin
            if (!eth1_tx_active) begin
                $display("[PIN_PROBE_ETH1] @%0t: MAC 1 STARTED TRANSMITTING", $time);
                eth1_tx_active = 1;
                eth1_tx_byte_count = 0;
            end
            eth1_lower_nibble <= eth_tx_if[0].txd;
        end else if (!eth_tx_if[0].tx_ctl && eth1_tx_active) begin
            $display("[PIN_PROBE_ETH1] @%0t: MAC 1 STOPPED TRANSMITTING. Total Physical Bytes: %0d", $time, eth1_tx_byte_count);
            eth1_tx_active = 0;
        end
    end

    always @(negedge eth_tx_if[0].tx_c) begin
        if (eth_tx_if[0].tx_ctl) begin
            eth1_tx_byte_count++;
            $display("[PIN_PROBE_ETH1_DATA] @%0t: Byte %0d = 0x%0h", 
                     $time, eth1_tx_byte_count, {eth_tx_if[0].txd, eth1_lower_nibble});
        end
    end

endmodule
`endif