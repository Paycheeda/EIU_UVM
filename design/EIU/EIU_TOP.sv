`default_nettype none

module EIU_TOP(
		input wire 						clk_44_2368MHz,
		input wire						clk_64MHz,
		input wire						clk1_125MHz,
		input wire						clk2_125MHz,
		input wire						clk3_125MHz,
		input wire						clk4_125MHz,
		input wire						clk_nrz_125MHz,
		input wire						rst_n,
		
		input wire						uart1_rx,
		input wire						uart2_rx,
		input wire						uart3_rx,
		
		output wire						uart1_tx,
		output wire						uart2_tx,
		output wire						uart3_tx,
		
		input wire						rx_c_eth1,
		input wire [3:0] 				rxd_eth1,
		input wire						rx_ctl_eth1,
		
		output wire [3:0]				txd_eth1,
		output wire						tx_ctl_eth1,
		output wire						tx_c_eth1,
		
		input wire						rx_c_eth2,
		input wire [3:0] 				rxd_eth2,
		input wire						rx_ctl_eth2,
		
		output wire [3:0]				txd_eth2,
		output wire						tx_ctl_eth2,
		output wire						tx_c_eth2,
		
		input wire						rx_c_eth3,
		input wire [3:0] 				rxd_eth3,
		input wire						rx_ctl_eth3,
		
		output wire[3:0]				txd_eth3,
		output wire						tx_ctl_eth3,
		output wire						tx_c_eth3,
		
		input wire						rx_c_eth4,
		input wire [3:0] 				rxd_eth4,
		input wire						rx_ctl_eth4,
		
		output wire [3:0]				txd_eth4,
		output wire						tx_ctl_eth4,
		output wire						tx_c_eth4,
		
		output wire [3:0]				txd_eth_nrz,
		output wire						tx_ctl_eth_nrz,
		output wire						tx_c_eth_nrz,
		
		input wire						clk_20MHz,
		input wire						data_in_nrz,
		input wire						bkp_prg_mode_on,
		input wire						bkp_config_wr_pulse,
		input wire [3:0] 				bkp_card_id,
		input wire [3:0] 				fpga_card_id,
		input wire						bkp_data_dir,
		input wire [5:0] 				bkp_address,
		inout wire [11:0]				bkp_data_bus,
		input wire						word_start_strobe_pulse,
		
		output wire [7:0]				led_out
);

parameter integer PARAM_MAX_DATA_WIDTH_UART1 = 9;
parameter PARAM_FIFO_SIZE_UART1 = "18Kb";

wire[31:0] baudrate_uart1;
wire parity_en_uart1;
wire parity_odd_even_uart1;
wire[3:0] data_width_uart1;
wire config_done_uart;

wire tx_fifo_rd_en_uart1;
wire [PARAM_MAX_DATA_WIDTH_UART1-1 : 0] tx_fifo_data_out_uart1;

wire rx_fifo_wr_en_uart1;
wire [PARAM_MAX_DATA_WIDTH_UART1-1 : 0] rx_fifo_data_in_uart1;

wire tx_acq_start_uart1;
wire uart_tx_busy_uart1;
wire tx_acq_done_uart1;

wire[10:0] rx_corrupt_byte_count_uart1;
wire[10:0] rx_valid_byte_count_uart1;
wire uart_rx_busy_uart1;

counter_8bit u_counter_8bit(
		.clk(clk_64MHz),
		.rst_n(rst_n),
		.count_value(led_out)
);

uart#(
		.PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART1)
	)u_uart1(
		.clk(clk_44_2368MHz),
		.rst_n(rst_n),

		.baudrate(baudrate_uart1),
		.parity_en(parity_en_uart1),
		.parity_odd_even(parity_odd_even_uart1),
		.data_width(data_width_uart1),
		.config_done_pulse(config_done_uart),
		
		.rx(uart1_rx),
		.tx(uart1_tx),
		
		.tx_fifo_rd_en(tx_fifo_rd_en_uart1),
		.tx_fifo_data(tx_fifo_data_out_uart1),
		
		.rx_fifo_wr_en(rx_fifo_wr_en_uart1),		
		.rx_fifo_data(rx_fifo_data_in_uart1),
		
		.tx_acq_start(tx_acq_start_uart1),
		.uart_tx_busy(uart_tx_busy_uart1),
		.tx_acq_done(tx_acq_done_uart1),
		
		.rx_corrupt_byte_count(rx_corrupt_byte_count_uart1),
		.rx_valid_byte_count(rx_valid_byte_count_uart1),
		.uart_rx_busy(uart_rx_busy_uart1)
);

wire rx_fifo_rd_en_uart1;
wire [PARAM_MAX_DATA_WIDTH_UART1-1 : 0] rx_fifo_data_out_uart1;
wire rx_fifo_full_uart1;
wire rx_fifo_empty_uart1;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART1),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_UART1)
)rx_fifo_uart1(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_44_2368MHz),
			.data_in(rx_fifo_data_in_uart1),
			.wr_en(rx_fifo_wr_en_uart1),

			.rd_clk(clk_64MHz),
			.rd_en(rx_fifo_rd_en_uart1),
			.data_out(rx_fifo_data_out_uart1),
			
			.fifo_full(rx_fifo_full_uart1),
			.fifo_empty(rx_fifo_empty_uart1)
		);

wire [PARAM_MAX_DATA_WIDTH_UART1-1 : 0] tx_fifo_data_in_uart1;
wire tx_fifo_wr_en_uart1;
wire tx_fifo_full_uart1;
wire tx_fifo_empty_uart1;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART1),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_UART1)
)tx_fifo_uart1(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.data_in(tx_fifo_data_in_uart1),
			.wr_en(tx_fifo_wr_en_uart1),

			.rd_clk(clk_44_2368MHz),
			.rd_en(tx_fifo_rd_en_uart1),
			.data_out(tx_fifo_data_out_uart1),
			
			.fifo_full(tx_fifo_full_uart1),
			.fifo_empty(tx_fifo_empty_uart1)
		);
///////////////////////////////////////////////////////////////////////////////////////////

parameter integer PARAM_MAX_DATA_WIDTH_UART2 = 9;
parameter PARAM_FIFO_SIZE_UART2 = "18Kb";

wire[31:0] baudrate_uart2;
wire parity_en_uart2;
wire parity_odd_even_uart2;
wire[3:0] data_width_uart2;

wire tx_fifo_rd_en_uart2;
wire [PARAM_MAX_DATA_WIDTH_UART2-1 : 0] tx_fifo_data_out_uart2;

wire rx_fifo_wr_en_uart2;
wire [PARAM_MAX_DATA_WIDTH_UART2-1 : 0] rx_fifo_data_in_uart2;

wire tx_acq_start_uart2;
wire uart_tx_busy_uart2;
wire tx_acq_done_uart2;

wire[10:0] rx_corrupt_byte_count_uart2;
wire[10:0] rx_valid_byte_count_uart2;
wire uart_rx_busy_uart2;

uart#(
		.PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART2)
	)u_uart2(
		.clk(clk_44_2368MHz),
		.rst_n(rst_n),

		.baudrate(baudrate_uart2),
		.parity_en(parity_en_uart2),
		.parity_odd_even(parity_odd_even_uart2),
		.data_width(data_width_uart2),
		.config_done_pulse(config_done_uart),
		
		.rx(uart2_rx),
		.tx(uart2_tx),
		
		.tx_fifo_rd_en(tx_fifo_rd_en_uart2),
		.tx_fifo_data(tx_fifo_data_out_uart2),
		
		.rx_fifo_wr_en(rx_fifo_wr_en_uart2),		
		.rx_fifo_data(rx_fifo_data_in_uart2),
		
		.tx_acq_start(tx_acq_start_uart2),
		.uart_tx_busy(uart_tx_busy_uart2),
		.tx_acq_done(tx_acq_done_uart2),
		
		.rx_corrupt_byte_count(rx_corrupt_byte_count_uart2),
		.rx_valid_byte_count(rx_valid_byte_count_uart2),
		.uart_rx_busy(uart_rx_busy_uart2)
);

wire rx_fifo_rd_en_uart2;
wire [PARAM_MAX_DATA_WIDTH_UART2-1 : 0] rx_fifo_data_out_uart2;
wire rx_fifo_full_uart2;
wire rx_fifo_empty_uart2;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART2),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_UART2)
)rx_fifo_uart2(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_44_2368MHz),
			.data_in(rx_fifo_data_in_uart2),
			.wr_en(rx_fifo_wr_en_uart2),

			.rd_clk(clk_64MHz),
			.rd_en(rx_fifo_rd_en_uart2),
			.data_out(rx_fifo_data_out_uart2),
			
			.fifo_full(rx_fifo_full_uart2),
			.fifo_empty(rx_fifo_empty_uart2)
		);

wire [PARAM_MAX_DATA_WIDTH_UART2-1 : 0] tx_fifo_data_in_uart2;
wire tx_fifo_wr_en_uart2;
wire tx_fifo_full_uart2;
wire tx_fifo_empty_uart2;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART2),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_UART2)
)tx_fifo_uart2(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.data_in(tx_fifo_data_in_uart2),
			.wr_en(tx_fifo_wr_en_uart2),

			.rd_clk(clk_44_2368MHz),
			.rd_en(tx_fifo_rd_en_uart2),
			.data_out(tx_fifo_data_out_uart2),
			
			.fifo_full(tx_fifo_full_uart2),
			.fifo_empty(tx_fifo_empty_uart2)
		);

////////////////////////////////////////////////////////////////////////////////////////////////////////

parameter integer PARAM_MAX_DATA_WIDTH_UART3 = 9;
parameter PARAM_FIFO_SIZE_UART3 = "18Kb";

wire[31:0] baudrate_uart3;
wire parity_en_uart3;
wire parity_odd_even_uart3;
wire[3:0] data_width_uart3;

wire tx_fifo_rd_en_uart3;
wire [PARAM_MAX_DATA_WIDTH_UART3-1 : 0] tx_fifo_data_out_uart3;

wire rx_fifo_wr_en_uart3;
wire [PARAM_MAX_DATA_WIDTH_UART3-1 : 0] rx_fifo_data_in_uart3;

wire tx_acq_start_uart3;
wire uart_tx_busy_uart3;
wire tx_acq_done_uart3;

wire[10:0] rx_corrupt_byte_count_uart3;
wire[10:0] rx_valid_byte_count_uart3;
wire uart_rx_busy_uart3;

uart#(
		.PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART3)
	) u_uart3 (
		.clk(clk_44_2368MHz),
		.rst_n(rst_n),

		.baudrate(baudrate_uart3),
		.parity_en(parity_en_uart3),
		.parity_odd_even(parity_odd_even_uart3),
		.data_width(data_width_uart3),
		.config_done_pulse(config_done_uart),
		
		.rx(uart3_rx),
		.tx(uart3_tx),
		
		.tx_fifo_rd_en(tx_fifo_rd_en_uart3),
		.tx_fifo_data(tx_fifo_data_out_uart3),
		
		.rx_fifo_wr_en(rx_fifo_wr_en_uart3),		
		.rx_fifo_data(rx_fifo_data_in_uart3),
		
		.tx_acq_start(tx_acq_start_uart3),
		.uart_tx_busy(uart_tx_busy_uart3),
		.tx_acq_done(tx_acq_done_uart3),
		
		.rx_corrupt_byte_count(rx_corrupt_byte_count_uart3),
		.rx_valid_byte_count(rx_valid_byte_count_uart3),
		.uart_rx_busy(uart_rx_busy_uart3)
);

wire rx_fifo_rd_en_uart3;
wire [PARAM_MAX_DATA_WIDTH_UART3-1 : 0] rx_fifo_data_out_uart3;
wire rx_fifo_full_uart3;
wire rx_fifo_empty_uart3;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART3),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_UART3)
)rx_fifo_uart3(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_44_2368MHz),
			.data_in(rx_fifo_data_in_uart3),
			.wr_en(rx_fifo_wr_en_uart3),

			.rd_clk(clk_64MHz),
			.rd_en(rx_fifo_rd_en_uart3),
			.data_out(rx_fifo_data_out_uart3),
			
			.fifo_full(rx_fifo_full_uart3),
			.fifo_empty(rx_fifo_empty_uart3)
		);

wire [PARAM_MAX_DATA_WIDTH_UART3-1 : 0] tx_fifo_data_in_uart3;
wire tx_fifo_wr_en_uart3;
wire tx_fifo_full_uart3;
wire tx_fifo_empty_uart3;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_UART3),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_UART3)
)tx_fifo_uart3(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.data_in(tx_fifo_data_in_uart3),
			.wr_en(tx_fifo_wr_en_uart3),

			.rd_clk(clk_44_2368MHz),
			.rd_en(tx_fifo_rd_en_uart3),
			.data_out(tx_fifo_data_out_uart3),
			
			.fifo_full(tx_fifo_full_uart3),
			.fifo_empty(tx_fifo_empty_uart3)
		);
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		

parameter integer 	PARAM_MAX_DATA_WIDTH_ETH1 = 8;
parameter 			PARAM_FIFO_SIZE_ETH1 = "18Kb";

wire [10:0] 	rx_eth_corrupt_frame_count_eth1;
wire 			eth_rx_data_valid_eth1;
wire [10:0] 	rx_eth_valid_bytes_eth1;
wire [47:0] 	dest_mac_eth1;
wire [47:0] 	source_mac_eth1;
wire [31:0] 	source_ip_eth1;
wire [31:0] 	dest_ip_eth1;
wire [15:0] 	source_port_eth1;
wire [15:0] 	dest_port_eth1;
wire [10:0] 	tx_payload_length_eth1;

wire 			eth_tx_start_pulse_eth1;
wire 			eth_tx_data_sent_eth1;
wire 			config_done_eth1;

eth u_eth1 (
        .tx_clk                     (clk1_125MHz),
        .rx_clk                     (rx_c_eth1),
        .rst_n                      (rst_n),
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
		.config_done_pulse			(config_done_eth1),
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

wire 											rx_fifo_wr_en_eth1;
wire [PARAM_MAX_DATA_WIDTH_ETH1 - 1 :0] 		rx_fifo_data_in_eth1;
wire 											rx_fifo_rst_n_eth1;
wire 											rx_fifo_empty_eth1;
wire 											rx_fifo_full_eth1;
wire 											rx_fifo_rd_en_eth1;
wire [PARAM_MAX_DATA_WIDTH_ETH1 - 1 :0]			rx_fifo_data_out_eth1;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH1),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_ETH1)
)rx_fifo_eth1(
			
			.rst_n(rx_fifo_rst_n_eth1),
			
			.wr_clk(rx_c_eth1),
			.data_in(rx_fifo_data_in_eth1),
			.wr_en(rx_fifo_wr_en_eth1),

			.rd_clk(clk_64MHz),
			.rd_en(rx_fifo_rd_en_eth1),
			.data_out(rx_fifo_data_out_eth1),
			
			.fifo_full(rx_fifo_full_eth1),
			.fifo_empty(rx_fifo_empty_eth1)
		);

wire 											tx_fifo_wr_en_eth1;
wire [PARAM_MAX_DATA_WIDTH_ETH1 - 1 :0] 		tx_fifo_data_in_eth1;
wire 											tx_fifo_rst_n_eth1;
wire 											tx_fifo_empty_eth1;
wire 											tx_fifo_full_eth1;
wire 											tx_fifo_rd_en_eth1;
wire [PARAM_MAX_DATA_WIDTH_ETH1 - 1 :0]			tx_fifo_data_out_eth1;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH1),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_ETH1)
)tx_fifo_eth1(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.data_in(tx_fifo_data_in_eth1),
			.wr_en(tx_fifo_wr_en_eth1),

			.rd_clk(clk1_125MHz),
			.rd_en(tx_fifo_rd_en_eth1),
			.data_out(tx_fifo_data_out_eth1),
			
			.fifo_full(tx_fifo_full_eth1),
			.fifo_empty(tx_fifo_empty_eth1)
		);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		

parameter integer 	PARAM_MAX_DATA_WIDTH_ETH2 = 8;
parameter 			PARAM_FIFO_SIZE_ETH2 = "18Kb";

wire [10:0] 	rx_eth_corrupt_frame_count_eth2;
wire 			eth_rx_data_valid_eth2;
wire [10:0] 	rx_eth_valid_bytes_eth2;
wire [47:0] 	dest_mac_eth2;
wire [47:0] 	source_mac_eth2;
wire [31:0] 	source_ip_eth2;
wire [31:0] 	dest_ip_eth2;
wire [15:0] 	source_port_eth2;
wire [15:0] 	dest_port_eth2;
wire [10:0] 	tx_payload_length_eth2;

wire 			eth_tx_start_pulse_eth2;
wire 			eth_tx_data_sent_eth2;
wire 			config_done_eth2;

eth u_eth2 (
        .tx_clk                     (clk2_125MHz),
        .rx_clk                     (rx_c_eth2),
        .rst_n                      (rst_n),
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
		.config_done_pulse			(config_done_eth2),
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

wire 											rx_fifo_wr_en_eth2;
wire [PARAM_MAX_DATA_WIDTH_ETH2 - 1 :0] 		rx_fifo_data_in_eth2;
wire 											rx_fifo_rst_n_eth2;
wire 											rx_fifo_empty_eth2;
wire 											rx_fifo_full_eth2;
wire 											rx_fifo_rd_en_eth2;
wire [PARAM_MAX_DATA_WIDTH_ETH2 - 1 :0]			rx_fifo_data_out_eth2;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH2),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_ETH2)
)rx_fifo_eth2(
			
			.rst_n(rx_fifo_rst_n_eth2),
			
			.wr_clk(rx_c_eth2),
			.data_in(rx_fifo_data_in_eth2),
			.wr_en(rx_fifo_wr_en_eth2),

			.rd_clk(clk_64MHz),
			.rd_en(rx_fifo_rd_en_eth2),
			.data_out(rx_fifo_data_out_eth2),
			
			.fifo_full(rx_fifo_full_eth2),
			.fifo_empty(rx_fifo_empty_eth2)
		);

wire 											tx_fifo_wr_en_eth2;
wire [PARAM_MAX_DATA_WIDTH_ETH2 - 1 :0] 		tx_fifo_data_in_eth2;
wire 											tx_fifo_rst_n_eth2;
wire 											tx_fifo_empty_eth2;
wire 											tx_fifo_full_eth2;
wire 											tx_fifo_rd_en_eth2;
wire [PARAM_MAX_DATA_WIDTH_ETH2 - 1 :0]			tx_fifo_data_out_eth2;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH2),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_ETH2)
)tx_fifo_eth2(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.data_in(tx_fifo_data_in_eth2),
			.wr_en(tx_fifo_wr_en_eth2),

			.rd_clk(clk2_125MHz),
			.rd_en(tx_fifo_rd_en_eth2),
			.data_out(tx_fifo_data_out_eth2),
			
			.fifo_full(tx_fifo_full_eth2),
			.fifo_empty(tx_fifo_empty_eth2)
		);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		

parameter integer 	PARAM_MAX_DATA_WIDTH_ETH3 = 8;
parameter 			PARAM_FIFO_SIZE_ETH3 = "18Kb";

wire [10:0] 	rx_eth_corrupt_frame_count_eth3;
wire 			eth_rx_data_valid_eth3;
wire [10:0] 	rx_eth_valid_bytes_eth3;
wire [47:0] 	dest_mac_eth3;
wire [47:0] 	source_mac_eth3;
wire [31:0] 	source_ip_eth3;
wire [31:0] 	dest_ip_eth3;
wire [15:0] 	source_port_eth3;
wire [15:0] 	dest_port_eth3;
wire [10:0] 	tx_payload_length_eth3;

wire 			eth_tx_start_pulse_eth3;
wire 			eth_tx_data_sent_eth3;
wire 			config_done_eth3;

eth u_eth3 (
        .tx_clk                     (clk3_125MHz),
        .rx_clk                     (rx_c_eth3),
        .rst_n                      (rst_n),
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
		.config_done_pulse			(config_done_eth3),
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

wire 											rx_fifo_wr_en_eth3;
wire [PARAM_MAX_DATA_WIDTH_ETH3 - 1 :0] 		rx_fifo_data_in_eth3;
wire 											rx_fifo_rst_n_eth3;
wire 											rx_fifo_empty_eth3;
wire 											rx_fifo_full_eth3;
wire 											rx_fifo_rd_en_eth3;
wire [PARAM_MAX_DATA_WIDTH_ETH3 - 1 :0]			rx_fifo_data_out_eth3;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH3),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_ETH3)
)rx_fifo_eth3(
			
			.rst_n(rx_fifo_rst_n_eth3),
			
			.wr_clk(rx_c_eth3),
			.data_in(rx_fifo_data_in_eth3),
			.wr_en(rx_fifo_wr_en_eth3),

			.rd_clk(clk_64MHz),
			.rd_en(rx_fifo_rd_en_eth3),
			.data_out(rx_fifo_data_out_eth3),
			
			.fifo_full(rx_fifo_full_eth3),
			.fifo_empty(rx_fifo_empty_eth3)
		);

wire 											tx_fifo_wr_en_eth3;
wire [PARAM_MAX_DATA_WIDTH_ETH3 - 1 :0] 		tx_fifo_data_in_eth3;
wire 											tx_fifo_rst_n_eth3;
wire 											tx_fifo_empty_eth3;
wire 											tx_fifo_full_eth3;
wire 											tx_fifo_rd_en_eth3;
wire [PARAM_MAX_DATA_WIDTH_ETH3 - 1 :0]			tx_fifo_data_out_eth3;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH3),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_ETH3)
)tx_fifo_eth3(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.data_in(tx_fifo_data_in_eth3),
			.wr_en(tx_fifo_wr_en_eth3),

			.rd_clk(clk3_125MHz),
			.rd_en(tx_fifo_rd_en_eth3),
			.data_out(tx_fifo_data_out_eth3),
			
			.fifo_full(tx_fifo_full_eth3),
			.fifo_empty(tx_fifo_empty_eth3)
		);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		

parameter integer 	PARAM_MAX_DATA_WIDTH_ETH4 = 8;
parameter 			PARAM_FIFO_SIZE_ETH4 = "18Kb";

wire [10:0] 	rx_eth_corrupt_frame_count_eth4;
wire 			eth_rx_data_valid_eth4;
wire [10:0] 	rx_eth_valid_bytes_eth4;
wire [47:0] 	dest_mac_eth4;
wire [47:0] 	source_mac_eth4;
wire [31:0] 	source_ip_eth4;
wire [31:0] 	dest_ip_eth4;
wire [15:0] 	source_port_eth4;
wire [15:0] 	dest_port_eth4;
wire [10:0] 	tx_payload_length_eth4;

wire 			eth_tx_start_pulse_eth4;
wire 			eth_tx_data_sent_eth4;
wire 			config_done_eth4;

eth u_eth4 (
        .tx_clk                     (clk4_125MHz),
        .rx_clk                     (rx_c_eth4),
        .rst_n                      (rst_n),
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
		.config_done_pulse			(config_done_eth4),
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

wire 											rx_fifo_wr_en_eth4;
wire [PARAM_MAX_DATA_WIDTH_ETH4 - 1 :0] 		rx_fifo_data_in_eth4;
wire 											rx_fifo_rst_n_eth4;
wire 											rx_fifo_empty_eth4;
wire 											rx_fifo_full_eth4;
wire 											rx_fifo_rd_en_eth4;
wire [PARAM_MAX_DATA_WIDTH_ETH4 - 1 :0]			rx_fifo_data_out_eth4;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH4),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_ETH4)
)rx_fifo_eth4(
			
			.rst_n(rx_fifo_rst_n_eth4),
			
			.wr_clk(rx_c_eth4),
			.data_in(rx_fifo_data_in_eth4),
			.wr_en(rx_fifo_wr_en_eth4),

			.rd_clk(clk_64MHz),
			.rd_en(rx_fifo_rd_en_eth4),
			.data_out(rx_fifo_data_out_eth4),
			
			.fifo_full(rx_fifo_full_eth4),
			.fifo_empty(rx_fifo_empty_eth4)
		);

wire 											tx_fifo_wr_en_eth4;
wire [PARAM_MAX_DATA_WIDTH_ETH4 - 1 :0] 		tx_fifo_data_in_eth4;
wire 											tx_fifo_rst_n_eth4;
wire 											tx_fifo_empty_eth4;
wire 											tx_fifo_full_eth4;
wire 											tx_fifo_rd_en_eth4;
wire [PARAM_MAX_DATA_WIDTH_ETH4 - 1 :0]			tx_fifo_data_out_eth4;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH4),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_ETH4)
)tx_fifo_eth4(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.data_in(tx_fifo_data_in_eth4),
			.wr_en(tx_fifo_wr_en_eth4),

			.rd_clk(clk4_125MHz),
			.rd_en(tx_fifo_rd_en_eth4),
			.data_out(tx_fifo_data_out_eth4),
			
			.fifo_full(tx_fifo_full_eth4),
			.fifo_empty(tx_fifo_empty_eth4)
		);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		

parameter integer 	PARAM_MAX_DATA_WIDTH_ETH_NRZ = 8;
parameter 			PARAM_FIFO_SIZE_ETH_NRZ = "18Kb";


wire [47:0] 	dest_mac_eth_nrz;
wire [47:0] 	source_mac_eth_nrz;
wire [31:0] 	source_ip_eth_nrz;
wire [31:0] 	dest_ip_eth_nrz;
wire [15:0] 	source_port_eth_nrz;
wire [15:0] 	dest_port_eth_nrz;
wire [10:0] 	tx_payload_length_eth_nrz;

wire 			eth_tx_start_pulse_eth_nrz;
wire 			eth_tx_data_sent_eth_nrz;
wire 			config_done_eth_nrz;

eth u_eth_nrz (
        .tx_clk                     (clk_nrz_125MHz),
        .rx_clk                     (clk_nrz_125MHz),
        .rst_n                      (rst_n),
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
		.config_done_pulse			(config_done_eth_nrz),
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


wire 											tx_fifo_wr_en_eth_nrz;
wire [PARAM_MAX_DATA_WIDTH_ETH_NRZ - 1 :0] 		tx_fifo_data_in_eth_nrz;
wire 											tx_fifo_rst_n_eth_nrz;
wire 											tx_fifo_empty_eth_nrz;
wire 											tx_fifo_full_eth_nrz;
wire 											tx_fifo_rd_en_eth_nrz;
wire [PARAM_MAX_DATA_WIDTH_ETH_NRZ - 1 :0]			tx_fifo_data_out_eth_nrz;

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(PARAM_MAX_DATA_WIDTH_ETH_NRZ),
				.PARAM_FIFO_SIZE(PARAM_FIFO_SIZE_ETH_NRZ)
)tx_fifo_eth_nrz(
			
			.rst_n(rst_n),
			
			.wr_clk(clk_64MHz),
			.data_in(tx_fifo_data_in_eth_nrz),
			.wr_en(tx_fifo_wr_en_eth_nrz),

			.rd_clk(clk_nrz_125MHz),
			.rd_en(tx_fifo_rd_en_eth_nrz),
			.data_out(tx_fifo_data_out_eth_nrz),
			
			.fifo_full(tx_fifo_full_eth_nrz),
			.fifo_empty(tx_fifo_empty_eth_nrz)
		);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

kernel u_kernel(
			
			.clk(clk_64MHz),
			.clk_uart(clk_44_2368MHz),
			.clk_eth1(clk1_125MHz),
			.clk_eth2(clk2_125MHz),
			.clk_eth3(clk3_125MHz),
			.clk_eth4(clk4_125MHz),
			.clk_eth_nrz(clk_nrz_125MHz),
			.rst_n(rst_n),
			.rx_clk_eth1(rx_c_eth1),
			.rx_clk_eth2(rx_c_eth2),
			.rx_clk_eth3(rx_c_eth3),
			.rx_clk_eth4(rx_c_eth4),
			
			.clk_20MHz(clk_20MHz),
			.data_in_nrz(data_in_nrz),
			.bkp_prg_mode_on(bkp_prg_mode_on),
			.bkp_config_wr_pulse(bkp_config_wr_pulse),
			.bkp_card_id(bkp_card_id),
			.fpga_card_id(fpga_card_id),
			.bkp_data_dir(bkp_data_dir),
			.bkp_address(bkp_address),
			.bkp_data_bus(bkp_data_bus),
			.word_start_strobe_pulse(word_start_strobe_pulse),
			
			.config_done_uart(config_done_uart),
			.config_done_eth1(config_done_eth1),
			.config_done_eth2(config_done_eth2),
			.config_done_eth3(config_done_eth3),
			.config_done_eth4(config_done_eth4),
			.config_done_eth_nrz(config_done_eth_nrz),

			.baudrate_uart1(baudrate_uart1),
			.parity_en_uart1(parity_en_uart1),
			.parity_odd_even_uart1(parity_odd_even_uart1),
			.data_width_uart1(data_width_uart1),
			
			.baudrate_uart2(baudrate_uart2),
			.parity_en_uart2(parity_en_uart2),
			.parity_odd_even_uart2(parity_odd_even_uart2),
			.data_width_uart2(data_width_uart2),
			
			.baudrate_uart3(baudrate_uart3),
			.parity_en_uart3(parity_en_uart3),
			.parity_odd_even_uart3(parity_odd_even_uart3),
			.data_width_uart3(data_width_uart3),
			
			.dest_mac_eth1(dest_mac_eth1),
			.source_mac_eth1(source_mac_eth1),
			.source_ip_eth1(source_ip_eth1),
			.dest_ip_eth1(dest_ip_eth1),
			.source_port_eth1(source_port_eth1),
			.dest_port_eth1(dest_port_eth1),
			.tx_payload_length_eth1(tx_payload_length_eth1),
			
			.dest_mac_eth2(dest_mac_eth2),
			.source_mac_eth2(source_mac_eth2),
			.source_ip_eth2(source_ip_eth2),
			.dest_ip_eth2(dest_ip_eth2),
			.source_port_eth2(source_port_eth2),
			.dest_port_eth2(dest_port_eth2),
			.tx_payload_length_eth2(tx_payload_length_eth2),
			
			.dest_mac_eth3(dest_mac_eth3),
			.source_mac_eth3(source_mac_eth3),
			.source_ip_eth3(source_ip_eth3),
			.dest_ip_eth3(dest_ip_eth3),
			.source_port_eth3(source_port_eth3),
			.dest_port_eth3(dest_port_eth3),
			.tx_payload_length_eth3(tx_payload_length_eth3),
			
			.dest_mac_eth4(dest_mac_eth4),
			.source_mac_eth4(source_mac_eth4),
			.source_ip_eth4(source_ip_eth4),
			.dest_ip_eth4(dest_ip_eth4),
			.source_port_eth4(source_port_eth4),
			.dest_port_eth4(dest_port_eth4),
			.tx_payload_length_eth4(tx_payload_length_eth4),
			
			.dest_mac_eth_nrz(dest_mac_eth_nrz),
			.source_mac_eth_nrz(source_mac_eth_nrz),
			.source_ip_eth_nrz(source_ip_eth_nrz),
			.dest_ip_eth_nrz(dest_ip_eth_nrz),
			.source_port_eth_nrz(source_port_eth_nrz),
			.dest_port_eth_nrz(dest_port_eth_nrz),
			.tx_payload_length_eth_nrz(tx_payload_length_eth_nrz),
			
			.fifo_wr_en_uart1(tx_fifo_wr_en_uart1),
			.fifo_wr_en_uart2(tx_fifo_wr_en_uart2),
			.fifo_wr_en_uart3(tx_fifo_wr_en_uart3),
			.fifo_wr_en_eth1(tx_fifo_wr_en_eth1),
			.fifo_wr_en_eth2(tx_fifo_wr_en_eth2),
			.fifo_wr_en_eth3(tx_fifo_wr_en_eth3),
			.fifo_wr_en_eth4(tx_fifo_wr_en_eth4),
			.fifo_wr_en_eth_nrz(tx_fifo_wr_en_eth_nrz),
			
			.fifo_data_in_uart1(tx_fifo_data_in_uart1),
			.fifo_data_in_uart2(tx_fifo_data_in_uart2),
			.fifo_data_in_uart3(tx_fifo_data_in_uart3),
			.fifo_data_in_eth1(tx_fifo_data_in_eth1),
			.fifo_data_in_eth2(tx_fifo_data_in_eth2),
			.fifo_data_in_eth3(tx_fifo_data_in_eth3),
			.fifo_data_in_eth4(tx_fifo_data_in_eth4),
			.fifo_data_in_eth_nrz(tx_fifo_data_in_eth_nrz),
			
			.tx_acq_start_uart1(tx_acq_start_uart1),
			.tx_acq_start_uart2(tx_acq_start_uart2),
			.tx_acq_start_uart3(tx_acq_start_uart3),
			.eth_tx_start_pulse_eth1(eth_tx_start_pulse_eth1),
			.eth_tx_start_pulse_eth2(eth_tx_start_pulse_eth2),
			.eth_tx_start_pulse_eth3(eth_tx_start_pulse_eth3),
			.eth_tx_start_pulse_eth4(eth_tx_start_pulse_eth4),
			.eth_tx_start_pulse_eth_nrz(eth_tx_start_pulse_eth_nrz),
			
			.rx_fifo_data_out_uart1(rx_fifo_data_out_uart1),
			.rx_fifo_data_out_uart2(rx_fifo_data_out_uart2),
			.rx_fifo_data_out_uart3(rx_fifo_data_out_uart3),
			.rx_fifo_data_out_eth1(rx_fifo_data_out_eth1),
			.rx_fifo_data_out_eth2(rx_fifo_data_out_eth2),
			.rx_fifo_data_out_eth3(rx_fifo_data_out_eth3),
			.rx_fifo_data_out_eth4(rx_fifo_data_out_eth4),
			
			.uart1_rx_valid_count(rx_valid_byte_count_uart1),
			.uart2_rx_valid_count(rx_valid_byte_count_uart2),
			.uart3_rx_valid_count(rx_valid_byte_count_uart3),
			.rx_eth_valid_bytes_eth1(rx_eth_valid_bytes_eth1),
			.rx_eth_valid_bytes_eth2(rx_eth_valid_bytes_eth2),
			.rx_eth_valid_bytes_eth3(rx_eth_valid_bytes_eth3),
			.rx_eth_valid_bytes_eth4(rx_eth_valid_bytes_eth4),
			
			.uart1_rx_corrupt_count(rx_corrupt_byte_count_uart1),
			.uart2_rx_corrupt_count(rx_corrupt_byte_count_uart2),
			.uart3_rx_corrupt_count(rx_corrupt_byte_count_uart3),
			.rx_eth_corrupt_frame_count_eth1(rx_eth_corrupt_frame_count_eth1),
			.rx_eth_corrupt_frame_count_eth2(rx_eth_corrupt_frame_count_eth2),
			.rx_eth_corrupt_frame_count_eth3(rx_eth_corrupt_frame_count_eth3),
			.rx_eth_corrupt_frame_count_eth4(rx_eth_corrupt_frame_count_eth4),
			
			.tx_fifo_full_uart1(tx_fifo_full_uart1),
			.tx_fifo_full_uart2(tx_fifo_full_uart2),
			.tx_fifo_full_uart3(tx_fifo_full_uart3),
			.tx_fifo_full_eth1(tx_fifo_full_eth1),
			.tx_fifo_full_eth2(tx_fifo_full_eth2),
			.tx_fifo_full_eth3(tx_fifo_full_eth3),
			.tx_fifo_full_eth4(tx_fifo_full_eth4),
			.tx_fifo_full_eth_nrz(tx_fifo_full_eth_nrz),
			
			.rx_fifo_full_uart1(rx_fifo_full_uart1),
			.rx_fifo_full_uart2(rx_fifo_full_uart2),
			.rx_fifo_full_uart3(rx_fifo_full_uart3),
			.rx_fifo_full_eth1(rx_fifo_full_eth1),
			.rx_fifo_full_eth2(rx_fifo_full_eth2),
			.rx_fifo_full_eth3(rx_fifo_full_eth3),
			.rx_fifo_full_eth4(rx_fifo_full_eth4),
			
			.tx_fifo_empty_uart1(tx_fifo_empty_uart1),
			.tx_fifo_empty_uart2(tx_fifo_empty_uart2),
			.tx_fifo_empty_uart3(tx_fifo_empty_uart3),
			.tx_fifo_empty_eth1(tx_fifo_empty_eth1),
			.tx_fifo_empty_eth2(tx_fifo_empty_eth2),
			.tx_fifo_empty_eth3(tx_fifo_empty_eth3),
			.tx_fifo_empty_eth4(tx_fifo_empty_eth4),
			.tx_fifo_empty_eth_nrz(tx_fifo_empty_eth_nrz),
			
			.rx_fifo_empty_uart1(rx_fifo_empty_uart1),
			.rx_fifo_empty_uart2(rx_fifo_empty_uart2),
			.rx_fifo_empty_uart3(rx_fifo_empty_uart3),
			.rx_fifo_empty_eth1(rx_fifo_empty_eth1),
			.rx_fifo_empty_eth2(rx_fifo_empty_eth2),
			.rx_fifo_empty_eth3(rx_fifo_empty_eth3),
			.rx_fifo_empty_eth4(rx_fifo_empty_eth4),
			
			.rx_fifo_rd_en_uart1(rx_fifo_rd_en_uart1),
			.rx_fifo_rd_en_uart2(rx_fifo_rd_en_uart2),
			.rx_fifo_rd_en_uart3(rx_fifo_rd_en_uart3),
			.rx_fifo_rd_en_eth1(rx_fifo_rd_en_eth1),
			.rx_fifo_rd_en_eth2(rx_fifo_rd_en_eth2),
			.rx_fifo_rd_en_eth3(rx_fifo_rd_en_eth3),
			.rx_fifo_rd_en_eth4(rx_fifo_rd_en_eth4),
			
			.eth_tx_data_sent_eth1(eth_tx_data_sent_eth1),
			.eth_tx_data_sent_eth2(eth_tx_data_sent_eth2),
			.eth_tx_data_sent_eth3(eth_tx_data_sent_eth3),
			.eth_tx_data_sent_eth4(eth_tx_data_sent_eth4),
			.eth_tx_data_sent_eth_nrz(eth_tx_data_sent_eth_nrz)
);





endmodule

`default_nettype wire