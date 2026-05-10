module uart#(
				parameter integer PARAM_MAX_DATA_WIDTH = 9
	)(
		input 									clk,
		input 									rst_n,

		input[31:0] 							baudrate,
		input 									parity_en,
		input 									parity_odd_even,
		input[3:0]								data_width,
		input 									config_done_pulse,
		
		input 									rx,
		output  								tx,
		
		output 									tx_fifo_rd_en,
		input[PARAM_MAX_DATA_WIDTH -1 : 0] 		tx_fifo_data,
		
		output wire 							rx_fifo_wr_en,		
		output[PARAM_MAX_DATA_WIDTH -1 : 0]		rx_fifo_data,
		
		input 									tx_acq_start,
		output wire								uart_tx_busy,
		output wire 							tx_acq_done,
		
		output [10:0]							rx_corrupt_byte_count,
		output 									uart_rx_busy,
		output [10:0]							rx_valid_byte_count
);

wire[12:0] clock_delay_param;
wire [3:0] data_width_reg;
wire parity_en_reg;
wire parity_odd_even_reg;

wire rx_acq_done;

uart_IF u_uart_IF
		(
		.clk(clk),
		.rst_n(rst_n),
		.config_done_pulse(config_done_pulse),
		
		.baudrate(baudrate),
		.data_width(data_width),
		.parity_en(parity_en),
		.parity_odd_even(parity_odd_even),
		
		.data_width_reg(data_width_reg),
		.parity_en_reg(parity_en_reg),
		.parity_odd_even_reg(parity_odd_even_reg),
		.clock_delay_param(clock_delay_param),
		.rx_corrupt_byte_count(rx_corrupt_byte_count),
		.rx_acq_done(rx_acq_done),
		.rx_valid_byte_count(rx_valid_byte_count)
);


uart_TX #(
			.PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH)
	) u_uart_TX(			
				.clk(clk), 
				.rst_n(rst_n),
				
				.data_tx(tx),
				
				.parity_en(parity_en_reg), 
				.parity_odd_even(parity_odd_even_reg), 
				.clock_delay_param(clock_delay_param),
				.data_width(data_width_reg),
				
				
				
				.tx_fifo_rd_en(tx_fifo_rd_en),
				.tx_fifo_data(tx_fifo_data),
				
				.tx_acq_start(tx_acq_start),
				.tx_acq_done(tx_acq_done),
				.uart_tx_busy(uart_tx_busy)
);

uart_RX #(
				.PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH)
	) u_uart_RX(
				.clk(clk), 
				.rst_n(rst_n), 
				
				.data_rx(rx), 
				
				.parity_en(parity_en_reg),
				.parity_odd_even(parity_odd_even_reg),
				.data_width(data_width_reg),
				.clock_delay_param(clock_delay_param),
				
				.rx_fifo_data(rx_fifo_data), 
				.rx_fifo_wr_en(rx_fifo_wr_en), 
				
				.rx_corrupt_byte_count(rx_corrupt_byte_count),
				.rx_acq_done(rx_acq_done),
				.uart_rx_busy(uart_rx_busy)
);

endmodule