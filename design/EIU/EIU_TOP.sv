module EIU_TOP#(
                
            parameter integer PARAM_MAX_DATA_WIDTH_ETH      = 8,
            parameter         PARAM_FIFO_SIZE_ETH_TX        = "18Kb",
            parameter         PARAM_FIFO_SIZE_ETH_RX        = "36Kb",

            parameter integer PARAM_MAX_DATA_WIDTH_UART1    = 9,
            parameter         PARAM_FIFO_SIZE_UART1_TX      = "18Kb",
            parameter         PARAM_FIFO_SIZE_UART1_RX      = "18Kb",

            parameter integer PARAM_MAX_DATA_WIDTH_UART2    = 9,
            parameter         PARAM_FIFO_SIZE_UART2_TX      = "18Kb",
            parameter         PARAM_FIFO_SIZE_UART2_RX      = "18Kb",

            parameter integer PARAM_MAX_DATA_WIDTH_UART3    = 9,
            parameter         PARAM_FIFO_SIZE_UART3_TX      = "18Kb",
            parameter         PARAM_FIFO_SIZE_UART3_RX      = "18Kb",

            parameter integer RXD0_IDELAY_VALUE_ETH1        = 26,
            parameter integer RXD1_IDELAY_VALUE_ETH1        = 26,
            parameter integer RXD2_IDELAY_VALUE_ETH1        = 26,
            parameter integer RXD3_IDELAY_VALUE_ETH1        = 26,
            parameter integer RXCTL_IDELAY_VALUE_ETH1       = 26,

            parameter integer RXD0_IDELAY_VALUE_ETH2        = 26,
            parameter integer RXD1_IDELAY_VALUE_ETH2        = 26,
            parameter integer RXD2_IDELAY_VALUE_ETH2        = 26,
            parameter integer RXD3_IDELAY_VALUE_ETH2        = 26,
            parameter integer RXCTL_IDELAY_VALUE_ETH2       = 26,

            parameter integer RXD0_IDELAY_VALUE_ETH3        = 26,
            parameter integer RXD1_IDELAY_VALUE_ETH3        = 26,
            parameter integer RXD2_IDELAY_VALUE_ETH3        = 26,
            parameter integer RXD3_IDELAY_VALUE_ETH3        = 26,
            parameter integer RXCTL_IDELAY_VALUE_ETH3       = 26,

            parameter integer RXD0_IDELAY_VALUE_ETH4        = 28,
            parameter integer RXD1_IDELAY_VALUE_ETH4        = 28,
            parameter integer RXD2_IDELAY_VALUE_ETH4        = 28,
            parameter integer RXD3_IDELAY_VALUE_ETH4        = 28,
            parameter integer RXCTL_IDELAY_VALUE_ETH4       = 28

)(

        input               clk_64MHz,
        input               clk_25MHz,//

        input               clk_125MHz_eth1,
        input               clk_125MHz_eth2,
        input               clk_125MHz_eth3,
        input               clk_125MHz_eth4,
        input               clk_125MHz_eth_nrz,
        
        input               clk_uart_55_296MHz,
        
        // UART1
        input               uart1_rx,
        output              uart1_tx,

        // UART2
        input               uart2_rx,
        output              uart2_tx,
        
        // UART3
        input               uart3_rx,
        output              uart3_tx,

        // ETH1 RGMII
        input               rx_c_eth1,
        input  [3:0]        rxd_eth1,
        input               rx_ctl_eth1,
        output [3:0]        txd_eth1,
        output              tx_ctl_eth1,
        output              tx_c_eth1,

        // ETH2 RGMII
        input               rx_c_eth2,
        input  [3:0]        rxd_eth2,
        input               rx_ctl_eth2,
        output [3:0]        txd_eth2,
        output              tx_ctl_eth2,
        output              tx_c_eth2,

        // ETH3 RGMII
        input               rx_c_eth3,
        input  [3:0]        rxd_eth3,
        input               rx_ctl_eth3,
        output [3:0]        txd_eth3,
        output              tx_ctl_eth3,
        output              tx_c_eth3,

        // ETH4 RGMII
        input               rx_c_eth4,
        input  [3:0]        rxd_eth4,
        input               rx_ctl_eth4,
        output [3:0]        txd_eth4,
        output              tx_ctl_eth4,
        output              tx_c_eth4,

        // ETH_NRZ 
        output [3:0]        txd_eth_nrz,
        output              tx_ctl_eth_nrz,
        output              tx_c_eth_nrz,

        // NRZ source inputs
        input               clk_20MHz,
        input               data_in_nrz,

        input               rst_n,

        input               bkp_prg_mode_on,
        input               bkp_config_wr_pulse,
        input  [3:0]        bkp_card_id,
        input  [3:0]        fpga_card_id,
        input               bkp_data_dir,
        input  [5:0]        bkp_address,
        inout  [11:0]       bkp_data_bus,
        input               word_start_strobe_pulse,
        
        // General purpose LEDs
        output [7:0]        LED,//
        
        // MDC ETH1
        output              mdc_eth1,//
        inout               mdio_eth1,//
        
        // MDC ETH2
        output              mdc_eth2,//
        inout               mdio_eth2,//
        
        // MDC ETH3
        output              mdc_eth3,//
        inout               mdio_eth3,//
        
        // MDC ETH4
        output              mdc_eth4,//
        inout               mdio_eth4,//
        
        // MDC ETH_NRZ
        output              mdc_eth_nrz,//
        inout               mdio_eth_nrz//

);

// =====================================================
// ETH RX clock buffers
// =====================================================

wire rx_clk_eth1_buf;
wire rx_clk_eth2_buf;
wire rx_clk_eth3_buf;
wire rx_clk_eth4_buf;

BUFG u_bufg_rx_clk_eth1 (
    .I(rx_c_eth1),
    .O(rx_clk_eth1_buf)
);

BUFG u_bufg_rx_clk_eth2 (
    .I(rx_c_eth2),
    .O(rx_clk_eth2_buf)
);

BUFG u_bufg_rx_clk_eth3 (
    .I(rx_c_eth3),
    .O(rx_clk_eth3_buf)
);

BUFG u_bufg_rx_clk_eth4 (
    .I(rx_c_eth4),
    .O(rx_clk_eth4_buf)
);



// =====================================================
// ETH 125 MHz clock buffers
// =====================================================

wire clk_125MHz_eth1_buf;
wire clk_125MHz_eth2_buf;
wire clk_125MHz_eth3_buf;
wire clk_125MHz_eth4_buf;
wire clk_125MHz_eth_nrz_buf;
wire clk_20MHz_buf;
wire clk_uart_55_296MHz_buf;
wire clk_25MHz_buf;
wire clk_64MHz_buf;

BUFG u_bufg_clk_125MHz_eth1 (
    .I(clk_125MHz_eth1),
    .O(clk_125MHz_eth1_buf)
);

BUFG u_bufg_clk_125MHz_eth2 (
    .I(clk_125MHz_eth2),
    .O(clk_125MHz_eth2_buf)
);

BUFG u_bufg_clk_125MHz_eth3 (
    .I(clk_125MHz_eth3),
    .O(clk_125MHz_eth3_buf)
);

BUFG u_bufg_clk_125MHz_eth4 (
    .I(clk_125MHz_eth4),
    .O(clk_125MHz_eth4_buf)
);

BUFG u_bufg_clk_125MHz_eth_nrz (
    .I(clk_125MHz_eth_nrz),
    .O(clk_125MHz_eth_nrz_buf)
);

BUFG u_bufg_clk_20MHz (
    .I(clk_20MHz),
    .O(clk_20MHz_buf)
);

BUFG u_bufg_clk_uart_55_296MHz (
    .I(clk_uart_55_296MHz),
    .O(clk_uart_55_296MHz_buf)
);

BUFG u_bufg_clk_25MHz (
    .I(clk_25MHz),
    .O(clk_25MHz_buf)
);

BUFG u_bufg_clk_64MHz (
    .I(clk_64MHz),
    .O(clk_64MHz_buf)
);

// =====================================================
// SHARED 200 MHz IDELAY REFERENCE CLOCK
// One stable 200 MHz refclk can feed IDELAYCTRLs for ETH1/2/3/4/ETH_NRZ.
// It does not need to be phase-related to any RGMII clock.
// =====================================================

wire idelay_refclk_200MHz;
wire idelay_refclk_locked;

clk_wiz_125_to_200 u_clk_wiz_125_to_200 (
    .clk_out_200MHz (idelay_refclk_200MHz),
    .resetn         (rst_n),
    .locked         (idelay_refclk_locked),
    .clk_125MHz     (clk_125MHz_eth1_buf)
);

// =====================================================
// UART1 CONFIG WIRES FROM KERNEL
// =====================================================

wire        config_done_uart1;

wire [31:0] baudrate_uart1;
wire        parity_en_uart1;
wire        parity_odd_even_uart1;
wire [3:0]  data_width_uart1;

// =====================================================
// UART2 CONFIG WIRES FROM KERNEL
// =====================================================
wire        config_done_uart2;

wire [31:0] baudrate_uart2;
wire        parity_en_uart2;
wire        parity_odd_even_uart2;
wire [3:0]  data_width_uart2;

// =====================================================
// UART3 CONFIG WIRES FROM KERNEL
// =====================================================
wire        config_done_uart3;

wire [31:0] baudrate_uart3;
wire        parity_en_uart3;
wire        parity_odd_even_uart3;
wire [3:0]  data_width_uart3;


// =====================================================
// UART1 TX WIRES
// =====================================================

wire                                        tx_fifo_wr_en_uart1;
wire [PARAM_MAX_DATA_WIDTH_UART1 - 1:0]     tx_fifo_data_in_uart1;
wire                                        tx_fifo_rd_en_uart1;
wire [PARAM_MAX_DATA_WIDTH_UART1 - 1:0]     tx_fifo_data_out_uart1;
wire                                        tx_fifo_full_uart1;
wire                                        tx_fifo_empty_uart1;

wire                                        tx_acq_start_uart1;
wire                                        uart_tx_busy_uart1;
wire                                        tx_acq_done_uart1;

// =====================================================
// UART2 TX WIRES
// =====================================================

wire                                        tx_fifo_wr_en_uart2;
wire [PARAM_MAX_DATA_WIDTH_UART2 - 1:0]     tx_fifo_data_in_uart2;
wire                                        tx_fifo_rd_en_uart2;
wire [PARAM_MAX_DATA_WIDTH_UART2 - 1:0]     tx_fifo_data_out_uart2;
wire                                        tx_fifo_full_uart2;
wire                                        tx_fifo_empty_uart2;

wire                                        tx_acq_start_uart2;
wire                                        uart_tx_busy_uart2;
wire                                        tx_acq_done_uart2;

// =====================================================
// UART3 TX WIRES
// =====================================================

wire                                        tx_fifo_wr_en_uart3;
wire [PARAM_MAX_DATA_WIDTH_UART3 - 1:0]     tx_fifo_data_in_uart3;
wire                                        tx_fifo_rd_en_uart3;
wire [PARAM_MAX_DATA_WIDTH_UART3 - 1:0]     tx_fifo_data_out_uart3;
wire                                        tx_fifo_full_uart3;
wire                                        tx_fifo_empty_uart3;

wire                                        tx_acq_start_uart3;
wire                                        uart_tx_busy_uart3;
wire                                        tx_acq_done_uart3;


// =====================================================
// UART1 RX WIRES
// =====================================================

wire                                        rx_fifo_wr_en_uart1;
wire [PARAM_MAX_DATA_WIDTH_UART1 - 1:0]     rx_fifo_data_in_uart1;
wire                                        rx_fifo_rd_en_uart1;
wire [PARAM_MAX_DATA_WIDTH_UART1 - 1:0]     rx_fifo_data_out_uart1;
wire                                        rx_fifo_full_uart1;
wire                                        rx_fifo_empty_uart1;

wire                                        uart_rx_busy_uart1;
wire [11:0]                                 uart1_rx_valid_count;
wire [11:0]                                 uart1_rx_corrupt_count;
wire [11:0]                                 count_uart1;

// =====================================================
// UART2 RX WIRES
// =====================================================

wire                                        rx_fifo_wr_en_uart2;
wire [PARAM_MAX_DATA_WIDTH_UART2 - 1:0]     rx_fifo_data_in_uart2;
wire                                        rx_fifo_rd_en_uart2;
wire [PARAM_MAX_DATA_WIDTH_UART2 - 1:0]     rx_fifo_data_out_uart2;
wire                                        rx_fifo_full_uart2;
wire                                        rx_fifo_empty_uart2;

wire                                        uart_rx_busy_uart2;
wire [11:0]                                 uart2_rx_valid_count;
wire [11:0]                                 uart2_rx_corrupt_count;
wire [11:0]                                 count_uart2;

// =====================================================
// UART3 RX WIRES
// =====================================================

wire                                        rx_fifo_wr_en_uart3;
wire [PARAM_MAX_DATA_WIDTH_UART3 - 1:0]     rx_fifo_data_in_uart3;
wire                                        rx_fifo_rd_en_uart3;
wire [PARAM_MAX_DATA_WIDTH_UART3 - 1:0]     rx_fifo_data_out_uart3;
wire                                        rx_fifo_full_uart3;
wire                                        rx_fifo_empty_uart3;

wire                                        uart_rx_busy_uart3;
wire [11:0]                                 uart3_rx_valid_count;
wire [11:0]                                 uart3_rx_corrupt_count;
wire [11:0]                                 count_uart3;

// =====================================================
// ETH1 RX WIRES
// =====================================================

wire                                rx_fifo_wr_en_eth1;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] rx_fifo_data_in_eth1;
wire                                rx_fifo_rst_n_eth1;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] rx_fifo_data_out_eth1;
wire                                rx_fifo_full_eth1;
wire                                rx_fifo_empty_eth1;
wire                                rx_fifo_rd_en_eth1;

wire [11:0]                         rx_eth_corrupt_frame_count_eth1;
wire                                eth_rx_data_valid_eth1;
wire [11:0]                         rx_eth_valid_bytes_eth1;
wire [11:0]                         count_eth1;

// =====================================================
// ETH1 TX WIRES
// =====================================================

wire                                tx_fifo_wr_en_eth1;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_in_eth1;
wire                                tx_fifo_rd_en_eth1;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_out_eth1;
wire                                tx_fifo_full_eth1;
wire                                tx_fifo_empty_eth1;

wire                                eth_tx_data_sent_eth1;
wire                                eth_tx_start_pulse_eth1;


// =====================================================
// ETH1 CONFIG WIRES FROM KERNEL
// =====================================================

wire                                config_done_eth1;

wire [47:0]                         dest_mac_eth1;
wire [47:0]                         source_mac_eth1;
wire [31:0]                         source_ip_eth1;
wire [31:0]                         dest_ip_eth1;
wire [15:0]                         source_port_eth1;
wire [15:0]                         dest_port_eth1;
wire [10:0]                         tx_payload_length_eth1;

// =====================================================
// ETH2 RX WIRES
// =====================================================

wire                                rx_fifo_wr_en_eth2;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] rx_fifo_data_in_eth2;
wire                                rx_fifo_rst_n_eth2;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] rx_fifo_data_out_eth2;
wire                                rx_fifo_full_eth2;
wire                                rx_fifo_empty_eth2;
wire                                rx_fifo_rd_en_eth2;

wire [11:0]                         rx_eth_corrupt_frame_count_eth2;
wire                                eth_rx_data_valid_eth2;
wire [11:0]                         rx_eth_valid_bytes_eth2;
wire [11:0]                         count_eth2;

// =====================================================
// ETH2 TX WIRES
// =====================================================

wire                                tx_fifo_wr_en_eth2;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_in_eth2;
wire                                tx_fifo_rd_en_eth2;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_out_eth2;
wire                                tx_fifo_full_eth2;
wire                                tx_fifo_empty_eth2;

wire                                eth_tx_data_sent_eth2;
wire                                eth_tx_start_pulse_eth2;


// =====================================================
// ETH2 CONFIG WIRES FROM KERNEL
// =====================================================

wire                                config_done_eth2;

wire [47:0]                         dest_mac_eth2;
wire [47:0]                         source_mac_eth2;
wire [31:0]                         source_ip_eth2;
wire [31:0]                         dest_ip_eth2;
wire [15:0]                         source_port_eth2;
wire [15:0]                         dest_port_eth2;
wire [10:0]                         tx_payload_length_eth2;

// =====================================================
// ETH3 RX WIRES
// =====================================================

wire                                rx_fifo_wr_en_eth3;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] rx_fifo_data_in_eth3;
wire                                rx_fifo_rst_n_eth3;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] rx_fifo_data_out_eth3;
wire                                rx_fifo_full_eth3;
wire                                rx_fifo_empty_eth3;
wire                                rx_fifo_rd_en_eth3;

wire [11:0]                         rx_eth_corrupt_frame_count_eth3;
wire                                eth_rx_data_valid_eth3;
wire [11:0]                         rx_eth_valid_bytes_eth3;
wire [11:0]                         count_eth3;

// =====================================================
// ETH3 TX WIRES
// =====================================================

wire                                tx_fifo_wr_en_eth3;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_in_eth3;
wire                                tx_fifo_rd_en_eth3;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_out_eth3;
wire                                tx_fifo_full_eth3;
wire                                tx_fifo_empty_eth3;

wire                                eth_tx_data_sent_eth3;
wire                                eth_tx_start_pulse_eth3;


// =====================================================
// ETH3 CONFIG WIRES FROM KERNEL
// =====================================================

wire                                config_done_eth3;

wire [47:0]                         dest_mac_eth3;
wire [47:0]                         source_mac_eth3;
wire [31:0]                         source_ip_eth3;
wire [31:0]                         dest_ip_eth3;
wire [15:0]                         source_port_eth3;
wire [15:0]                         dest_port_eth3;
wire [10:0]                         tx_payload_length_eth3;

// =====================================================
// ETH4 RX WIRES
// =====================================================

wire                                rx_fifo_wr_en_eth4;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] rx_fifo_data_in_eth4;
wire                                rx_fifo_rst_n_eth4;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] rx_fifo_data_out_eth4;
wire                                rx_fifo_full_eth4;
wire                                rx_fifo_empty_eth4;
wire                                rx_fifo_rd_en_eth4;

wire [11:0]                         rx_eth_corrupt_frame_count_eth4;
wire                                eth_rx_data_valid_eth4;
wire [11:0]                         rx_eth_valid_bytes_eth4;
wire [11:0]                         count_eth4;

// =====================================================
// ETH4 TX WIRES
// =====================================================

wire                                tx_fifo_wr_en_eth4;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_in_eth4;
wire                                tx_fifo_rd_en_eth4;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_out_eth4;
wire                                tx_fifo_full_eth4;
wire                                tx_fifo_empty_eth4;

wire                                eth_tx_data_sent_eth4;
wire                                eth_tx_start_pulse_eth4;


// =====================================================
// ETH4 CONFIG WIRES FROM KERNEL
// =====================================================

wire                                config_done_eth4;

wire [47:0]                         dest_mac_eth4;
wire [47:0]                         source_mac_eth4;
wire [31:0]                         source_ip_eth4;
wire [31:0]                         dest_ip_eth4;
wire [15:0]                         source_port_eth4;
wire [15:0]                         dest_port_eth4;
wire [10:0]                         tx_payload_length_eth4;


// =====================================================
// ETH_NRZ / ETH5 RX WIRES
// =====================================================

wire                                rx_fifo_wr_en_eth_nrz;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] rx_fifo_data_in_eth_nrz;
wire                                rx_fifo_rst_n_eth_nrz;

wire [11:0]                         rx_eth_corrupt_frame_count_eth_nrz;
wire                                eth_rx_data_valid_eth_nrz;
wire [11:0]                         rx_eth_valid_bytes_eth_nrz;
wire [11:0]                         count_eth_nrz;


// =====================================================
// ETH_NRZ / ETH5 TX WIRES
// =====================================================

wire                                tx_fifo_wr_en_eth_nrz;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_in_eth_nrz;
wire                                tx_fifo_rd_en_eth_nrz;
wire [PARAM_MAX_DATA_WIDTH_ETH-1:0] tx_fifo_data_out_eth_nrz;
wire                                tx_fifo_full_eth_nrz;
wire                                tx_fifo_empty_eth_nrz;

wire                                eth_tx_data_sent_eth_nrz;
wire                                eth_tx_start_pulse_eth_nrz;


// =====================================================
// ETH_NRZ / ETH5 CONFIG WIRES FROM KERNEL
// =====================================================

wire                                config_done_eth_nrz;

wire [47:0]                         dest_mac_eth_nrz;
wire [47:0]                         source_mac_eth_nrz;
wire [31:0]                         source_ip_eth_nrz;
wire [31:0]                         dest_ip_eth_nrz;
wire [15:0]                         source_port_eth_nrz;
wire [15:0]                         dest_port_eth_nrz;
wire [10:0]                         tx_payload_length_eth_nrz;

// ============================================================
// MDIO configuration status wires
// ============================================================

wire mdio_config_busy_any;

wire mdio_all_config_done;
wire mdio_all_config_done_pulse;
wire mdio_all_config_success;
wire mdio_all_config_failed;
wire mdio_any_config_error;

wire [4:0] mdio_phy_config_busy;
wire [4:0] mdio_phy_config_done;
wire [4:0] mdio_phy_config_success;
wire [4:0] mdio_phy_config_error;

wire [7:0] mdio_status_led;

assign LED = mdio_status_led[7:0];

// ============================================================
// MDC / MDIO top-level PHY configuration block
// ============================================================

mdio_top #(
    .PHY_ADDR_ETH1      (5'd1),
    .PHY_ADDR_ETH2      (5'd1),
    .PHY_ADDR_ETH3      (5'd1),
    .PHY_ADDR_ETH4      (5'd1),
    .PHY_ADDR_ETH5      (5'd1),

    .POLL_MAX_ATTEMPTS  (16'd65535)
) u_mdio_top (
    .clk                    (clk_25MHz_buf),
    .rst_n                  (rst_n),

    .config_busy_any        (mdio_config_busy_any),

    .all_config_done        (mdio_all_config_done),
    .all_config_done_pulse  (mdio_all_config_done_pulse),
    .all_config_success     (mdio_all_config_success),
    .all_config_failed      (mdio_all_config_failed),
    .any_config_error       (mdio_any_config_error),

    .phy_config_busy        (mdio_phy_config_busy),
    .phy_config_done        (mdio_phy_config_done),
    .phy_config_success     (mdio_phy_config_success),
    .phy_config_error       (mdio_phy_config_error),

    .mdio_status_led        (mdio_status_led),

    .mdc_eth1               (mdc_eth1),
    .mdio_eth1              (mdio_eth1),

    .mdc_eth2               (mdc_eth2),
    .mdio_eth2              (mdio_eth2),

    .mdc_eth3               (mdc_eth3),
    .mdio_eth3              (mdio_eth3),

    .mdc_eth4               (mdc_eth4),
    .mdio_eth4              (mdio_eth4),

    .mdc_eth5               (mdc_eth_nrz),
    .mdio_eth5              (mdio_eth_nrz)
);

// =====================================================
// UART1 MODULE
// =====================================================

uart #(
    .PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART1)
) u_uart1 (
    .clk                    (clk_uart_55_296MHz_buf),
    .rst_n                  (rst_n),

    .baudrate               (baudrate_uart1),
    .parity_en              (parity_en_uart1),
    .parity_odd_even        (parity_odd_even_uart1),
    .data_width             (data_width_uart1),
    .config_done_pulse      (config_done_uart1),

    .rx                     (uart1_rx),
    .tx                     (uart1_tx),

    .tx_fifo_rd_en          (tx_fifo_rd_en_uart1),
    .tx_fifo_data           (tx_fifo_data_out_uart1),

    .rx_fifo_wr_en          (rx_fifo_wr_en_uart1),
    .rx_fifo_data           (rx_fifo_data_in_uart1),

    .tx_acq_start           (tx_acq_start_uart1),
    .uart_tx_busy           (uart_tx_busy_uart1),
    .tx_acq_done            (tx_acq_done_uart1),

    .rx_corrupt_byte_count  (uart1_rx_corrupt_count),
    .uart_rx_busy           (uart_rx_busy_uart1),
    .rx_valid_byte_count    (uart1_rx_valid_count),
    
    .count_uart             (count_uart1)
);

// =====================================================
// UART2 MODULE
// =====================================================

uart #(
    .PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART2)
) u_uart2 (
    .clk                    (clk_uart_55_296MHz_buf),
    .rst_n                  (rst_n),

    .baudrate               (baudrate_uart2),
    .parity_en              (parity_en_uart2),
    .parity_odd_even        (parity_odd_even_uart2),
    .data_width             (data_width_uart2),
    .config_done_pulse      (config_done_uart2),

    .rx                     (uart2_rx),
    .tx                     (uart2_tx),

    .tx_fifo_rd_en          (tx_fifo_rd_en_uart2),
    .tx_fifo_data           (tx_fifo_data_out_uart2),

    .rx_fifo_wr_en          (rx_fifo_wr_en_uart2),
    .rx_fifo_data           (rx_fifo_data_in_uart2),

    .tx_acq_start           (tx_acq_start_uart2),
    .uart_tx_busy           (uart_tx_busy_uart2),
    .tx_acq_done            (tx_acq_done_uart2),

    .rx_corrupt_byte_count  (uart2_rx_corrupt_count),
    .uart_rx_busy           (uart_rx_busy_uart2),
    .rx_valid_byte_count    (uart2_rx_valid_count),
    
    .count_uart             (count_uart2)
);


// =====================================================
// UART3 MODULE
// =====================================================

uart #(
    .PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART3)
) u_uart3 (
    .clk                    (clk_uart_55_296MHz_buf),
    .rst_n                  (rst_n),

    .baudrate               (baudrate_uart3),
    .parity_en              (parity_en_uart3),
    .parity_odd_even        (parity_odd_even_uart3),
    .data_width             (data_width_uart3),
    .config_done_pulse      (config_done_uart3),

    .rx                     (uart3_rx),
    .tx                     (uart3_tx),

    .tx_fifo_rd_en          (tx_fifo_rd_en_uart3),
    .tx_fifo_data           (tx_fifo_data_out_uart3),

    .rx_fifo_wr_en          (rx_fifo_wr_en_uart3),
    .rx_fifo_data           (rx_fifo_data_in_uart3),

    .tx_acq_start           (tx_acq_start_uart3),
    .uart_tx_busy           (uart_tx_busy_uart3),
    .tx_acq_done            (tx_acq_done_uart3),

    .rx_corrupt_byte_count  (uart3_rx_corrupt_count),
    .uart_rx_busy           (uart_rx_busy_uart3),
    .rx_valid_byte_count    (uart3_rx_valid_count),
    
    .count_uart             (count_uart3)
);

// =====================================================
// ETH1 RX SHIFTED CLOCK AND RESET
// =====================================================

wire rx1_clk_shifted;
wire rx1_clk_shifted_locked;

wire eth1_rx_ready; 
assign eth1_rx_ready = rx1_clk_shifted_locked & idelay_refclk_locked;

wire eth1_rx_rst_n;

clk_wiz_rgmii_rx_shift u_clk_wiz_rgmii_rx1_shift (
    .clk_out_shifted (rx1_clk_shifted),
    .resetn          (rst_n),
    .locked          (rx1_clk_shifted_locked),
    .clk_in          (rx_clk_eth1_buf)
);

reset_synchronizer u_eth1_rx_reset_synchronizer (
    .clk        (rx1_clk_shifted),
    .rst_n      (rst_n),
    .clk_locked (eth1_rx_ready),
    .rst_n_sync (eth1_rx_rst_n)
);

// =====================================================
// ETH2 RX SHIFTED CLOCK AND RESET
// =====================================================

wire rx2_clk_shifted;
wire rx2_clk_shifted_locked;

wire eth2_rx_ready; 
assign eth2_rx_ready = rx2_clk_shifted_locked & idelay_refclk_locked;

wire eth2_rx_rst_n;

clk_wiz_rgmii_rx_shift u_clk_wiz_rgmii_rx2_shift (
    .clk_out_shifted (rx2_clk_shifted),
    .resetn          (rst_n),
    .locked          (rx2_clk_shifted_locked),
    .clk_in          (rx_clk_eth2_buf)
);

reset_synchronizer u_eth2_rx_reset_synchronizer (
    .clk        (rx2_clk_shifted),
    .rst_n      (rst_n),
    .clk_locked (eth2_rx_ready),
    .rst_n_sync (eth2_rx_rst_n)
);

// =====================================================
// ETH3 RX SHIFTED CLOCK AND RESET
// =====================================================

wire rx3_clk_shifted;
wire rx3_clk_shifted_locked;

wire eth3_rx_ready; 
assign eth3_rx_ready = rx3_clk_shifted_locked & idelay_refclk_locked;

wire eth3_rx_rst_n;

clk_wiz_rgmii_rx_shift u_clk_wiz_rgmii_rx3_shift (
    .clk_out_shifted (rx3_clk_shifted),
    .resetn          (rst_n),
    .locked          (rx3_clk_shifted_locked),
    .clk_in          (rx_clk_eth3_buf)
);

reset_synchronizer u_eth3_rx_reset_synchronizer (
    .clk        (rx3_clk_shifted),
    .rst_n      (rst_n),
    .clk_locked (eth3_rx_ready),
    .rst_n_sync (eth3_rx_rst_n)
);

// =====================================================
// ETH4 RX SHIFTED CLOCK AND RESET
// =====================================================

wire rx4_clk_shifted;
wire rx4_clk_shifted_locked;

wire eth4_rx_ready; 
assign eth4_rx_ready = rx4_clk_shifted_locked & idelay_refclk_locked;

wire eth4_rx_rst_n;

clk_wiz_rgmii_rx_shift u_clk_wiz_rgmii_rx4_shift (
    .clk_out_shifted (rx4_clk_shifted),
    .resetn          (rst_n),
    .locked          (rx4_clk_shifted_locked),
    .clk_in          (rx_clk_eth4_buf)
);

reset_synchronizer u_eth4_rx_reset_synchronizer (
    .clk        (rx4_clk_shifted),
    .rst_n      (rst_n),
    .clk_locked (eth4_rx_ready),
    .rst_n_sync (eth4_rx_rst_n)
);

// =====================================================
// ETH1 MODULE
// =====================================================

eth #(
    .IODELAY_GROUP_NAME("ETH1_IDELAY_GROUP"),
    .RXD0_IDELAY_VALUE  (RXD0_IDELAY_VALUE_ETH1),
    .RXD1_IDELAY_VALUE  (RXD1_IDELAY_VALUE_ETH1),
    .RXD2_IDELAY_VALUE  (RXD2_IDELAY_VALUE_ETH1),
    .RXD3_IDELAY_VALUE  (RXD3_IDELAY_VALUE_ETH1),
    .RXCTL_IDELAY_VALUE (RXCTL_IDELAY_VALUE_ETH1)
) u_eth1 (
        .tx_clk                     (clk_125MHz_eth1_buf),
        .rx_clk                     (rx1_clk_shifted),
        .rst_n                      (rst_n),
        .eth_rx_rst_n               (eth1_rx_rst_n),

        .idelay_refclk_200MHz       (idelay_refclk_200MHz),
        .idelay_refclk_locked       (idelay_refclk_locked),

        .rxd                        (rxd_eth1),
        .rx_ctl                     (rx_ctl_eth1),

        .rx_fifo_wr_en              (rx_fifo_wr_en_eth1),
        .rx_fifo_data_in            (rx_fifo_data_in_eth1),
        .rx_fifo_rst_n              (rx_fifo_rst_n_eth1),

        .rx_eth_corrupt_frame_count (rx_eth_corrupt_frame_count_eth1),
        .eth_rx_data_valid          (eth_rx_data_valid_eth1),
        .rx_eth_valid_bytes         (rx_eth_valid_bytes_eth1),

        .txd                        (txd_eth1),
        .tx_ctl                     (tx_ctl_eth1),
        .tx_c                       (tx_c_eth1),

        .config_done_pulse          (config_done_eth1),

        .dest_mac                   (dest_mac_eth1),
        .source_mac                 (source_mac_eth1),
        .source_ip                  (source_ip_eth1),
        .dest_ip                    (dest_ip_eth1),
        .source_port                (source_port_eth1),
        .dest_port                  (dest_port_eth1),
        .tx_payload_length          (tx_payload_length_eth1),

        .eth_tx_start_pulse         (eth_tx_start_pulse_eth1),

        .tx_fifo_rd_en              (tx_fifo_rd_en_eth1),
        .tx_fifo_empty              (tx_fifo_empty_eth1),
        .tx_fifo_data_out           (tx_fifo_data_out_eth1),

        .eth_tx_data_sent           (eth_tx_data_sent_eth1),
        
        .count_eth                  (count_eth1)
);

// =====================================================
// ETH2 MODULE
// =====================================================

eth #(
    .IODELAY_GROUP_NAME("ETH2_IDELAY_GROUP"),
    .RXD0_IDELAY_VALUE  (RXD0_IDELAY_VALUE_ETH2),
    .RXD1_IDELAY_VALUE  (RXD1_IDELAY_VALUE_ETH2),
    .RXD2_IDELAY_VALUE  (RXD2_IDELAY_VALUE_ETH2),
    .RXD3_IDELAY_VALUE  (RXD3_IDELAY_VALUE_ETH2),
    .RXCTL_IDELAY_VALUE (RXCTL_IDELAY_VALUE_ETH2)
) u_eth2 (
        .tx_clk                     (clk_125MHz_eth2_buf),
        .rx_clk                     (rx2_clk_shifted),
        .rst_n                      (rst_n),
        .eth_rx_rst_n               (eth2_rx_rst_n),

        .idelay_refclk_200MHz       (idelay_refclk_200MHz),
        .idelay_refclk_locked       (idelay_refclk_locked),

        .rxd                        (rxd_eth2),
        .rx_ctl                     (rx_ctl_eth2),

        .rx_fifo_wr_en              (rx_fifo_wr_en_eth2),
        .rx_fifo_data_in            (rx_fifo_data_in_eth2),
        .rx_fifo_rst_n              (rx_fifo_rst_n_eth2),

        .rx_eth_corrupt_frame_count (rx_eth_corrupt_frame_count_eth2),
        .eth_rx_data_valid          (eth_rx_data_valid_eth2),
        .rx_eth_valid_bytes         (rx_eth_valid_bytes_eth2),

        .txd                        (txd_eth2),
        .tx_ctl                     (tx_ctl_eth2),
        .tx_c                       (tx_c_eth2),

        .config_done_pulse          (config_done_eth2),

        .dest_mac                   (dest_mac_eth2),
        .source_mac                 (source_mac_eth2),
        .source_ip                  (source_ip_eth2),
        .dest_ip                    (dest_ip_eth2),
        .source_port                (source_port_eth2),
        .dest_port                  (dest_port_eth2),
        .tx_payload_length          (tx_payload_length_eth2),

        .eth_tx_start_pulse         (eth_tx_start_pulse_eth2),

        .tx_fifo_rd_en              (tx_fifo_rd_en_eth2),
        .tx_fifo_empty              (tx_fifo_empty_eth2),
        .tx_fifo_data_out           (tx_fifo_data_out_eth2),

        .eth_tx_data_sent           (eth_tx_data_sent_eth2),
        
        .count_eth                  (count_eth2)
);

// =====================================================
// ETH3 MODULE
// =====================================================

eth #(
    .IODELAY_GROUP_NAME("ETH3_IDELAY_GROUP"),
    .RXD0_IDELAY_VALUE  (RXD0_IDELAY_VALUE_ETH3),
    .RXD1_IDELAY_VALUE  (RXD1_IDELAY_VALUE_ETH3),
    .RXD2_IDELAY_VALUE  (RXD2_IDELAY_VALUE_ETH3),
    .RXD3_IDELAY_VALUE  (RXD3_IDELAY_VALUE_ETH3),
    .RXCTL_IDELAY_VALUE (RXCTL_IDELAY_VALUE_ETH3)
) u_eth3 (
        .tx_clk                     (clk_125MHz_eth3_buf),
        .rx_clk                     (rx3_clk_shifted),
        .rst_n                      (rst_n),
        .eth_rx_rst_n               (eth3_rx_rst_n),

        .idelay_refclk_200MHz       (idelay_refclk_200MHz),
        .idelay_refclk_locked       (idelay_refclk_locked),

        .rxd                        (rxd_eth3),
        .rx_ctl                     (rx_ctl_eth3),

        .rx_fifo_wr_en              (rx_fifo_wr_en_eth3),
        .rx_fifo_data_in            (rx_fifo_data_in_eth3),
        .rx_fifo_rst_n              (rx_fifo_rst_n_eth3),

        .rx_eth_corrupt_frame_count (rx_eth_corrupt_frame_count_eth3),
        .eth_rx_data_valid          (eth_rx_data_valid_eth3),
        .rx_eth_valid_bytes         (rx_eth_valid_bytes_eth3),

        .txd                        (txd_eth3),
        .tx_ctl                     (tx_ctl_eth3),
        .tx_c                       (tx_c_eth3),

        .config_done_pulse          (config_done_eth3),

        .dest_mac                   (dest_mac_eth3),
        .source_mac                 (source_mac_eth3),
        .source_ip                  (source_ip_eth3),
        .dest_ip                    (dest_ip_eth3),
        .source_port                (source_port_eth3),
        .dest_port                  (dest_port_eth3),
        .tx_payload_length          (tx_payload_length_eth3),

        .eth_tx_start_pulse         (eth_tx_start_pulse_eth3),

        .tx_fifo_rd_en              (tx_fifo_rd_en_eth3),
        .tx_fifo_empty              (tx_fifo_empty_eth3),
        .tx_fifo_data_out           (tx_fifo_data_out_eth3),

        .eth_tx_data_sent           (eth_tx_data_sent_eth3),
        
        .count_eth                  (count_eth3)
);

// =====================================================
// ETH4 MODULE
// =====================================================

eth #(
    .IODELAY_GROUP_NAME("ETH4_IDELAY_GROUP"),
    .RXD0_IDELAY_VALUE  (RXD0_IDELAY_VALUE_ETH4),
    .RXD1_IDELAY_VALUE  (RXD1_IDELAY_VALUE_ETH4),
    .RXD2_IDELAY_VALUE  (RXD2_IDELAY_VALUE_ETH4),
    .RXD3_IDELAY_VALUE  (RXD3_IDELAY_VALUE_ETH4),
    .RXCTL_IDELAY_VALUE (RXCTL_IDELAY_VALUE_ETH4)
) u_eth4 (
        .tx_clk                     (clk_125MHz_eth4_buf),
        .rx_clk                     (rx4_clk_shifted),
        .rst_n                      (rst_n),
        .eth_rx_rst_n               (eth4_rx_rst_n),

        .idelay_refclk_200MHz       (idelay_refclk_200MHz),
        .idelay_refclk_locked       (idelay_refclk_locked),

        .rxd                        (rxd_eth4),
        .rx_ctl                     (rx_ctl_eth4),

        .rx_fifo_wr_en              (rx_fifo_wr_en_eth4),
        .rx_fifo_data_in            (rx_fifo_data_in_eth4),
        .rx_fifo_rst_n              (rx_fifo_rst_n_eth4),

        .rx_eth_corrupt_frame_count (rx_eth_corrupt_frame_count_eth4),
        .eth_rx_data_valid          (eth_rx_data_valid_eth4),
        .rx_eth_valid_bytes         (rx_eth_valid_bytes_eth4),

        .txd                        (txd_eth4),
        .tx_ctl                     (tx_ctl_eth4),
        .tx_c                       (tx_c_eth4),

        .config_done_pulse          (config_done_eth4),

        .dest_mac                   (dest_mac_eth4),
        .source_mac                 (source_mac_eth4),
        .source_ip                  (source_ip_eth4),
        .dest_ip                    (dest_ip_eth4),
        .source_port                (source_port_eth4),
        .dest_port                  (dest_port_eth4),
        .tx_payload_length          (tx_payload_length_eth4),

        .eth_tx_start_pulse         (eth_tx_start_pulse_eth4),

        .tx_fifo_rd_en              (tx_fifo_rd_en_eth4),
        .tx_fifo_empty              (tx_fifo_empty_eth4),
        .tx_fifo_data_out           (tx_fifo_data_out_eth4),

        .eth_tx_data_sent           (eth_tx_data_sent_eth4),
        
        .count_eth                  (count_eth4)
);

// =====================================================
// ETH_NRZ / ETH5 MODULE
// =====================================================

eth  #(
    .IODELAY_GROUP_NAME("ETH_NRZ_IDELAY_GROUP"),
    .ENABLE_RX(0)
)u_eth_nrz(
        .tx_clk                     (clk_125MHz_eth_nrz_buf),
        .rx_clk                     (clk_125MHz_eth_nrz_buf),
        .rst_n                      (rst_n),
        .eth_rx_rst_n               (rst_n),

        .idelay_refclk_200MHz       (idelay_refclk_200MHz),
        .idelay_refclk_locked       (idelay_refclk_locked),

        .rxd                        (4'd0),
        .rx_ctl                     (1'b0),

        .rx_fifo_wr_en              (),
        .rx_fifo_data_in            (),
        .rx_fifo_rst_n              (),

        .rx_eth_corrupt_frame_count (),
        .eth_rx_data_valid          (),
        .rx_eth_valid_bytes         (),

        .txd                        (txd_eth_nrz),
        .tx_ctl                     (tx_ctl_eth_nrz),
        .tx_c                       (tx_c_eth_nrz),

        .config_done_pulse          (config_done_eth_nrz),

        .dest_mac                   (dest_mac_eth_nrz),
        .source_mac                 (source_mac_eth_nrz),
        .source_ip                  (source_ip_eth_nrz),
        .dest_ip                    (dest_ip_eth_nrz),
        .source_port                (source_port_eth_nrz),
        .dest_port                  (dest_port_eth_nrz),
        .tx_payload_length          (tx_payload_length_eth_nrz),

        .eth_tx_start_pulse         (eth_tx_start_pulse_eth_nrz),

        .tx_fifo_rd_en              (tx_fifo_rd_en_eth_nrz),
        .tx_fifo_empty              (tx_fifo_empty_eth_nrz),
        .tx_fifo_data_out           (tx_fifo_data_out_eth_nrz),

        .eth_tx_data_sent           (eth_tx_data_sent_eth_nrz),
        
        .count_eth                  ()
);


// =====================================================
// UART1 RX FIFO
// =====================================================

dual_port_FIFO #(
    .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART1),
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART1_RX)
) rx_fifo_uart1 (
    .rst_n      (rst_n),

    .wr_clk     (clk_uart_55_296MHz_buf),
    .data_in    (rx_fifo_data_in_uart1),
    .wr_en      (rx_fifo_wr_en_uart1),

    .rd_clk     (clk_64MHz_buf),
    .rd_en      (rx_fifo_rd_en_uart1),
    .data_out   (rx_fifo_data_out_uart1),

    .fifo_full  (rx_fifo_full_uart1),
    .fifo_empty (rx_fifo_empty_uart1)
);

// =====================================================
// UART2 RX FIFO
// =====================================================

dual_port_FIFO #(
    .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART2),
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART2_RX)
) rx_fifo_uart2 (
    .rst_n      (rst_n),

    .wr_clk     (clk_uart_55_296MHz_buf),
    .data_in    (rx_fifo_data_in_uart2),
    .wr_en      (rx_fifo_wr_en_uart2),

    .rd_clk     (clk_64MHz_buf),
    .rd_en      (rx_fifo_rd_en_uart2),
    .data_out   (rx_fifo_data_out_uart2),

    .fifo_full  (rx_fifo_full_uart2),
    .fifo_empty (rx_fifo_empty_uart2)
);

// =====================================================
// UART3 RX FIFO
// =====================================================

dual_port_FIFO #(
    .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART3),
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART3_RX)
) rx_fifo_uart3 (
    .rst_n      (rst_n),

    .wr_clk     (clk_uart_55_296MHz_buf),
    .data_in    (rx_fifo_data_in_uart3),
    .wr_en      (rx_fifo_wr_en_uart3),

    .rd_clk     (clk_64MHz_buf),
    .rd_en      (rx_fifo_rd_en_uart3),
    .data_out   (rx_fifo_data_out_uart3),

    .fifo_full  (rx_fifo_full_uart3),
    .fifo_empty (rx_fifo_empty_uart3)
);

// =====================================================
// ETH1 RX FIFO
// =====================================================

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH),
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH_RX)
) rx_fifo_eth1 (
        .rst_n      (rx_fifo_rst_n_eth1),
        .wr_clk     (rx1_clk_shifted),
        .data_in    (rx_fifo_data_in_eth1),
        .wr_en      (rx_fifo_wr_en_eth1),
        .rd_clk     (clk_64MHz_buf),
        .rd_en      (rx_fifo_rd_en_eth1),
        .data_out   (rx_fifo_data_out_eth1),
        .fifo_full  (rx_fifo_full_eth1),
        .fifo_empty (rx_fifo_empty_eth1)
);

// =====================================================
// ETH2 RX FIFO
// =====================================================

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH),
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH_RX)
) rx_fifo_eth2 (
        .rst_n      (rx_fifo_rst_n_eth2),
        .wr_clk     (rx2_clk_shifted),
        .data_in    (rx_fifo_data_in_eth2),
        .wr_en      (rx_fifo_wr_en_eth2),
        .rd_clk     (clk_64MHz_buf),
        .rd_en      (rx_fifo_rd_en_eth2),
        .data_out   (rx_fifo_data_out_eth2),
        .fifo_full  (rx_fifo_full_eth2),
        .fifo_empty (rx_fifo_empty_eth2)
);

// =====================================================
// ETH3 RX FIFO
// =====================================================

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH),
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH_RX)
) rx_fifo_eth3 (
        .rst_n      (rx_fifo_rst_n_eth3),
        .wr_clk     (rx3_clk_shifted),
        .data_in    (rx_fifo_data_in_eth3),
        .wr_en      (rx_fifo_wr_en_eth3),
        .rd_clk     (clk_64MHz_buf),
        .rd_en      (rx_fifo_rd_en_eth3),
        .data_out   (rx_fifo_data_out_eth3),
        .fifo_full  (rx_fifo_full_eth3),
        .fifo_empty (rx_fifo_empty_eth3)
);

// =====================================================
// ETH4 RX FIFO
// =====================================================

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH),
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH_RX)
) rx_fifo_eth4 (
        .rst_n      (rx_fifo_rst_n_eth4),
        .wr_clk     (rx4_clk_shifted),
        .data_in    (rx_fifo_data_in_eth4),
        .wr_en      (rx_fifo_wr_en_eth4),
        .rd_clk     (clk_64MHz_buf),
        .rd_en      (rx_fifo_rd_en_eth4),
        .data_out   (rx_fifo_data_out_eth4),
        .fifo_full  (rx_fifo_full_eth4),
        .fifo_empty (rx_fifo_empty_eth4)
);

// =====================================================
// UART1 TX FIFO
// =====================================================

dual_port_FIFO #(
    .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART1),
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART1_TX)
) tx_fifo_uart1 (
    .rst_n      (rst_n),

    .wr_clk     (clk_64MHz_buf),
    .data_in    (tx_fifo_data_in_uart1),
    .wr_en      (tx_fifo_wr_en_uart1),

    .rd_clk     (clk_uart_55_296MHz_buf),
    .rd_en      (tx_fifo_rd_en_uart1),
    .data_out   (tx_fifo_data_out_uart1),

    .fifo_full  (tx_fifo_full_uart1),
    .fifo_empty (tx_fifo_empty_uart1)
);

// =====================================================
// UART2 TX FIFO
// =====================================================

dual_port_FIFO #(
    .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART2),
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART2_TX)
) tx_fifo_uart2 (
    .rst_n      (rst_n),

    .wr_clk     (clk_64MHz_buf),
    .data_in    (tx_fifo_data_in_uart2),
    .wr_en      (tx_fifo_wr_en_uart2),

    .rd_clk     (clk_uart_55_296MHz_buf),
    .rd_en      (tx_fifo_rd_en_uart2),
    .data_out   (tx_fifo_data_out_uart2),

    .fifo_full  (tx_fifo_full_uart2),
    .fifo_empty (tx_fifo_empty_uart2)
);

// =====================================================
// UART3 TX FIFO
// =====================================================

dual_port_FIFO #(
    .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART3),
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART3_TX)
) tx_fifo_uart3 (
    .rst_n      (rst_n),

    .wr_clk     (clk_64MHz_buf),
    .data_in    (tx_fifo_data_in_uart3),
    .wr_en      (tx_fifo_wr_en_uart3),

    .rd_clk     (clk_uart_55_296MHz_buf),
    .rd_en      (tx_fifo_rd_en_uart3),
    .data_out   (tx_fifo_data_out_uart3),

    .fifo_full  (tx_fifo_full_uart3),
    .fifo_empty (tx_fifo_empty_uart3)
);


// =====================================================
// ETH1 TX FIFO
// =====================================================

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH),
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH_TX)
) tx_fifo_eth1 (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz_buf),
        .data_in    (tx_fifo_data_in_eth1),
        .wr_en      (tx_fifo_wr_en_eth1),
        .rd_clk     (clk_125MHz_eth1_buf),
        .rd_en      (tx_fifo_rd_en_eth1),
        .data_out   (tx_fifo_data_out_eth1),
        .fifo_full  (tx_fifo_full_eth1),
        .fifo_empty (tx_fifo_empty_eth1)
);

// =====================================================
// ETH2 TX FIFO
// =====================================================

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH),
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH_TX)
) tx_fifo_eth2 (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz_buf),
        .data_in    (tx_fifo_data_in_eth2),
        .wr_en      (tx_fifo_wr_en_eth2),
        .rd_clk     (clk_125MHz_eth2_buf),
        .rd_en      (tx_fifo_rd_en_eth2),
        .data_out   (tx_fifo_data_out_eth2),
        .fifo_full  (tx_fifo_full_eth2),
        .fifo_empty (tx_fifo_empty_eth2)
);

// =====================================================
// ETH3 TX FIFO
// =====================================================

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH),
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH_TX)
) tx_fifo_eth3 (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz_buf),
        .data_in    (tx_fifo_data_in_eth3),
        .wr_en      (tx_fifo_wr_en_eth3),
        .rd_clk     (clk_125MHz_eth3_buf),
        .rd_en      (tx_fifo_rd_en_eth3),
        .data_out   (tx_fifo_data_out_eth3),
        .fifo_full  (tx_fifo_full_eth3),
        .fifo_empty (tx_fifo_empty_eth3)
);

// =====================================================
// ETH4 TX FIFO
// =====================================================

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH),
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH_TX)
) tx_fifo_eth4 (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz_buf),
        .data_in    (tx_fifo_data_in_eth4),
        .wr_en      (tx_fifo_wr_en_eth4),
        .rd_clk     (clk_125MHz_eth4_buf),
        .rd_en      (tx_fifo_rd_en_eth4),
        .data_out   (tx_fifo_data_out_eth4),
        .fifo_full  (tx_fifo_full_eth4),
        .fifo_empty (tx_fifo_empty_eth4)
);

// =====================================================
// ETH_NRZ / ETH5 TX FIFO
// =====================================================

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH),
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH_TX)
) tx_fifo_eth_nrz (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz_buf),
        .data_in    (tx_fifo_data_in_eth_nrz),
        .wr_en      (tx_fifo_wr_en_eth_nrz),
        .rd_clk     (clk_125MHz_eth_nrz_buf),
        .rd_en      (tx_fifo_rd_en_eth_nrz),
        .data_out   (tx_fifo_data_out_eth_nrz),
        .fifo_full  (tx_fifo_full_eth_nrz),
        .fifo_empty (tx_fifo_empty_eth_nrz)
);


// =====================================================
// KERNEL MODULE
// =====================================================

kernel u_kernel (
        .clk                        (clk_64MHz_buf),
        .clk_uart                   (clk_uart_55_296MHz_buf),

        .clk_eth1                   (clk_125MHz_eth1_buf),
        .clk_eth2                   (clk_125MHz_eth2_buf),
        .clk_eth3                   (clk_125MHz_eth3_buf),
        .clk_eth4                   (clk_125MHz_eth4_buf),
        .clk_eth_nrz                (clk_125MHz_eth_nrz_buf),

        .rst_n                      (rst_n),

        .rx_clk_eth1                (rx1_clk_shifted),
        .rx_clk_eth2                (rx2_clk_shifted),
        .rx_clk_eth3                (rx3_clk_shifted),
        .rx_clk_eth4                (rx4_clk_shifted),

        .clk_20MHz                  (clk_20MHz_buf),
        .data_in_nrz                (data_in_nrz),

        .bkp_prg_mode_on            (bkp_prg_mode_on),
        .bkp_config_wr_pulse        (bkp_config_wr_pulse),
        .bkp_card_id                (bkp_card_id),
        .fpga_card_id               (fpga_card_id),
        .bkp_data_dir               (bkp_data_dir),
        .bkp_address                (bkp_address),
        .bkp_data_bus               (bkp_data_bus),
        .word_start_strobe_pulse    (word_start_strobe_pulse),

        .config_done_uart1          (config_done_uart1),
        .config_done_uart2          (config_done_uart2),
        .config_done_uart3          (config_done_uart3),
        .config_done_eth1           (config_done_eth1),
        .config_done_eth2           (config_done_eth2),
        .config_done_eth3           (config_done_eth3),
        .config_done_eth4           (config_done_eth4),
        .config_done_eth_nrz        (config_done_eth_nrz),

        .baudrate_uart1             (baudrate_uart1),
        .parity_en_uart1            (parity_en_uart1),
        .parity_odd_even_uart1      (parity_odd_even_uart1),
        .data_width_uart1           (data_width_uart1),

        .baudrate_uart2             (baudrate_uart2),
        .parity_en_uart2            (parity_en_uart2),
        .parity_odd_even_uart2      (parity_odd_even_uart2),
        .data_width_uart2           (data_width_uart2),

        .baudrate_uart3             (baudrate_uart3),
        .parity_en_uart3            (parity_en_uart3),
        .parity_odd_even_uart3      (parity_odd_even_uart3),
        .data_width_uart3           (data_width_uart3),
        .dest_mac_eth1              (dest_mac_eth1),
        .source_mac_eth1            (source_mac_eth1),
        .source_ip_eth1             (source_ip_eth1),
        .dest_ip_eth1               (dest_ip_eth1),
        .source_port_eth1           (source_port_eth1),
        .dest_port_eth1             (dest_port_eth1),
        .tx_payload_length_eth1     (tx_payload_length_eth1),

        .dest_mac_eth2              (dest_mac_eth2),
        .source_mac_eth2            (source_mac_eth2),
        .source_ip_eth2             (source_ip_eth2),
        .dest_ip_eth2               (dest_ip_eth2),
        .source_port_eth2           (source_port_eth2),
        .dest_port_eth2             (dest_port_eth2),
        .tx_payload_length_eth2     (tx_payload_length_eth2),

        .dest_mac_eth3              (dest_mac_eth3),
        .source_mac_eth3            (source_mac_eth3),
        .source_ip_eth3             (source_ip_eth3),
        .dest_ip_eth3               (dest_ip_eth3),
        .source_port_eth3           (source_port_eth3),
        .dest_port_eth3             (dest_port_eth3),
        .tx_payload_length_eth3     (tx_payload_length_eth3),

        .dest_mac_eth4              (dest_mac_eth4),
        .source_mac_eth4            (source_mac_eth4),
        .source_ip_eth4             (source_ip_eth4),
        .dest_ip_eth4               (dest_ip_eth4),
        .source_port_eth4           (source_port_eth4),
        .dest_port_eth4             (dest_port_eth4),
        .tx_payload_length_eth4     (tx_payload_length_eth4),

        .dest_mac_eth_nrz           (dest_mac_eth_nrz),
        .source_mac_eth_nrz         (source_mac_eth_nrz),
        .source_ip_eth_nrz          (source_ip_eth_nrz),
        .dest_ip_eth_nrz            (dest_ip_eth_nrz),
        .source_port_eth_nrz        (source_port_eth_nrz),
        .dest_port_eth_nrz          (dest_port_eth_nrz),
        .tx_payload_length_eth_nrz  (tx_payload_length_eth_nrz),

        .fifo_wr_en_uart1           (tx_fifo_wr_en_uart1),
        .fifo_wr_en_uart2           (tx_fifo_wr_en_uart2),
        .fifo_wr_en_uart3           (tx_fifo_wr_en_uart3),
        .fifo_wr_en_eth1            (tx_fifo_wr_en_eth1),
        .fifo_wr_en_eth2            (tx_fifo_wr_en_eth2),
        .fifo_wr_en_eth3            (tx_fifo_wr_en_eth3),
        .fifo_wr_en_eth4            (tx_fifo_wr_en_eth4),
        .fifo_wr_en_eth_nrz         (tx_fifo_wr_en_eth_nrz),

        .fifo_data_in_uart1         (tx_fifo_data_in_uart1),
        .fifo_data_in_uart2         (tx_fifo_data_in_uart2),
        .fifo_data_in_uart3         (tx_fifo_data_in_uart3),
        .fifo_data_in_eth1          (tx_fifo_data_in_eth1),
        .fifo_data_in_eth2          (tx_fifo_data_in_eth2),
        .fifo_data_in_eth3          (tx_fifo_data_in_eth3),
        .fifo_data_in_eth4          (tx_fifo_data_in_eth4),
        .fifo_data_in_eth_nrz       (tx_fifo_data_in_eth_nrz),

        .tx_fifo_empty_uart1        (tx_fifo_empty_uart1),
        .tx_fifo_empty_uart2        (tx_fifo_empty_uart2),
        .tx_fifo_empty_uart3        (tx_fifo_empty_uart3),
        .tx_fifo_empty_eth1         (tx_fifo_empty_eth1),
        .tx_fifo_empty_eth2         (tx_fifo_empty_eth2),
        .tx_fifo_empty_eth3         (tx_fifo_empty_eth3),
        .tx_fifo_empty_eth4         (tx_fifo_empty_eth4),
        .tx_fifo_empty_eth_nrz      (tx_fifo_empty_eth_nrz),

        .tx_acq_start_uart1         (tx_acq_start_uart1),
        .tx_acq_start_uart2         (tx_acq_start_uart2),
        .tx_acq_start_uart3         (tx_acq_start_uart3),
        .eth_tx_start_pulse_eth1    (eth_tx_start_pulse_eth1),
        .eth_tx_start_pulse_eth2    (eth_tx_start_pulse_eth2),
        .eth_tx_start_pulse_eth3    (eth_tx_start_pulse_eth3),
        .eth_tx_start_pulse_eth4    (eth_tx_start_pulse_eth4),
        .eth_tx_start_pulse_eth_nrz (eth_tx_start_pulse_eth_nrz),

        .rx_fifo_data_out_uart1     (rx_fifo_data_out_uart1),
        .rx_fifo_data_out_uart2     (rx_fifo_data_out_uart2),
        .rx_fifo_data_out_uart3     (rx_fifo_data_out_uart3),
        .rx_fifo_data_out_eth1      (rx_fifo_data_out_eth1),
        .rx_fifo_data_out_eth2      (rx_fifo_data_out_eth2),
        .rx_fifo_data_out_eth3      (rx_fifo_data_out_eth3),
        .rx_fifo_data_out_eth4      (rx_fifo_data_out_eth4),

        .uart1_rx_valid_count       (uart1_rx_valid_count),
        .uart2_rx_valid_count       (uart2_rx_valid_count),
        .uart3_rx_valid_count       (uart3_rx_valid_count),
        .rx_eth_valid_bytes_eth1    (rx_eth_valid_bytes_eth1),
        .rx_eth_valid_bytes_eth2    (rx_eth_valid_bytes_eth2),
        .rx_eth_valid_bytes_eth3    (rx_eth_valid_bytes_eth3),
        .rx_eth_valid_bytes_eth4    (rx_eth_valid_bytes_eth4),

        .uart1_rx_corrupt_count     (uart1_rx_corrupt_count),
        .uart2_rx_corrupt_count     (uart2_rx_corrupt_count),
        .uart3_rx_corrupt_count     (uart3_rx_corrupt_count),
        .rx_eth_corrupt_frame_count_eth1 (rx_eth_corrupt_frame_count_eth1),
        .rx_eth_corrupt_frame_count_eth2 (rx_eth_corrupt_frame_count_eth2),
        .rx_eth_corrupt_frame_count_eth3 (rx_eth_corrupt_frame_count_eth3),
        .rx_eth_corrupt_frame_count_eth4 (rx_eth_corrupt_frame_count_eth4),

        .tx_fifo_full_uart1         (tx_fifo_full_uart1),
        .tx_fifo_full_uart2         (tx_fifo_full_uart2),
        .tx_fifo_full_uart3         (tx_fifo_full_uart3),
        .tx_fifo_full_eth1          (tx_fifo_full_eth1),
        .tx_fifo_full_eth2          (tx_fifo_full_eth2),
        .tx_fifo_full_eth3          (tx_fifo_full_eth3),
        .tx_fifo_full_eth4          (tx_fifo_full_eth4),
        .tx_fifo_full_eth_nrz       (tx_fifo_full_eth_nrz),

        .rx_fifo_full_uart1         (rx_fifo_full_uart1),
        .rx_fifo_full_uart2         (rx_fifo_full_uart2),
        .rx_fifo_full_uart3         (rx_fifo_full_uart3),
        .rx_fifo_full_eth1          (rx_fifo_full_eth1),
        .rx_fifo_full_eth2          (rx_fifo_full_eth2),
        .rx_fifo_full_eth3          (rx_fifo_full_eth3),
        .rx_fifo_full_eth4          (rx_fifo_full_eth4),

        .rx_fifo_empty_uart1        (rx_fifo_empty_uart1),
        .rx_fifo_empty_uart2        (rx_fifo_empty_uart2),
        .rx_fifo_empty_uart3        (rx_fifo_empty_uart3),
        .rx_fifo_empty_eth1         (rx_fifo_empty_eth1),
        .rx_fifo_empty_eth2         (rx_fifo_empty_eth2),
        .rx_fifo_empty_eth3         (rx_fifo_empty_eth3),
        .rx_fifo_empty_eth4         (rx_fifo_empty_eth4),

        .rx_fifo_rd_en_uart1        (rx_fifo_rd_en_uart1),
        .rx_fifo_rd_en_uart2        (rx_fifo_rd_en_uart2),
        .rx_fifo_rd_en_uart3        (rx_fifo_rd_en_uart3),
        .rx_fifo_rd_en_eth1         (rx_fifo_rd_en_eth1),
        .rx_fifo_rd_en_eth2         (rx_fifo_rd_en_eth2),
        .rx_fifo_rd_en_eth3         (rx_fifo_rd_en_eth3),
        .rx_fifo_rd_en_eth4         (rx_fifo_rd_en_eth4),

        .eth_tx_data_sent_eth1      (eth_tx_data_sent_eth1),
        .eth_tx_data_sent_eth2      (eth_tx_data_sent_eth2),
        .eth_tx_data_sent_eth3      (eth_tx_data_sent_eth3),
        .eth_tx_data_sent_eth4      (eth_tx_data_sent_eth4),
        .eth_tx_data_sent_eth_nrz   (eth_tx_data_sent_eth_nrz),
        
        .count_uart1                (count_uart1),
        .count_uart2                (count_uart2),
        .count_uart3                (count_uart3),
        .count_eth1                 (count_eth1),
        .count_eth2                 (count_eth2),
        .count_eth3                 (count_eth3),
        .count_eth4                 (count_eth4)
);

endmodule

module reset_synchronizer #(
    parameter integer STAGES = 3
)(
    input  wire clk,
    input  wire rst_n,
    input  wire clk_locked,

    output wire rst_n_sync
);

reg [STAGES-1:0] rst_sync_reg;

assign rst_n_sync = rst_sync_reg[STAGES-1];

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        rst_sync_reg <= {STAGES{1'b0}};
    else if (!clk_locked)
        rst_sync_reg <= {STAGES{1'b0}};
    else
        rst_sync_reg <= {rst_sync_reg[STAGES-2:0], 1'b1};
end

endmodule


// file: clk_wiz_rgmii_rx_shift.v
// (c) Copyright 2017-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//
//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk_out_shifted__125.00000____-120.000______50.0______117.042_____94.860
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary_________125.000____________0.010

`timescale 1ps/1ps

module clk_wiz_rgmii_rx_shift_clk_wiz 

 (// Clock in ports
  // Clock out ports
  output        clk_out_shifted,
  // Status and control signals
  input         resetn,
  output        locked,
  input         clk_in
 );
  // Input buffering
  //------------------------------------
wire clk_in_clk_wiz_rgmii_rx_shift;
wire clk_in2_clk_wiz_rgmii_rx_shift;
  assign clk_in_clk_wiz_rgmii_rx_shift = clk_in;




  // Clocking PRIMITIVE
  //------------------------------------

  // Instantiation of the MMCM PRIMITIVE
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused

  wire        clk_out_shifted_clk_wiz_rgmii_rx_shift;
  wire        clk_out2_clk_wiz_rgmii_rx_shift;
  wire        clk_out3_clk_wiz_rgmii_rx_shift;
  wire        clk_out4_clk_wiz_rgmii_rx_shift;
  wire        clk_out5_clk_wiz_rgmii_rx_shift;
  wire        clk_out6_clk_wiz_rgmii_rx_shift;
  wire        clk_out7_clk_wiz_rgmii_rx_shift;

  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        locked_int;
  wire        clkfbout_clk_wiz_rgmii_rx_shift;
  wire        clkfbout_buf_clk_wiz_rgmii_rx_shift;
  wire        clkfboutb_unused;
    wire clkout0b_unused;
   wire clkout1_unused;
   wire clkout1b_unused;
   wire clkout2_unused;
   wire clkout2b_unused;
   wire clkout3_unused;
   wire clkout3b_unused;
   wire clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;
  wire        reset_high;

  MMCME2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (8.250),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (8.250),
    .CLKOUT0_PHASE        (-120.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (8.000))
  mmcm_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_clk_wiz_rgmii_rx_shift),
    .CLKFBOUTB           (clkfboutb_unused),
    .CLKOUT0             (clk_out_shifted_clk_wiz_rgmii_rx_shift),
    .CLKOUT0B            (clkout0b_unused),
    .CLKOUT1             (clkout1_unused),
    .CLKOUT1B            (clkout1b_unused),
    .CLKOUT2             (clkout2_unused),
    .CLKOUT2B            (clkout2b_unused),
    .CLKOUT3             (clkout3_unused),
    .CLKOUT3B            (clkout3b_unused),
    .CLKOUT4             (clkout4_unused),
    .CLKOUT5             (clkout5_unused),
    .CLKOUT6             (clkout6_unused),
     // Input clock control
    .CLKFBIN             (clkfbout_buf_clk_wiz_rgmii_rx_shift),
    .CLKIN1              (clk_in_clk_wiz_rgmii_rx_shift),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (do_unused),
    .DRDY                (drdy_unused),
    .DWE                 (1'b0),
    // Ports for dynamic phase shift
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    .PSDONE              (psdone_unused),
    // Other control and status signals
    .LOCKED              (locked_int),
    .CLKINSTOPPED        (clkinstopped_unused),
    .CLKFBSTOPPED        (clkfbstopped_unused),
    .PWRDWN              (1'b0),
    .RST                 (reset_high));
  assign reset_high = ~resetn; 

  assign locked = locked_int;
// Clock Monitor clock assigning
//--------------------------------------
 // Output buffering
  //-----------------------------------

  BUFG clkf_buf
   (.O (clkfbout_buf_clk_wiz_rgmii_rx_shift),
    .I (clkfbout_clk_wiz_rgmii_rx_shift));






  BUFG clkout1_buf
   (.O   (clk_out_shifted),
    .I   (clk_out_shifted_clk_wiz_rgmii_rx_shift));




endmodule


// file: clk_wiz_rgmii_rx_shift.v
// (c) Copyright 2017-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//
//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk_out_shifted__125.00000____-120.000______50.0______117.042_____94.860
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary_________125.000____________0.010

`timescale 1ps/1ps

(* CORE_GENERATION_INFO = "clk_wiz_rgmii_rx_shift,clk_wiz_v6_0_16_0_0,{component_name=clk_wiz_rgmii_rx_shift,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,enable_axi=0,feedback_source=FDBK_AUTO,PRIMITIVE=MMCM,num_out_clk=1,clkin1_period=8.000,clkin2_period=10.000,use_power_down=false,use_reset=true,use_locked=true,use_inclk_stopped=false,feedback_type=SINGLE,CLOCK_MGR_TYPE=NA,manual_override=false}" *)

module clk_wiz_rgmii_rx_shift 
 (
  // Clock out ports
  output        clk_out_shifted,
  // Status and control signals
  input         resetn,
  output        locked,
 // Clock in ports
  input         clk_in
 );

  clk_wiz_rgmii_rx_shift_clk_wiz inst
  (
  // Clock out ports  
  .clk_out_shifted(clk_out_shifted),
  // Status and control signals               
  .resetn(resetn), 
  .locked(locked),
 // Clock in ports
  .clk_in(clk_in)
  );

endmodule


// file: clk_wiz_125_to_200.v
// (c) Copyright 2017-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//
//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk_out_200MHz__200.00000______0.000______50.0______109.241_____96.948
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary_________125.000____________0.010

`timescale 1ps/1ps

module clk_wiz_125_to_200_clk_wiz 

 (// Clock in ports
  // Clock out ports
  output        clk_out_200MHz,
  // Status and control signals
  input         resetn,
  output        locked,
  input         clk_125MHz
 );
  // Input buffering
  //------------------------------------
wire clk_125MHz_clk_wiz_125_to_200;
wire clk_in2_clk_wiz_125_to_200;
  assign clk_125MHz_clk_wiz_125_to_200 = clk_125MHz;




  // Clocking PRIMITIVE
  //------------------------------------

  // Instantiation of the MMCM PRIMITIVE
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused

  wire        clk_out_200MHz_clk_wiz_125_to_200;
  wire        clk_out2_clk_wiz_125_to_200;
  wire        clk_out3_clk_wiz_125_to_200;
  wire        clk_out4_clk_wiz_125_to_200;
  wire        clk_out5_clk_wiz_125_to_200;
  wire        clk_out6_clk_wiz_125_to_200;
  wire        clk_out7_clk_wiz_125_to_200;

  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        locked_int;
  wire        clkfbout_clk_wiz_125_to_200;
  wire        clkfbout_buf_clk_wiz_125_to_200;
  wire        clkfboutb_unused;
    wire clkout0b_unused;
   wire clkout1_unused;
   wire clkout1b_unused;
   wire clkout2_unused;
   wire clkout2b_unused;
   wire clkout3_unused;
   wire clkout3b_unused;
   wire clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;
  wire        reset_high;

  MMCME2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (8.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (5.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (8.000))
  mmcm_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_clk_wiz_125_to_200),
    .CLKFBOUTB           (clkfboutb_unused),
    .CLKOUT0             (clk_out_200MHz_clk_wiz_125_to_200),
    .CLKOUT0B            (clkout0b_unused),
    .CLKOUT1             (clkout1_unused),
    .CLKOUT1B            (clkout1b_unused),
    .CLKOUT2             (clkout2_unused),
    .CLKOUT2B            (clkout2b_unused),
    .CLKOUT3             (clkout3_unused),
    .CLKOUT3B            (clkout3b_unused),
    .CLKOUT4             (clkout4_unused),
    .CLKOUT5             (clkout5_unused),
    .CLKOUT6             (clkout6_unused),
     // Input clock control
    .CLKFBIN             (clkfbout_buf_clk_wiz_125_to_200),
    .CLKIN1              (clk_125MHz_clk_wiz_125_to_200),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (do_unused),
    .DRDY                (drdy_unused),
    .DWE                 (1'b0),
    // Ports for dynamic phase shift
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    .PSDONE              (psdone_unused),
    // Other control and status signals
    .LOCKED              (locked_int),
    .CLKINSTOPPED        (clkinstopped_unused),
    .CLKFBSTOPPED        (clkfbstopped_unused),
    .PWRDWN              (1'b0),
    .RST                 (reset_high));
  assign reset_high = ~resetn; 

  assign locked = locked_int;
// Clock Monitor clock assigning
//--------------------------------------
 // Output buffering
  //-----------------------------------

  BUFG clkf_buf
   (.O (clkfbout_buf_clk_wiz_125_to_200),
    .I (clkfbout_clk_wiz_125_to_200));






  BUFG clkout1_buf
   (.O   (clk_out_200MHz),
    .I   (clk_out_200MHz_clk_wiz_125_to_200));




endmodule


// file: clk_wiz_125_to_200.v
// (c) Copyright 2017-2018, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//
//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk_out_200MHz__200.00000______0.000______50.0______109.241_____96.948
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary_________125.000____________0.010

`timescale 1ps/1ps

(* CORE_GENERATION_INFO = "clk_wiz_125_to_200,clk_wiz_v6_0_16_0_0,{component_name=clk_wiz_125_to_200,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,enable_axi=0,feedback_source=FDBK_AUTO,PRIMITIVE=MMCM,num_out_clk=1,clkin1_period=8.000,clkin2_period=10.000,use_power_down=false,use_reset=true,use_locked=true,use_inclk_stopped=false,feedback_type=SINGLE,CLOCK_MGR_TYPE=NA,manual_override=false}" *)

module clk_wiz_125_to_200 
 (
  // Clock out ports
  output        clk_out_200MHz,
  // Status and control signals
  input         resetn,
  output        locked,
 // Clock in ports
  input         clk_125MHz
 );

  clk_wiz_125_to_200_clk_wiz inst
  (
  // Clock out ports  
  .clk_out_200MHz(clk_out_200MHz),
  // Status and control signals               
  .resetn(resetn), 
  .locked(locked),
 // Clock in ports
  .clk_125MHz(clk_125MHz)
  );

endmodule