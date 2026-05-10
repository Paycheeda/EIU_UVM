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
		
		output 									fifo_read_data_pulse,
		input 									fifo_empty,
		
		input[PARAM_MAX_DATA_WIDTH -1 : 0] 		data_in_TX,
		output[PARAM_MAX_DATA_WIDTH -1 : 0]		data_out_RX,
		
		input 									send_data_TX_pulse_in,
		output wire								uart_tx_busy,
		output wire 							data_ready_TX_pulse,
		
		output 									flag_data_received,
		output 									flag_packet_RX_corrupt,
		output wire 							data_ready_RX_pulse
);



wire data_start_TX_pulse_out;

wire uart_rx_busy;

wire [PARAM_MAX_DATA_WIDTH-1:0] data_for_TX;

wire[12:0] clock_delay_param;
wire [3:0] data_width_reg;
wire parity_en_reg;
wire parity_odd_even_reg;


uart_IF u_uart_IF
		(
		.clk(clk),
		.rst_n(rst_n),
		.config_done_pulse(config_done_pulse),
		
		.fifo_read_data_pulse(fifo_read_data_pulse),
		.fifo_empty(fifo_empty),
		
		.data_in_TX(data_in_TX),
		.data_for_TX(data_for_TX),
		
		.baudrate(baudrate),
		.data_width(data_width),
		.parity_en(parity_en),
		.parity_odd_even(parity_odd_even),
		
		.data_width_reg(data_width_reg),
		.parity_en_reg(parity_en_reg),
		.parity_odd_even_reg(parity_odd_even_reg),
		.clock_delay_param(clock_delay_param),
		
		.uart_tx_busy(uart_tx_busy),
		.data_ready_TX_pulse(data_ready_TX_pulse),
		.data_start_TX_pulse_out(data_start_TX_pulse_out),
		.send_data_TX_pulse_in(send_data_TX_pulse_in),
		
		.uart_rx_busy(uart_rx_busy),
		.data_ready_RX_pulse(data_ready_RX_pulse),
		.flag_data_received(flag_data_received)
);


uart_TX #(
			.PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH)
	) u_uart_TX(			
				.clk(clk), 
				.rst_n(rst_n),
				
				.parity_en(parity_en_reg), 
				.parity_odd_even(parity_odd_even_reg), 
				.clock_delay_param(clock_delay_param),
				.data_width(data_width_reg),
				
				.data_tx(tx),
				
				.data_start_pulse(data_start_TX_pulse_out),
				.data_in(data_for_TX),
				.data_ready_pulse(data_ready_TX_pulse),
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
				
				.data_out(data_out_RX), 
				.data_ready_pulse(data_ready_RX_pulse), 
				.flag_packet_corrupt(flag_packet_RX_corrupt),
				.uart_rx_busy(uart_rx_busy)
);

endmodule