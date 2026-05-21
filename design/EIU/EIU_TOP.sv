module EIU_TOP(

        input               clk_64MHz,

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
        input               word_start_strobe_pulse

);

parameter integer PARAM_MAX_DATA_WIDTH_ETH = 8;
parameter         PARAM_FIFO_SIZE_ETH      = "18Kb";

parameter integer PARAM_MAX_DATA_WIDTH_UART1 = 9;
parameter         PARAM_FIFO_SIZE_UART1      = "18Kb";

parameter integer PARAM_MAX_DATA_WIDTH_UART2 = 9;
parameter         PARAM_FIFO_SIZE_UART2      = "18Kb";

parameter integer PARAM_MAX_DATA_WIDTH_UART3 = 9;
parameter         PARAM_FIFO_SIZE_UART3      = "18Kb";


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

wire        config_done_uart;

wire [31:0] baudrate_uart1;
wire        parity_en_uart1;
wire        parity_odd_even_uart1;
wire [3:0]  data_width_uart1;

// =====================================================
// UART2 CONFIG WIRES FROM KERNEL
// =====================================================

wire [31:0] baudrate_uart2;
wire        parity_en_uart2;
wire        parity_odd_even_uart2;
wire [3:0]  data_width_uart2;

// =====================================================
// UART3 CONFIG WIRES FROM KERNEL
// =====================================================

wire [31:0] baudrate_uart3;
wire        parity_en_uart3;
wire        parity_odd_even_uart3;
wire [3:0]  data_width_uart3;


// =====================================================
// UART1 TX WIRES
// =====================================================

wire        tx_fifo_wr_en_uart1;
wire [8:0]  tx_fifo_data_in_uart1;
wire        tx_fifo_rd_en_uart1;
wire [8:0]  tx_fifo_data_out_uart1;
wire        tx_fifo_full_uart1;
wire        tx_fifo_empty_uart1;

wire        tx_acq_start_uart1;
wire        uart_tx_busy_uart1;
wire        tx_acq_done_uart1;

// =====================================================
// UART2 TX WIRES
// =====================================================

wire        tx_fifo_wr_en_uart2;
wire [8:0]  tx_fifo_data_in_uart2;
wire        tx_fifo_rd_en_uart2;
wire [8:0]  tx_fifo_data_out_uart2;
wire        tx_fifo_full_uart2;
wire        tx_fifo_empty_uart2;

wire        tx_acq_start_uart2;
wire        uart_tx_busy_uart2;
wire        tx_acq_done_uart2;

// =====================================================
// UART3 TX WIRES
// =====================================================

wire        tx_fifo_wr_en_uart3;
wire [8:0]  tx_fifo_data_in_uart3;
wire        tx_fifo_rd_en_uart3;
wire [8:0]  tx_fifo_data_out_uart3;
wire        tx_fifo_full_uart3;
wire        tx_fifo_empty_uart3;

wire        tx_acq_start_uart3;
wire        uart_tx_busy_uart3;
wire        tx_acq_done_uart3;


// =====================================================
// UART1 RX WIRES
// =====================================================

wire        rx_fifo_wr_en_uart1;
wire [8:0]  rx_fifo_data_in_uart1;
wire        rx_fifo_rd_en_uart1;
wire [8:0]  rx_fifo_data_out_uart1;
wire        rx_fifo_full_uart1;
wire        rx_fifo_empty_uart1;

wire        uart_rx_busy_uart1;
wire [10:0] uart1_rx_valid_count;
wire [10:0] uart1_rx_corrupt_count;

// =====================================================
// UART2 RX WIRES
// =====================================================

wire        rx_fifo_wr_en_uart2;
wire [8:0]  rx_fifo_data_in_uart2;
wire        rx_fifo_rd_en_uart2;
wire [8:0]  rx_fifo_data_out_uart2;
wire        rx_fifo_full_uart2;
wire        rx_fifo_empty_uart2;

wire        uart_rx_busy_uart2;
wire [10:0] uart2_rx_valid_count;
wire [10:0] uart2_rx_corrupt_count;

// =====================================================
// UART3 RX WIRES
// =====================================================

wire        rx_fifo_wr_en_uart3;
wire [8:0]  rx_fifo_data_in_uart3;
wire        rx_fifo_rd_en_uart3;
wire [8:0]  rx_fifo_data_out_uart3;
wire        rx_fifo_full_uart3;
wire        rx_fifo_empty_uart3;

wire        uart_rx_busy_uart3;
wire [10:0] uart3_rx_valid_count;
wire [10:0] uart3_rx_corrupt_count;


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

wire [10:0]                         rx_eth_corrupt_frame_count_eth1;
wire                                eth_rx_data_valid_eth1;
wire [10:0]                         rx_eth_valid_bytes_eth1;


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

wire [10:0]                         rx_eth_corrupt_frame_count_eth2;
wire                                eth_rx_data_valid_eth2;
wire [10:0]                         rx_eth_valid_bytes_eth2;


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

wire [10:0]                         rx_eth_corrupt_frame_count_eth3;
wire                                eth_rx_data_valid_eth3;
wire [10:0]                         rx_eth_valid_bytes_eth3;


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

wire [10:0]                         rx_eth_corrupt_frame_count_eth4;
wire                                eth_rx_data_valid_eth4;
wire [10:0]                         rx_eth_valid_bytes_eth4;


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

wire [10:0]                         rx_eth_corrupt_frame_count_eth_nrz;
wire                                eth_rx_data_valid_eth_nrz;
wire [10:0]                         rx_eth_valid_bytes_eth_nrz;


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
    .config_done_pulse      (config_done_uart),

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
    .rx_valid_byte_count    (uart1_rx_valid_count)
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
    .config_done_pulse      (config_done_uart),

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
    .rx_valid_byte_count    (uart2_rx_valid_count)
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
    .config_done_pulse      (config_done_uart),

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
    .rx_valid_byte_count    (uart3_rx_valid_count)
);

// =====================================================
// ETH1 RX SHIFTED CLOCK AND RESET
// =====================================================

wire rx1_clk_shifted;
wire rx1_clk_shifted_locked;

clk_wiz_rgmii_rx_shift u_clk_wiz_rgmii_rx1_shift (
    .clk_out_shifted (rx1_clk_shifted),
    .resetn          (rst_n),
    .locked          (rx1_clk_shifted_locked),
    .clk_in          (rx_clk_eth1_buf)
);

// =====================================================
// ETH2 RX SHIFTED CLOCK AND RESET
// =====================================================

wire rx2_clk_shifted;
wire rx2_clk_shifted_locked;

clk_wiz_rgmii_rx_shift u_clk_wiz_rgmii_rx2_shift (
    .clk_out_shifted (rx2_clk_shifted),
    .resetn          (rst_n),
    .locked          (rx2_clk_shifted_locked),
    .clk_in          (rx_clk_eth2_buf)
);

// =====================================================
// ETH3 RX SHIFTED CLOCK AND RESET
// =====================================================

wire rx3_clk_shifted;
wire rx3_clk_shifted_locked;

clk_wiz_rgmii_rx_shift u_clk_wiz_rgmii_rx3_shift (
    .clk_out_shifted (rx3_clk_shifted),
    .resetn          (rst_n),
    .locked          (rx3_clk_shifted_locked),
    .clk_in          (rx_clk_eth3_buf)
);

// =====================================================
// ETH4 RX SHIFTED CLOCK AND RESET
// =====================================================

wire rx4_clk_shifted;
wire rx4_clk_shifted_locked;

clk_wiz_rgmii_rx_shift u_clk_wiz_rgmii_rx4_shift (
    .clk_out_shifted (rx4_clk_shifted),
    .resetn          (rst_n),
    .locked          (rx4_clk_shifted_locked),
    .clk_in          (rx_clk_eth4_buf)
);

// =====================================================
// ETH1 MODULE
// =====================================================

eth #(
    .IODELAY_GROUP_NAME("ETH1_IDELAY_GROUP"),
        .RXD0_IDELAY_VALUE  (26),
        .RXD1_IDELAY_VALUE  (26),
        .RXD2_IDELAY_VALUE  (26),
        .RXD3_IDELAY_VALUE  (26),
        .RXCTL_IDELAY_VALUE (26)
) u_eth1 (
        .tx_clk                     (clk_125MHz_eth1_buf),
        .rx_clk                     (rx1_clk_shifted),
        .rst_n                      (rst_n),

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

        .eth_tx_data_sent           (eth_tx_data_sent_eth1)
);

// =====================================================
// ETH2 MODULE
// =====================================================

eth #(
    .IODELAY_GROUP_NAME("ETH2_IDELAY_GROUP"),
        .RXD0_IDELAY_VALUE  (26),
        .RXD1_IDELAY_VALUE  (26),
        .RXD2_IDELAY_VALUE  (26),
        .RXD3_IDELAY_VALUE  (26),
        .RXCTL_IDELAY_VALUE (26)
) u_eth2 (
        .tx_clk                     (clk_125MHz_eth2_buf),
        .rx_clk                     (rx2_clk_shifted),
        .rst_n                      (rst_n),

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

        .eth_tx_data_sent           (eth_tx_data_sent_eth2)
);

// =====================================================
// ETH3 MODULE
// =====================================================

eth #(
    .IODELAY_GROUP_NAME("ETH3_IDELAY_GROUP"),
        .RXD0_IDELAY_VALUE  (26),
        .RXD1_IDELAY_VALUE  (26),
        .RXD2_IDELAY_VALUE  (26),
        .RXD3_IDELAY_VALUE  (26),
        .RXCTL_IDELAY_VALUE (26)
) u_eth3 (
        .tx_clk                     (clk_125MHz_eth3_buf),
        .rx_clk                     (rx3_clk_shifted),
        .rst_n                      (rst_n),

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

        .eth_tx_data_sent           (eth_tx_data_sent_eth3)
);

// =====================================================
// ETH4 MODULE
// =====================================================

eth #(
    .IODELAY_GROUP_NAME("ETH4_IDELAY_GROUP"),
        .RXD0_IDELAY_VALUE  (28),
        .RXD1_IDELAY_VALUE  (28),
        .RXD2_IDELAY_VALUE  (28),
        .RXD3_IDELAY_VALUE  (28),
        .RXCTL_IDELAY_VALUE (28)
) u_eth4 (
        .tx_clk                     (clk_125MHz_eth4_buf),
        .rx_clk                     (rx4_clk_shifted),
        .rst_n                      (rst_n),

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

        .eth_tx_data_sent           (eth_tx_data_sent_eth4)
);

// =====================================================
// ETH_NRZ / ETH5 MODULE
// =====================================================

eth  #(
    .IODELAY_GROUP_NAME("ETH_NRZ_IDELAY_GROUP"),
        .ENABLE_RX(0)
)u_eth_nrz(
        .tx_clk                     (clk_125MHz_eth_nrz_buf),
        .rx_clk                     (),
        .rst_n                      (rst_n),

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

        .eth_tx_data_sent           (eth_tx_data_sent_eth_nrz)
);


// =====================================================
// UART1 RX FIFO
// =====================================================

dual_port_FIFO #(
    .PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART1),
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART1)
) rx_fifo_uart1 (
    .rst_n      (rst_n),

    .wr_clk     (clk_uart_55_296MHz_buf),
    .data_in    (rx_fifo_data_in_uart1),
    .wr_en      (rx_fifo_wr_en_uart1),

    .rd_clk     (clk_64MHz),
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
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART2)
) rx_fifo_uart2 (
    .rst_n      (rst_n),

    .wr_clk     (clk_uart_55_296MHz_buf),
    .data_in    (rx_fifo_data_in_uart2),
    .wr_en      (rx_fifo_wr_en_uart2),

    .rd_clk     (clk_64MHz),
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
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART3)
) rx_fifo_uart3 (
    .rst_n      (rst_n),

    .wr_clk     (clk_uart_55_296MHz_buf),
    .data_in    (rx_fifo_data_in_uart3),
    .wr_en      (rx_fifo_wr_en_uart3),

    .rd_clk     (clk_64MHz),
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
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH)
) rx_fifo_eth1 (
        .rst_n      (rx_fifo_rst_n_eth1),
        .wr_clk     (rx1_clk_shifted),
        .data_in    (rx_fifo_data_in_eth1),
        .wr_en      (rx_fifo_wr_en_eth1),
        .rd_clk     (clk_64MHz),
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
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH)
) rx_fifo_eth2 (
        .rst_n      (rx_fifo_rst_n_eth2),
        .wr_clk     (rx2_clk_shifted),
        .data_in    (rx_fifo_data_in_eth2),
        .wr_en      (rx_fifo_wr_en_eth2),
        .rd_clk     (clk_64MHz),
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
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH)
) rx_fifo_eth3 (
        .rst_n      (rx_fifo_rst_n_eth3),
        .wr_clk     (rx3_clk_shifted),
        .data_in    (rx_fifo_data_in_eth3),
        .wr_en      (rx_fifo_wr_en_eth3),
        .rd_clk     (clk_64MHz),
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
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH)
) rx_fifo_eth4 (
        .rst_n      (rx_fifo_rst_n_eth4),
        .wr_clk     (rx4_clk_shifted),
        .data_in    (rx_fifo_data_in_eth4),
        .wr_en      (rx_fifo_wr_en_eth4),
        .rd_clk     (clk_64MHz),
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
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART1)
) tx_fifo_uart1 (
    .rst_n      (rst_n),

    .wr_clk     (clk_64MHz),
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
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART2)
) tx_fifo_uart2 (
    .rst_n      (rst_n),

    .wr_clk     (clk_64MHz),
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
    .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_UART3)
) tx_fifo_uart3 (
    .rst_n      (rst_n),

    .wr_clk     (clk_64MHz),
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
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH)
) tx_fifo_eth1 (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz),
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
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH)
) tx_fifo_eth2 (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz),
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
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH)
) tx_fifo_eth3 (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz),
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
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH)
) tx_fifo_eth4 (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz),
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
        .PARAM_FIFO_SIZE (PARAM_FIFO_SIZE_ETH)
) tx_fifo_eth_nrz (
        .rst_n      (rst_n),
        .wr_clk     (clk_64MHz),
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
// ETH1, ETH2, ETH3, ETH4, and ETH_NRZ/ETH5 are connected meaningfully.
// UART paths are tied off for this test top.
// =====================================================

kernel u_kernel (
        .clk                        (clk_64MHz),
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

        .config_done_uart           (config_done_uart),
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
        .eth_tx_data_sent_eth_nrz   (eth_tx_data_sent_eth_nrz)
);

endmodule