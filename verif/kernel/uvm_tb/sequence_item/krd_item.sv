`ifndef KRD_ITEM_SV
`define KRD_ITEM_SV

class krd_item extends uvm_sequence_item;
    `uvm_object_utils(krd_item)

    // 1. Fake RX FIFO Data
    rand logic [8:0] rx_fifo_data_out_uart1, rx_fifo_data_out_uart2, rx_fifo_data_out_uart3;
    rand logic [7:0] rx_fifo_data_out_eth1, rx_fifo_data_out_eth2, rx_fifo_data_out_eth3, rx_fifo_data_out_eth4;
    
    // 2. Fake Counters
    rand logic [10:0] rx_valid_byte_count_uart1, rx_valid_byte_count_uart2, rx_valid_byte_count_uart3;
    rand logic [10:0] rx_eth_valid_bytes_eth1, rx_eth_valid_bytes_eth2, rx_eth_valid_bytes_eth3, rx_eth_valid_bytes_eth4;
    rand logic [10:0] rx_corrupt_byte_count_uart1, rx_corrupt_byte_count_uart2, rx_corrupt_byte_count_uart3;
    rand logic [10:0] rx_eth_corrupt_frame_count_eth1, rx_eth_corrupt_frame_count_eth2, rx_eth_corrupt_frame_count_eth3, rx_eth_corrupt_frame_count_eth4;
    
    // 3. Fake Status Flags
    rand logic tx_fifo_full_uart1, tx_fifo_full_uart2, tx_fifo_full_uart3;
    rand logic tx_fifo_full_eth1, tx_fifo_full_eth2, tx_fifo_full_eth3, tx_fifo_full_eth4, tx_fifo_full_eth_nrz;
    
    rand logic rx_fifo_full_uart1, rx_fifo_full_uart2, rx_fifo_full_uart3;
    rand logic rx_fifo_full_eth1, rx_fifo_full_eth2, rx_fifo_full_eth3, rx_fifo_full_eth4;
    
    rand logic tx_fifo_empty_uart1, tx_fifo_empty_uart2, tx_fifo_empty_uart3;
    rand logic tx_fifo_empty_eth1, tx_fifo_empty_eth2, tx_fifo_empty_eth3, tx_fifo_empty_eth4, tx_fifo_empty_eth_nrz;
    
    rand logic rx_fifo_empty_uart1, rx_fifo_empty_uart2, rx_fifo_empty_uart3;
    rand logic rx_fifo_empty_eth1, rx_fifo_empty_eth2, rx_fifo_empty_eth3, rx_fifo_empty_eth4;
    
    rand logic tx_data_sent_uart1, tx_data_sent_uart2, tx_data_sent_uart3;
    rand logic tx_data_sent_eth1, tx_data_sent_eth2, tx_data_sent_eth3, tx_data_sent_eth4, tx_data_sent_eth_nrz;

    function new(string name = "krd_item");
        super.new(name);
    endfunction
endclass

`endif