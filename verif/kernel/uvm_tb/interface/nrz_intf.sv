`ifndef NRZ_INTF_SV
`define NRZ_INTF_SV

interface nrz_intf(
    input logic clk_20mhz,  // Slow clock for NRZ Driver
    input logic clk_64mhz   // Fast system clock for NRZ Monitor
);

    // ==========================================
    // 20MHz Domain (Driven by Testbench)
    // ==========================================
    logic       data_in_nrz;
    
    // ==========================================
    // 64MHz Domain (Monitored from RTL)
    // ==========================================
    logic       fifo_wr_en;
    logic [7:0] fifo_data_in;
    logic       eth_tx_start_pulse;

endinterface

`endif