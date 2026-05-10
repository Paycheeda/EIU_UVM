module uart_top #(
    parameter BAUD_RATE  = 32'd115200,
    parameter DATA_WIDTH = 32'd9
)(
    input  wire                    clk,
    input  wire                    rst,
    
    // Global Configuration
    input  wire                    parity_en,
    input  wire                    parity_odd_even, // 0 = odd, 1 = even
    
    // TX Interface
    input  wire [DATA_WIDTH-1:0]   tx_data_in,
    input  wire                    tx_start_pulse,
    output wire                    tx_ready_pulse,
    output wire                    tx_serial_out,   // Goes to external RX
    
    // RX Interface
    input  wire                    rx_serial_in,    // Comes from external TX
    input  wire                    rx_start_pulse,  // Required by your RX state machine to start listening
    output wire [DATA_WIDTH-1:0]   rx_data_out,
    output wire                    rx_ready_pulse,
    output wire                    rx_packet_corrupt
);

    // =========================================================
    // UART Transmitter Instantiation
    // =========================================================
    uart_TX #(
        .PARAM_BAUD_RATE(BAUD_RATE),
        .PARAM_DATA_WIDTH(DATA_WIDTH)
    ) tx_inst1 (
        .clk                 (clk),
        .rst                 (rst),
        .data_tx             (tx_serial_out),
        .data_in             (tx_data_in),
        .parity_en           (parity_en),
        .parity_odd_even     (parity_odd_even),
        .data_start_pulse    (tx_start_pulse),
        .data_ready_pulse    (tx_ready_pulse)
    );

    // =========================================================
    // UART Receiver Instantiation
    // =========================================================
    uart_RX #(
        .PARAM_BAUD_RATE(BAUD_RATE),
        .PARAM_DATA_WIDTH(DATA_WIDTH)
    ) rx_inst1 (
        .clk                 (clk),
        .rst                 (rst),
        .data_rx             (rx_serial_in),
        .data_out            (rx_data_out),
        .parity_en           (parity_en),
        .parity_odd_even     (parity_odd_even),
        .data_start_pulse    (rx_start_pulse),
        .data_ready_pulse    (rx_ready_pulse),
        .flag_packet_corrupt (rx_packet_corrupt)
    );

        uart_TX #(
        .PARAM_BAUD_RATE(BAUD_RATE),
        .PARAM_DATA_WIDTH(DATA_WIDTH)
    ) tx_inst2 (
        .clk                 (clk),
        .rst                 (rst),
        .data_tx             (tx_serial_out),
        .data_in             (tx_data_in),
        .parity_en           (parity_en),
        .parity_odd_even     (parity_odd_even),
        .data_start_pulse    (tx_start_pulse),
        .data_ready_pulse    (tx_ready_pulse)
    );

    // =========================================================
    // UART Receiver Instantiation
    // =========================================================
    uart_RX #(
        .PARAM_BAUD_RATE(BAUD_RATE),
        .PARAM_DATA_WIDTH(DATA_WIDTH)
    ) rx_inst2 (
        .clk                 (clk),
        .rst                 (rst),
        .data_rx             (rx_serial_in),
        .data_out            (rx_data_out),
        .parity_en           (parity_en),
        .parity_odd_even     (parity_odd_even),
        .data_start_pulse    (rx_start_pulse),
        .data_ready_pulse    (rx_ready_pulse),
        .flag_packet_corrupt (rx_packet_corrupt)
    );

            uart_TX #(
        .PARAM_BAUD_RATE(BAUD_RATE),
        .PARAM_DATA_WIDTH(DATA_WIDTH)
    ) tx_inst3 (
        .clk                 (clk),
        .rst                 (rst),
        .data_tx             (tx_serial_out),
        .data_in             (tx_data_in),
        .parity_en           (parity_en),
        .parity_odd_even     (parity_odd_even),
        .data_start_pulse    (tx_start_pulse),
        .data_ready_pulse    (tx_ready_pulse)
    );

    // =========================================================
    // UART Receiver Instantiation
    // =========================================================
    uart_RX #(
        .PARAM_BAUD_RATE(BAUD_RATE),
        .PARAM_DATA_WIDTH(DATA_WIDTH)
    ) rx_inst3 (
        .clk                 (clk),
        .rst                 (rst),
        .data_rx             (rx_serial_in),
        .data_out            (rx_data_out),
        .parity_en           (parity_en),
        .parity_odd_even     (parity_odd_even),
        .data_start_pulse    (rx_start_pulse),
        .data_ready_pulse    (rx_ready_pulse),
        .flag_packet_corrupt (rx_packet_corrupt)
    );



endmodule