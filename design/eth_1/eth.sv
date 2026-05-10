//eth_tx_start_pulse and eth_tx_data_sent timing difference


/*module eth(
			
		input 			tx_clk,
		input 			rx_clk,
		input 			rst_n,
		
		input [3:0] 	rxd,
		input 			rx_ctl,
		
		output 			rx_fifo_wr_en,
		output [7:0] 	rx_fifo_data_in,
		output 			rx_fifo_rst_n,
		
		output [10:0]	rx_eth_corrupt_frame_count,
		output 			eth_rx_data_valid,
		output [10:0] 	rx_eth_valid_bytes,
		
		
		output [3:0] 	txd,
		output 			tx_ctl,
		output 			tx_c,
		
		input [47:0] 	dest_mac,
		input [47:0] 	source_mac,
		input [31:0]  	source_ip,
		input [31:0]  	dest_ip,
		input [15:0]  	source_port,
		input [15:0]  	dest_port,
		input [10:0] 	tx_payload_length,

		input 			eth_tx_start_pulse,
		input 			eth_tx_payload_ack,

		output 			tx_fifo_rd_en,
		input 			tx_fifo_empty,
		input [7:0] 	tx_fifo_data_out,

		output 			eth_tx_data_sent

);


eth_mac_rx u_eth_mac_rx (
    .clk                         	(rx_clk),
    .rst_n                       	(rst_n),
    .rxd                         	(rxd),
    .rx_ctl                      	(rx_ctl),
    .rx_fifo_wr_en               	(rx_fifo_wr_en),
    .rx_fifo_rst_n               	(rx_fifo_rst_n),
    .rx_fifo_data_in             	(rx_fifo_data_in),
    .eth_rx_data_valid           	(eth_rx_data_valid),
    .corrupt_packet_counter			(rx_eth_corrupt_frame_count),
	.valid_eth_frame				(rx_eth_valid_bytes)
);
	
	
eth_mac_tx u_eth_mac_tx (
    .clk                   (tx_clk),
    .rst_n                 (rst_n),
    .txd                   (txd),
    .tx_ctl                (tx_ctl),
    .tx_c                  (tx_c),
    .eth_tx_payload_ack    (eth_tx_payload_ack),
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


endmodule*/

module eth(
			
		input 			tx_clk,
		input 			rx_clk,
		input 			rst_n,
		
		input [3:0] 	rxd,
		input 			rx_ctl,
		
		output 			rx_fifo_wr_en,
		output [7:0] 	rx_fifo_data_in,
		output 			rx_fifo_rst_n,
		
		output [10:0]	rx_eth_corrupt_frame_count,
		output 			eth_rx_data_valid,
		output [10:0] 	rx_eth_valid_bytes,
		
		
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

		input 			eth_tx_start_pulse, //

		output 			tx_fifo_rd_en,
		input 			tx_fifo_empty,
		input [7:0] 	tx_fifo_data_out,

		output 			eth_tx_data_sent//

);


eth_mac_rx u_eth_mac_rx (
    .clk                         	(rx_clk),
    .rst_n                       	(rst_n),
    .rxd                         	(rxd),
    .rx_ctl                      	(rx_ctl),
    .rx_fifo_wr_en               	(rx_fifo_wr_en),
    .rx_fifo_rst_n               	(rx_fifo_rst_n),
    .rx_fifo_data_in             	(rx_fifo_data_in),
    .eth_rx_data_valid           	(eth_rx_data_valid),
    .corrupt_packet_counter			(rx_eth_corrupt_frame_count),
	.valid_eth_frame				(rx_eth_valid_bytes)
);
	
	
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