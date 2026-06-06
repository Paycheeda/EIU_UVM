module eth#(
        parameter IODELAY_GROUP_NAME = "ETH1_IDELAY_GROUP",
		parameter ENABLE_RX = 1,
		parameter integer RXD0_IDELAY_VALUE   = 22,
        parameter integer RXD1_IDELAY_VALUE   = 20,
        parameter integer RXD2_IDELAY_VALUE   = 20,
        parameter integer RXD3_IDELAY_VALUE   = 20,
        parameter integer RXCTL_IDELAY_VALUE  = 20
)(
			
		input 			tx_clk,
		input 			rx_clk,
		input 			rst_n,
		input 			eth_rx_rst_n,
		
		input 			idelay_refclk_200MHz,
		input 			idelay_refclk_locked,
		
		input [3:0] 	rxd,
		input 			rx_ctl,
		
		output 			rx_fifo_wr_en,
		output [7:0] 	rx_fifo_data_in,
		output 			rx_fifo_rst_n,
		
		output [11:0]	rx_eth_corrupt_frame_count,
		output 			eth_rx_data_valid,
		output [11:0] 	rx_eth_valid_bytes,
		
		
		output [3:0] 	txd,
		output 			tx_ctl,
		output 			tx_c,
		
		input 			config_done_pulse,
		input [47:0] 	dest_mac,
		input [47:0] 	source_mac,
		input [31:0]  	source_ip,
		input [31:0]  	dest_ip,
		input [15:0]  	source_port,
		input [15:0]  	dest_port,
		input [10:0] 	tx_payload_length,

		input 			eth_tx_start_pulse,

		output 			tx_fifo_rd_en,
		input 			tx_fifo_empty,
		input [7:0] 	tx_fifo_data_out,

		output 			eth_tx_data_sent,
		
		input [11:0]	count_eth

);

generate
	if (ENABLE_RX) 
	begin : GEN_ETH_RX

		wire idelayctrl_rdy;

		(* IODELAY_GROUP = IODELAY_GROUP_NAME *)
		IDELAYCTRL u_idelayctrl_eth (
			.REFCLK (idelay_refclk_200MHz),
			.RST    (~eth_rx_rst_n),
			.RDY    (idelayctrl_rdy)
		);

		eth_mac_rx #(
			.IODELAY_GROUP_NAME (IODELAY_GROUP_NAME),
			.RXD0_IDELAY_VALUE  (RXD0_IDELAY_VALUE),
			.RXD1_IDELAY_VALUE  (RXD1_IDELAY_VALUE),
			.RXD2_IDELAY_VALUE  (RXD2_IDELAY_VALUE),
			.RXD3_IDELAY_VALUE  (RXD3_IDELAY_VALUE),
			.RXCTL_IDELAY_VALUE (RXCTL_IDELAY_VALUE)
		) u_eth_mac_rx (
			.clk                          (rx_clk),
			.rst_n                        (eth_rx_rst_n),

			.rxd                          (rxd),
			.rx_ctl                       (rx_ctl),

			.rx_fifo_wr_en                (rx_fifo_wr_en),
			.rx_fifo_data_in              (rx_fifo_data_in),
			.rx_fifo_rst_n                (rx_fifo_rst_n),

			.eth_rx_data_valid            (eth_rx_data_valid),
			.corrupt_packet_counter       (rx_eth_corrupt_frame_count),
			.valid_eth_bytes_count        (rx_eth_valid_bytes),
			.count_eth					  (count_eth)
		);

	end 
	else 
	begin : GEN_NO_ETH_RX

		assign rx_fifo_wr_en              = 1'b0;
		assign rx_fifo_data_in            = 8'd0;
		assign rx_fifo_rst_n              = eth_rx_rst_n;

		assign rx_eth_corrupt_frame_count = 12'd0;
		assign eth_rx_data_valid          = 1'b0;
		assign rx_eth_valid_bytes         = 12'd0;

	end
endgenerate
	
	
eth_mac_tx u_eth_mac_tx (
    .clk                   (tx_clk),
    .rst_n                 (rst_n),
	.config_done_pulse	   (config_done_pulse),
    .txd                   (txd),
    .tx_ctl                (tx_ctl),
    .tx_c                  (tx_c),
    .eth_tx_start_pulse    (eth_tx_start_pulse),
    .dest_mac_in           (dest_mac),
    .source_mac_in         (source_mac),
    .source_ip_in          (source_ip),
    .dest_ip_in            (dest_ip),
    .source_port_in        (source_port),
    .dest_port_in          (dest_port),
    .payload_length        (tx_payload_length),
    .payload_fifo_rd_en    (tx_fifo_rd_en),
    .payload_fifo_empty    (tx_fifo_empty),
    .payload_fifo_data_out (tx_fifo_data_out),
    .eth_tx_data_sent      (eth_tx_data_sent)
);


endmodule