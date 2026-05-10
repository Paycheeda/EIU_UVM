`ifndef KRD_INTF_SV
`define KRD_INTF_SV

interface krd_intf(
    input logic clk, 
    input logic clk_uart, 
    input logic clk_eth1, 
    input logic clk_eth2, 
    input logic clk_eth3, 
    input logic clk_eth4, 
    input logic rst_n
);

    // 1. Physical FIFO Write Signals (Driven by UVM Agent)
    logic [8:0] rx_fifo_data_in_uart1, rx_fifo_data_in_uart2, rx_fifo_data_in_uart3;
    logic rx_fifo_wr_en_uart1, rx_fifo_wr_en_uart2, rx_fifo_wr_en_uart3;
    logic [7:0] rx_fifo_data_in_eth1, rx_fifo_data_in_eth2, rx_fifo_data_in_eth3, rx_fifo_data_in_eth4;
    logic rx_fifo_wr_en_eth1, rx_fifo_wr_en_eth2, rx_fifo_wr_en_eth3, rx_fifo_wr_en_eth4;

    // 2. Physical FIFO Read Signals (Wired to dual_port_FIFO outputs)
    wire [8:0] rx_fifo_data_out_uart1, rx_fifo_data_out_uart2, rx_fifo_data_out_uart3;
    wire [7:0] rx_fifo_data_out_eth1, rx_fifo_data_out_eth2, rx_fifo_data_out_eth3, rx_fifo_data_out_eth4;
    wire rx_fifo_empty_uart1, rx_fifo_empty_uart2, rx_fifo_empty_uart3;
    wire rx_fifo_empty_eth1, rx_fifo_empty_eth2, rx_fifo_empty_eth3, rx_fifo_empty_eth4;

    // 3. Read Enable (Driven by kernel_read RTL)
    wire rx_fifo_rd_en_uart1, rx_fifo_rd_en_uart2, rx_fifo_rd_en_uart3;
    wire rx_fifo_rd_en_eth1, rx_fifo_rd_en_eth2, rx_fifo_rd_en_eth3, rx_fifo_rd_en_eth4;

    // 4. Fake Counters & Flags
    logic [10:0] rx_valid_byte_count_uart1, rx_valid_byte_count_uart2, rx_valid_byte_count_uart3;
    logic [10:0] rx_eth_valid_bytes_eth1, rx_eth_valid_bytes_eth2, rx_eth_valid_bytes_eth3, rx_eth_valid_bytes_eth4;
    logic [10:0] rx_corrupt_byte_count_uart1, rx_corrupt_byte_count_uart2, rx_corrupt_byte_count_uart3;
    logic [10:0] rx_eth_corrupt_frame_count_eth1, rx_eth_corrupt_frame_count_eth2, rx_eth_corrupt_frame_count_eth3, rx_eth_corrupt_frame_count_eth4;
    
    logic tx_fifo_full_uart1, tx_fifo_full_uart2, tx_fifo_full_uart3;
    logic tx_fifo_full_eth1, tx_fifo_full_eth2, tx_fifo_full_eth3, tx_fifo_full_eth4, tx_fifo_full_eth_nrz;
    
    logic rx_fifo_full_uart1, rx_fifo_full_uart2, rx_fifo_full_uart3;
    logic rx_fifo_full_eth1, rx_fifo_full_eth2, rx_fifo_full_eth3, rx_fifo_full_eth4;
    
    logic tx_fifo_empty_uart1, tx_fifo_empty_uart2, tx_fifo_empty_uart3;
    logic tx_fifo_empty_eth1, tx_fifo_empty_eth2, tx_fifo_empty_eth3, tx_fifo_empty_eth4, tx_fifo_empty_eth_nrz;
    
    logic tx_data_sent_uart1, tx_data_sent_uart2, tx_data_sent_uart3;
    logic tx_data_sent_eth1, tx_data_sent_eth2, tx_data_sent_eth3, tx_data_sent_eth4, tx_data_sent_eth_nrz;

endinterface

`endif