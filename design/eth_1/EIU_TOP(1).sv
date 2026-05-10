`default_nettype none

module EIU_TOP#(
	)(
		input 						clk_44_2386MHz,
		input 						clk_64MHz,
		input 						rst_n,
		
		input 						uart1_rx,
		input 						uart2_rx,
		input 						uart3_rx,
		
		output 						uart1_tx,
		output 						uart2_tx,
		output 						uart3_tx
);

parameter integer PARAM_UART1_DATA_WIDTH = 9;
parameter integer PARAM_UART2_DATA_WIDTH = 9;
parameter integer PARAM_UART3_DATA_WIDTH = 9;
/////////////////////////////////////////////////////////////////
// DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width //
// ===========|===========|============|=======================//
//   37-72    |  "36Kb"   |     512    |         9-bit         //
//   19-36    |  "36Kb"   |    1024    |        10-bit         //
//   19-36    |  "18Kb"   |     512    |         9-bit         //
//   10-18    |  "36Kb"   |    2048    |        11-bit         // 
//   10-18    |  "18Kb"   |    1024    |        10-bit         //
//    5-9     |  "36Kb"   |    4096    |        12-bit         //
//    5-9     |  "18Kb"   |    2048    |        11-bit         //
//    1-4     |  "36Kb"   |    8192    |        13-bit         //
//    1-4     |  "18Kb"   |    4096    |        12-bit         //
/////////////////////////////////////////////////////////////////
parameter PARAM_FIFO_UART1_RX_SIZE = "18Kb";
parameter PARAM_FIFO_UART1_TX_SIZE = "18Kb";

parameter PARAM_FIFO_UART2_RX_SIZE = "18Kb";
parameter PARAM_FIFO_UART2_TX_SIZE = "18Kb";

parameter PARAM_FIFO_UART3_RX_SIZE = "18Kb";
parameter PARAM_FIFO_UART3_TX_SIZE = "18Kb";


wire[PARAM_UART1_DATA_WIDTH-1 : 0] uart1_RX_data_fifo_in;
wire[PARAM_UART2_DATA_WIDTH-1 : 0] uart2_RX_data_fifo_in;
wire[PARAM_UART3_DATA_WIDTH-1 : 0] uart3_RX_data_fifo_in;

wire[PARAM_UART1_DATA_WIDTH-1 : 0] uart1_TX_data_fifo_in;
wire[PARAM_UART2_DATA_WIDTH-1 : 0] uart2_TX_data_fifo_in;
wire[PARAM_UART3_DATA_WIDTH-1 : 0] uart3_TX_data_fifo_in;

wire[PARAM_UART1_DATA_WIDTH-1 : 0] uart1_TX_data_fifo_out;
wire[PARAM_UART2_DATA_WIDTH-1 : 0] uart2_TX_data_fifo_out;
wire[PARAM_UART3_DATA_WIDTH-1 : 0] uart3_TX_data_fifo_out;

wire[PARAM_UART1_DATA_WIDTH-1 : 0] uart1_RX_data_fifo_out;
wire[PARAM_UART2_DATA_WIDTH-1 : 0] uart2_RX_data_fifo_out;
wire[PARAM_UART3_DATA_WIDTH-1 : 0] uart3_RX_data_fifo_out;

wire uart1_RX_data_corrupt_flag_out;
wire uart2_RX_data_corrupt_flag_out;
wire uart3_RX_data_corrupt_flag_out;

wire uart1_RX_data_ready_pulse_out;
wire uart2_RX_data_ready_pulse_out;
wire uart3_RX_data_ready_pulse_out;

wire uart1_TX_data_ready_pulse_out;
wire uart2_TX_data_ready_pulse_out;
wire uart3_TX_data_ready_pulse_out;

wire uart1_TX_start_send_pulse_out;
wire uart2_TX_start_send_pulse_out;
wire uart3_TX_start_send_pulse_out;

wire uart1_RX_start_read_pulse_out;
wire uart2_RX_start_read_pulse_out;
wire uart3_RX_start_read_pulse_out;

wire uart1_TX_start_read_flag_in;
wire uart2_TX_start_read_flag_in;
wire uart3_TX_start_read_flag_in;

wire uart1_TX_fifo_write_data_pulse_in;
wire uart2_TX_fifo_write_data_pulse_in;
wire uart3_TX_fifo_write_data_pulse_in;

wire uart1_RX_start_read_flag_in;
wire uart2_RX_start_read_flag_in;
wire uart3_RX_start_read_flag_in;

wire uart1_RX_data_received_flag_out;
wire uart2_RX_data_received_flag_out;
wire uart3_RX_data_received_flag_out;

wire uart1_TX_busy_flag_out;
wire uart2_TX_busy_flag_out;
wire uart3_TX_busy_flag_out;

wire uart1_RX_fifo_empty;
wire uart2_RX_fifo_empty;
wire uart3_RX_fifo_empty;

wire uart1_TX_fifo_empty;
wire uart2_TX_fifo_empty;
wire uart3_TX_fifo_empty;

wire uart1_RX_fifo_full;
wire uart2_RX_fifo_full;
wire uart3_RX_fifo_full;

wire uart1_TX_fifo_full;
wire uart2_TX_fifo_full;
wire uart3_TX_fifo_full;

wire[31:0] uart1_baudrate;
wire[31:0] uart2_baudrate;
wire[31:0] uart3_baudrate;

wire uart1_parity_en;
wire uart2_parity_en;
wire uart3_parity_en;

wire uart1_parity_odd_even;
wire uart2_parity_odd_even;
wire uart3_parity_odd_even;

wire[3:0] uart1_data_width;
wire[3:0] uart2_data_width;
wire[3:0] uart3_data_width;


kernel#(
			.PARAM_UART1_DATA_WIDTH(PARAM_UART1_DATA_WIDTH),
			.PARAM_UART2_DATA_WIDTH(PARAM_UART2_DATA_WIDTH),
			.PARAM_UART3_DATA_WIDTH(PARAM_UART3_DATA_WIDTH)
) master_controller(
		
		.clk(clk_64MHz),
		.rst_n(rst_n),
		
		.uart1_baudrate(uart1_baudrate),
		.uart2_baudrate(uart2_baudrate),
		.uart3_baudrate(uart3_baudrate),
		
		.uart1_parity_en(uart1_parity_en),
		.uart2_parity_en(uart2_parity_en),
		.uart3_parity_en(uart3_parity_en),
		
		.uart1_parity_odd_even(uart1_parity_odd_even),
		.uart2_parity_odd_even(uart2_parity_odd_even),
		.uart3_parity_odd_even(uart3_parity_odd_even),
		
		.uart1_data_width(uart1_data_width),
		.uart2_data_width(uart2_data_width),
		.uart3_data_width(uart3_data_width),
		
		.uart1_RX_start_read_pulse_in(uart1_RX_start_read_pulse_out),
		.uart2_RX_start_read_pulse_in(uart2_RX_start_read_pulse_out),
		.uart3_RX_start_read_pulse_in(uart3_RX_start_read_pulse_out),
		
		.uart1_TX_data_ready_pulse_in(uart1_TX_data_ready_pulse_out),
		.uart2_TX_data_ready_pulse_in(uart2_TX_data_ready_pulse_out),
		.uart3_TX_data_ready_pulse_in(uart3_TX_data_ready_pulse_out),
		
		.uart1_RX_data_in(uart1_RX_data_fifo_out),
		.uart2_RX_data_in(uart2_RX_data_fifo_out),
		.uart3_RX_data_in(uart3_RX_data_fifo_out),
		
		.uart1_TX_data_out(uart1_TX_data_fifo_in),
		.uart2_TX_data_out(uart2_TX_data_fifo_in),
		.uart3_TX_data_out(uart3_TX_data_fifo_in),
		
		.uart1_RX_fifo_empty(uart1_RX_fifo_empty),
		.uart2_RX_fifo_empty(uart2_RX_fifo_empty),
		.uart3_RX_fifo_empty(uart3_RX_fifo_empty),
		
		.uart1_TX_fifo_empty(uart1_TX_fifo_empty),
		.uart2_TX_fifo_empty(uart2_TX_fifo_empty),
		.uart3_TX_fifo_empty(uart3_TX_fifo_empty),
		
		.uart1_RX_fifo_full(uart1_RX_fifo_full),
		.uart2_RX_fifo_full(uart2_RX_fifo_full),
		.uart3_RX_fifo_full(uart3_RX_fifo_full),
		
		.uart1_TX_fifo_full(uart1_TX_fifo_full),
		.uart2_TX_fifo_full(uart2_TX_fifo_full),
		.uart3_TX_fifo_full(uart3_TX_fifo_full),
		
		.uart1_RX_start_read_flag_out(uart1_RX_start_read_flag_in),
		.uart2_RX_start_read_flag_out(uart2_RX_start_read_flag_in),
		.uart3_RX_start_read_flag_out(uart3_RX_start_read_flag_in),
		
		.uart1_TX_start_read_flag_out(uart1_TX_start_read_flag_in),
		.uart2_TX_start_read_flag_out(uart2_TX_start_read_flag_in),
		.uart3_TX_start_read_flag_out(uart3_TX_start_read_flag_in),
		
		.uart1_TX_write_data_pulse_out(uart1_TX_fifo_write_data_pulse_in),
		.uart2_TX_write_data_pulse_out(uart2_TX_fifo_write_data_pulse_in),
		.uart3_TX_write_data_pulse_out(uart3_TX_fifo_write_data_pulse_in),
		
		.uart1_RX_data_received_flag_in(uart1_RX_data_received_flag_out),
		.uart2_RX_data_received_flag_in(uart2_RX_data_received_flag_out),
		.uart3_RX_data_received_flag_in(uart3_RX_data_received_flag_out),
		
		.uart1_TX_busy_flag_in(uart1_TX_busy_flag_out),
		.uart2_TX_busy_flag_in(uart2_TX_busy_flag_out),
		.uart3_TX_busy_flag_in(uart3_TX_busy_flag_out)
);


uart#(
		.PARAM_MAX_DATA_WIDTH(PARAM_UART1_DATA_WIDTH)
	) uart_1 (
		.clk(clk_44_2386MHz),
		.rst_n(rst_n),

		.baudrate(uart1_baudrate),
		.parity_en(uart1_parity_en),
		.parity_odd_even(uart1_parity_odd_even),
		.data_width(uart1_data_width),
		
		.rx(uart1_rx),
		.tx(uart1_tx),
		
		.data_in_TX(uart1_TX_data_fifo_out),
		.data_out_RX(uart1_RX_data_fifo_in),
		
		.send_data_TX_pulse_in(uart1_TX_start_send_pulse_out),
		.uart_tx_busy(uart1_TX_busy_flag_out),
		.data_ready_TX_pulse(uart1_TX_data_ready_pulse_out),
		
		.flag_data_received(uart1_RX_data_received_flag_out),
		.flag_packet_RX_corrupt(uart1_RX_data_corrupt_flag_out),
		.data_ready_RX_pulse(uart1_RX_data_ready_pulse_out)
);

dual_port_FIFO #(
				.PARAM_DATA_WIDTH(PARAM_UART1_DATA_WIDTH),
				.PARAM_FIFO_SIZE(PARAM_FIFO_UART1_RX_SIZE)
		) uart1_rx_fifo (
			.rst_n(rst_n),
			
			.wr_clk(clk_44_2386MHz),
			.packet_corrupt_flag(uart1_RX_data_corrupt_flag_out),
			.data_in(uart1_RX_data_fifo_in),
			.write_data_ready_pulse(uart1_RX_data_ready_pulse_out),

			.rd_clk(clk_64MHz),
			.read_data_flag(uart1_RX_start_read_flag_in),	// comes from the KERNEL TO START READING
			.data_out(uart1_RX_data_fifo_out),
			.start_data_read_pulse(uart1_RX_start_read_pulse_out), // goes to the interface that reads data
			.fifo_full(uart1_RX_fifo_full),	// goes to the KERNEL
			.fifo_empty(uart1_RX_fifo_empty) // goes to the KERNEL
		);
		
dual_port_FIFO #(
				.PARAM_DATA_WIDTH(PARAM_UART1_DATA_WIDTH),
				.PARAM_FIFO_SIZE(PARAM_FIFO_UART1_TX_SIZE)
		) uart1_tx_fifo (
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.packet_corrupt_flag(1'b0),
			.data_in(uart1_TX_data_fifo_in),
			.write_data_ready_pulse(uart1_TX_fifo_write_data_pulse_in),

			.rd_clk(clk_44_2386MHz),
			.read_data_flag(uart1_TX_start_read_flag_in),	// comes from the KERNEL to start reading
			.data_out(uart1_TX_data_fifo_out),
			.start_data_read_pulse(uart1_TX_start_send_pulse_out), // goes to the interface that reads data
			.fifo_full(uart1_TX_fifo_full),
			.fifo_empty(uart1_TX_fifo_empty)
		);

uart#(
		.PARAM_MAX_DATA_WIDTH(PARAM_UART2_DATA_WIDTH)
	) uart_2 (
		.clk(clk_44_2386MHz),
		.rst_n(rst_n),

		.baudrate(uart2_baudrate),
		.parity_en(uart2_parity_en),
		.parity_odd_even(uart2_parity_odd_even),
		.data_width(uart2_data_width),
		
		.rx(uart2_rx),
		.tx(uart2_tx),
		
		.data_in_TX(uart2_TX_data_fifo_out),
		.data_out_RX(uart2_RX_data_fifo_in),
		
		.send_data_TX_pulse_in(uart2_TX_start_send_pulse_out),
		.uart_tx_busy(uart2_TX_busy_flag_out),
		.data_ready_TX_pulse(uart2_TX_data_ready_pulse_out),
		
		.flag_data_received(uart2_RX_data_received_flag_out),
		.flag_packet_RX_corrupt(uart2_RX_data_corrupt_flag_out),
		.data_ready_RX_pulse(uart2_RX_data_ready_pulse_out)
);

dual_port_FIFO #(
				.PARAM_DATA_WIDTH(PARAM_UART2_DATA_WIDTH),
				.PARAM_FIFO_SIZE(PARAM_FIFO_UART2_RX_SIZE)
		) uart2_rx_fifo (
			.rst_n(rst_n),
			
			.wr_clk(clk_44_2386MHz),
			.packet_corrupt_flag(uart2_RX_data_corrupt_flag_out),
			.data_in(uart2_RX_data_fifo_in),
			.write_data_ready_pulse(uart2_RX_data_ready_pulse_out),

			.rd_clk(clk_64MHz),
			.read_data_flag(uart2_RX_start_read_flag_in),	// comes from the KERNEL TO START READING
			.data_out(uart2_RX_data_fifo_out),
			.start_data_read_pulse(uart2_RX_start_read_pulse_out), // goes to the interface that reads data
			.fifo_full(uart2_RX_fifo_full),	// goes to the KERNEL
			.fifo_empty(uart2_RX_fifo_empty) // goes to the KERNEL
		);
		
dual_port_FIFO #(
				.PARAM_DATA_WIDTH(PARAM_UART2_DATA_WIDTH),
				.PARAM_FIFO_SIZE(PARAM_FIFO_UART2_TX_SIZE)
		) uart2_tx_fifo (
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.packet_corrupt_flag(1'b0),
			.data_in(uart2_TX_data_fifo_in),
			.write_data_ready_pulse(uart2_TX_fifo_write_data_pulse_in),

			.rd_clk(clk_44_2386MHz),
			.read_data_flag(uart2_TX_start_read_flag_in),	// comes from the KERNEL to start reading
			.data_out(uart2_TX_data_fifo_out),
			.start_data_read_pulse(uart2_TX_start_send_pulse_out), // goes to the interface that reads data
			.fifo_full(uart2_TX_fifo_full),
			.fifo_empty(uart2_TX_fifo_empty)
		);

uart#(
		.PARAM_MAX_DATA_WIDTH(PARAM_UART3_DATA_WIDTH)
	) uart_3 (
		.clk(clk_44_2386MHz),
		.rst_n(rst_n),

		.baudrate(uart3_baudrate),
		.parity_en(uart3_parity_en),
		.parity_odd_even(uart3_parity_odd_even),
		.data_width(uart3_data_width),
		
		.rx(uart3_rx),
		.tx(uart3_tx),
		
		.data_in_TX(uart3_TX_data_fifo_out),
		.data_out_RX(uart3_RX_data_fifo_in),
		
		.send_data_TX_pulse_in(uart3_TX_start_send_pulse_out),
		.uart_tx_busy(uart3_TX_busy_flag_out),
		.data_ready_TX_pulse(uart3_TX_data_ready_pulse_out),
		
		.flag_data_received(uart3_RX_data_received_flag_out),
		.flag_packet_RX_corrupt(uart3_RX_data_corrupt_flag_out),
		.data_ready_RX_pulse(uart3_RX_data_ready_pulse_out)
);

dual_port_FIFO #(
				.PARAM_DATA_WIDTH(PARAM_UART3_DATA_WIDTH),
				.PARAM_FIFO_SIZE(PARAM_FIFO_UART3_RX_SIZE)
		) uart3_rx_fifo (
			.rst_n(rst_n),
			
			.wr_clk(clk_44_2386MHz),
			.packet_corrupt_flag(uart3_RX_data_corrupt_flag_out),
			.data_in(uart3_RX_data_fifo_in),
			.write_data_ready_pulse(uart3_RX_data_ready_pulse_out),

			.rd_clk(clk_64MHz),
			.read_data_flag(uart3_RX_start_read_flag_in),	// comes from the KERNEL TO START READING
			.data_out(uart3_RX_data_fifo_out),
			.start_data_read_pulse(uart3_RX_start_read_pulse_out), // goes to the interface that reads data
			.fifo_full(uart3_RX_fifo_full),	// goes to the KERNEL
			.fifo_empty(uart3_RX_fifo_empty) // goes to the KERNEL
		);
		
dual_port_FIFO #(
				.PARAM_DATA_WIDTH(PARAM_UART3_DATA_WIDTH),
				.PARAM_FIFO_SIZE(PARAM_FIFO_UART3_TX_SIZE)
		) uart3_tx_fifo (
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.packet_corrupt_flag(1'b0),
			.data_in(uart3_TX_data_fifo_in),
			.write_data_ready_pulse(uart3_TX_fifo_write_data_pulse_in),

			.rd_clk(clk_44_2386MHz),
			.read_data_flag(uart3_TX_start_read_flag_in),	// comes from the KERNEL to start reading
			.data_out(uart3_TX_data_fifo_out),
			.start_data_read_pulse(uart3_TX_start_send_pulse_out), // goes to the interface that reads data
			.fifo_full(uart3_TX_fifo_full),
			.fifo_empty(uart3_TX_fifo_empty)
		);

endmodule

`default_nettype wire