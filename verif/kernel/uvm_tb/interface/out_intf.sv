`ifndef OUT_INTF_SV
`define OUT_INTF_SV

interface out_intf(input logic clk, input logic rst_n);

    // Configuration Done Pulses
    logic config_done_pulse;
    logic config_done_uart;
    logic config_done_eth1;
    logic config_done_eth2;
    logic config_done_eth3;
    logic config_done_eth4;
    logic config_done_eth_nrz;

    // UART Configurations
    logic [31:0] baudrate_uart1, baudrate_uart2, baudrate_uart3;
    logic        parity_en_uart1, parity_en_uart2, parity_en_uart3;
    logic        parity_odd_even_uart1, parity_odd_even_uart2, parity_odd_even_uart3;
    logic [3:0]  data_width_uart1, data_width_uart2, data_width_uart3;

    // Ethernet Configurations (Standard MACs)
    logic [47:0] dest_mac_eth1, source_mac_eth1;
    logic [31:0] dest_ip_eth1, source_ip_eth1;
    logic [15:0] dest_port_eth1, source_port_eth1;
    logic [10:0] tx_payload_length_eth1;
    logic [47:0] dest_mac_eth2, source_mac_eth2;
    logic [31:0] dest_ip_eth2, source_ip_eth2;
    logic [15:0] dest_port_eth2, source_port_eth2;
    logic [10:0] tx_payload_length_eth2;
    logic [47:0] dest_mac_eth3, source_mac_eth3;
    logic [31:0] dest_ip_eth3, source_ip_eth3;
    logic [15:0] dest_port_eth3, source_port_eth3;
    logic [10:0] tx_payload_length_eth3;
    logic [47:0] dest_mac_eth4, source_mac_eth4;
    logic [31:0] dest_ip_eth4, source_ip_eth4;
    logic [15:0] dest_port_eth4, source_port_eth4;
    logic [10:0] tx_payload_length_eth4;

    // Ethernet Configuration (NRZ Specific)
    logic [47:0] dest_mac_eth_nrz, source_mac_eth_nrz;
    logic [31:0] dest_ip_eth_nrz, source_ip_eth_nrz;
    logic [15:0] dest_port_eth_nrz, source_port_eth_nrz;
    logic [10:0] tx_payload_length_eth_nrz;
    logic        tx_zero_endian_eth_nrz;
    logic [1:0]  tx_bpw_eth_nrz;
    logic [11:0] tx_sync_word1_eth_nrz;
    logic [11:0] tx_sync_word2_eth_nrz;

    // TX Data Sent Flags
    logic eth_tx_data_sent_eth1;
    logic eth_tx_data_sent_eth2;
    logic eth_tx_data_sent_eth3;
    logic eth_tx_data_sent_eth4;
    logic eth_tx_data_sent_eth_nrz;

    // Dedicated Phase-Lock Reset Wire
    logic bkp_prg_mode_force;

    // BACKDOOR CONFIGURATION TASK
    task drive_nrz_config(
        input logic [1:0]  bpw_val,
        input logic        ze_val,
        input logic [11:0] sync1_val,
        input logic [11:0] sync2_val,
        input logic [10:0] len_val
    );
        // Clean procedural drive. CONFIG_DUT is no longer fighting us!
        tx_bpw_eth_nrz            <= bpw_val;
        tx_zero_endian_eth_nrz    <= ze_val;
        tx_sync_word1_eth_nrz     <= sync1_val;
        tx_sync_word2_eth_nrz     <= sync2_val;
        tx_payload_length_eth_nrz <= len_val;
        
        // Fire the 200ns config pulse for the 20MHz domain to catch
        config_done_pulse <= 1'b1;
        config_done_eth_nrz <= 1'b1;
        #200ns; 
        config_done_pulse <= 1'b0;
        config_done_eth_nrz <= 1'b0;
    endtask

endinterface
`endif