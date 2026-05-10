/*module eth_mac_rx(
		
		input 			clk,
		input 			rst_n,
		
		input [3:0] 	rxd,
		input 			rx_ctl,
		
		output 			rx_fifo_wr_en,
		output 			rx_fifo_rst_n,
		output [7:0] 	rx_fifo_data_in,
		
		output 			eth_rx_data_valid,
		output [10:0]	corrupt_packet_counter,
		output [10:0] 	valid_eth_frame
		
	);

wire [7:0] iddr_out;
wire rx_dv;
wire rx_er;

wire crc_first;
wire crc_valid;
wire crc_last;
wire [31:0] crc_calc;
wire crc_done_flag;

wire int_fifo_wr_en;
wire [7:0] int_fifo_data_in;
wire int_fifo_rd_en;
wire [7:0] int_fifo_data_out;

wire [10:0] payload_length;
wire [10:0] invalid_bytes;
wire rx_transaction_done_pulse;
wire packet_received_corrupt_out;

iddr_rx u_iddr_rx (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (rxd),
        .rx_ctl   (rx_ctl),
        .iddr_out (iddr_out),
        .rx_dv    (rx_dv),
        .rx_er    (rx_er)
    );

eth_rx_IF u_eth_rx_IF (
        .clk                         (clk),
        .rst_n                       (rst_n),
        .rxd                         (iddr_out),
        .rx_dv                       (rx_dv),
        .rx_er                       (rx_er),
        .rx_fifo_wr_en               (int_fifo_wr_en),
        .fifo_data_in                (int_fifo_data_in),
        .crc_first                   (crc_first),
        .crc_valid                   (crc_valid),
        .crc_last                    (crc_last),
        .crc_done_flag               (crc_done_flag),
        .crc_calc                    (crc_calc),
		.payload_length              (payload_length),
        .packet_received_corrupt_out (packet_received_corrupt_out),
        .invalid_bytes               (invalid_bytes),
        .rx_transaction_done_pulse   (rx_transaction_done_pulse)
);

crc32_data8 u_crc32_data8 (
        .clk            (clk),
        .rst_n          (rst_n),
        .crc_start_flag (crc_first),
        .crc_valid_flag (crc_valid),
        .crc_last_flag  (crc_last),
        .data_in        (int_fifo_data_in),
        .crc_out        (crc_calc),
        .crc_done_pulse (),
        .crc_done_flag  (crc_done_flag)
);

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(8),
        .PARAM_FIFO_SIZE ("18Kb")
) u_internal_fifo (
        .rst_n      (rst_n),
        .wr_clk     (clk),
        .data_in    (int_fifo_data_in),
        .wr_en      (int_fifo_wr_en),
        .rd_clk     (clk),
        .rd_en      (int_fifo_rd_en),
        .data_out   (int_fifo_data_out),
        .fifo_full  (),
        .fifo_empty ()
);

eth_rx_fifo_IF u_eth_rx_fifo_IF (
        .clk                         	(clk),
        .rst_n                       	(rst_n),
        .eth_rx_data_valid           	(eth_rx_data_valid),
        .payload_length              	(payload_length),
        .rx_fifo_wr_en               	(rx_fifo_wr_en),
        .rx_fifo_data_in             	(rx_fifo_data_in),
        .int_fifo_rd_en              	(int_fifo_rd_en),
        .int_fifo_data_out           	(int_fifo_data_out),
        .rx_transaction_done_pulse   	(rx_transaction_done_pulse),
        .packet_received_corrupt_pulse	(packet_received_corrupt_out),
        .invalid_bytes               	(invalid_bytes),
		.corrupt_packet_counter			(corrupt_packet_counter),
        .ext_fifo_rst_n              	(rx_fifo_rst_n),
		.valid_eth_frame				(valid_eth_frame)
);

endmodule*/
module eth_mac_rx(
                
                input                   clk,
                input                   rst_n,
                
                input [3:0]     rxd,
                input                   rx_ctl,
                
                output                  rx_fifo_wr_en,
                output                  rx_fifo_rst_n,
                output [7:0]    rx_fifo_data_in,
                
                output                  eth_rx_data_valid,
                output [10:0]   corrupt_packet_counter,
                output [10:0]   valid_eth_frame
                
        );

wire [7:0]      iddr_out;
wire            rx_dv;
wire            rx_er;

wire            crc_first;
wire            crc_valid;
wire            crc_last;
wire [31:0] crc_calc;
wire            crc_done_flag;

wire            int_fifo_wr_en;
wire [7:0]      int_fifo_data_in;
wire            int_fifo_rd_en;
wire [7:0]      int_fifo_data_out;
wire            int_fifo_full;
wire            int_fifo_empty;

wire [10:0] payload_length;
wire [10:0] invalid_bytes;
wire            rx_transaction_done_pulse;
wire            packet_received_corrupt_out;

wire        metadata_fifo_rd_en;
wire [22:0] metadata_fifo_data_out;
wire        metadata_fifo_empty;
wire        metadata_fifo_full;
wire        metadata_overflow_pulse;

iddr_rx u_iddr_rx (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (rxd),
        .rx_ctl   (rx_ctl),
        .iddr_out (iddr_out),
        .rx_dv    (rx_dv),
        .rx_er    (rx_er)
    );

eth_rx_IF u_eth_rx_IF (
        .clk                         (clk),
        .rst_n                       (rst_n),
        .rxd                         (iddr_out),
        .rx_dv                       (rx_dv),
        .rx_er                       (rx_er),
        .rx_fifo_wr_en               (int_fifo_wr_en),
        .fifo_data_in                (int_fifo_data_in),
        .crc_first                   (crc_first),
        .crc_valid                   (crc_valid),
        .crc_last                    (crc_last),
        .crc_done_flag               (crc_done_flag),
        .crc_calc                    (crc_calc),
                .payload_length              (payload_length),
        .packet_received_corrupt_out (packet_received_corrupt_out),
        .invalid_bytes               (invalid_bytes),
        .rx_transaction_done_pulse   (rx_transaction_done_pulse)
);

crc32_data8 u_crc32_data8 (
        .clk            (clk),
        .rst_n          (rst_n),
        .crc_start_flag (crc_first),
        .crc_valid_flag (crc_valid),
        .crc_last_flag  (crc_last),
        .data_in        (int_fifo_data_in),
        .crc_out        (crc_calc),
        .crc_done_pulse (),
        .crc_done_flag  (crc_done_flag)
);

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(8),
        .PARAM_FIFO_SIZE ("36Kb")
) u_internal_fifo (
        .rst_n      (rst_n),
        .wr_clk     (clk),
        .data_in    (int_fifo_data_in),
        .wr_en      (int_fifo_wr_en),
        .rd_clk     (clk),
        .rd_en      (int_fifo_rd_en),
        .data_out   (int_fifo_data_out),
        .fifo_full  (int_fifo_full),
        .fifo_empty (int_fifo_empty)
);

eth_rx_fifo_IF u_eth_rx_fifo_IF (
        .clk                    (clk),
        .rst_n                  (rst_n),

        .metadata_fifo_empty    (metadata_fifo_empty),
        .metadata_fifo_rd_en    (metadata_fifo_rd_en),
        .metadata_fifo_data_out (metadata_fifo_data_out),

        .eth_rx_data_valid      (eth_rx_data_valid),
        .valid_eth_frame        (valid_eth_frame),

        .rx_fifo_wr_en          (rx_fifo_wr_en),
        .rx_fifo_data_in        (rx_fifo_data_in),

        .int_fifo_rd_en         (int_fifo_rd_en),
        .int_fifo_data_out      (int_fifo_data_out),

        .corrupt_packet_counter (corrupt_packet_counter),

        .ext_fifo_rst_n         (rx_fifo_rst_n)
);

eth_rx_metadata u_eth_rx_metadata (
        .clk                          (clk),
        .rst_n                        (rst_n),

        .rx_transaction_done_pulse    (rx_transaction_done_pulse),
        .packet_received_corrupt_pulse(packet_received_corrupt_out),
        .payload_length               (payload_length),
        .invalid_bytes                (invalid_bytes),

        .fifo_rd_en                   (metadata_fifo_rd_en),
        .fifo_data_out                (metadata_fifo_data_out),
        .fifo_empty                   (metadata_fifo_empty),
        .fifo_full                    (metadata_fifo_full),

        .metadata_overflow_pulse      (metadata_overflow_pulse)
);

endmodule