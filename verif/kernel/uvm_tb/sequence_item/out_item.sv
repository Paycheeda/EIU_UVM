`ifndef OUT_ITEM_SV
`define OUT_ITEM_SV

class out_item extends uvm_sequence_item;

    // UART Configs
    bit [31:0] baudrate_uart [3];
    bit        parity_en_uart [3];
    bit        parity_odd_even_uart [3];
    bit        data_width_uart [3];

    // ETH Configs (Index 0-3 = ETH1-4, Index 4 = ETH NRZ)
    bit [47:0] dest_mac_eth [5];
    bit [47:0] source_mac_eth [5];
    bit [31:0] source_ip_eth [5];
    bit [31:0] dest_ip_eth [5];
    bit [15:0] source_port_eth [5];
    bit [15:0] dest_port_eth [5];
    bit [10:0] tx_payload_length_eth [5];

    // NRZ Specific
    bit        tx_zero_endian_eth_nrz;
    bit [1:0]  tx_bpw_eth_nrz;
    bit [11:0] tx_sync_word1_eth_nrz;
    bit [11:0] tx_sync_word2_eth_nrz;

    `uvm_object_utils_begin(out_item)
        // Note: Arrays require specific macros in UVM if we want automatic printing
        `uvm_field_sarray_int(baudrate_uart, UVM_ALL_ON)
        `uvm_field_sarray_int(dest_mac_eth, UVM_ALL_ON)
        `uvm_field_sarray_int(source_ip_eth, UVM_ALL_ON)
        // ... (We can print specific fields manually in the scoreboard to keep logs clean)
    `uvm_object_utils_end

    function new(string name = "out_item");
        super.new(name);
    endfunction

endclass

`endif