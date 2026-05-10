/*
module eth_mac_tx(
            
            input               clk,
            input               rst_n,
            
            output [3:0]        txd,
            output              tx_ctl,
            output              tx_c,
            
            input               config_done_pulse,
            
            input               eth_tx_start_pulse,
            
            input [47:0]        dest_mac_in,
            input [47:0]        source_mac_in,
            
            input [31:0]        source_ip_in,
            input [31:0]        dest_ip_in,
            
            input [15:0]        source_port_in,
            input [15:0]        dest_port_in,
            
            input [10:0]        payload_length,
            
            output              payload_fifo_rd_en,
            input               payload_fifo_empty,
            input [7:0]         payload_fifo_data_out,
            
            output              eth_tx_data_sent
            
            );

wire [15:0] udp_length_in;
assign udp_length_in = payload_length + 16'd8;
wire [15:0] ipv4_total_length_in;
assign ipv4_total_length_in = payload_length + 16'd28;
wire [15:0] eth_frame_length;
assign eth_frame_length = payload_length + 16'd54;

wire        udp_checksum_done;
wire [15:0] udp_checksum;

wire        udp_payload_rd_en;
wire        udp_payload_valid;
wire [7:0]  udp_payload;
wire        udp_payload_last;

wire        eth_frame_ready_pulse;
wire        int_fifo_full;
wire [7:0]  int_fifo_data_in;
wire        int_fifo_wr_en;
wire        int_fifo_rd_en;
wire [7:0]  int_fifo_data_out;
wire        int_fifo_empty;

wire [7:0]  data_out_crc;
wire        crc_first;
wire        crc_valid;
wire        crc_last;
wire        crc_done_flag;
wire [31:0] crc_out;
wire        crc_done_pulse;

wire        tx_en;
wire        udp_checksum_read_ack;

udp_checksum_calculator u_udp_checksum_calculator (
    .clk                         (clk),
    .rst_n                       (rst_n),
    .config_done_pulse           (config_done_pulse),
    .udp_checksum_read_ack       (udp_checksum_read_ack),
    .udp_checksum_done           (udp_checksum_done),
    .udp_checksum                (udp_checksum),
    .udp_payload_rd_en      (udp_payload_rd_en),
    .udp_payload_valid (udp_payload_valid),
    .udp_payload                 (udp_payload),
    .udp_payload_last (udp_payload_last),
    .source_port_in              (source_port_in),
    .dest_port_in                (dest_port_in),
    .source_ip_in                (source_ip_in),
    .dest_ip_in                  (dest_ip_in),
    .protocol_in                 (8'h11),
    .udp_length_in               (udp_length_in),
    .ext_fifo_rd_en              (payload_fifo_rd_en),
    .ext_fifo_empty              (payload_fifo_empty),
    .ext_fifo_data_out           (payload_fifo_data_out)
);

eth_tx_frame_maker u_eth_tx_frame_maker (
    .clk                         (clk),
    .rst_n                       (rst_n),
    .config_done_pulse           (config_done_pulse),
    .udp_checksum_read_ack       (udp_checksum_read_ack),
    .udp_checksum_done           (udp_checksum_done),
    .udp_payload_rd_en      (udp_payload_rd_en),
    .udp_payload_valid (udp_payload_valid),
    .udp_payload_in              (udp_payload),
    .udp_payload_last (udp_payload_last),
    .eth_frame_ready_pulse       (eth_frame_ready_pulse),
    .fifo_full                   (int_fifo_full),
    .data_out_fifo               (int_fifo_data_in),
    .fifo_wr_en                  (int_fifo_wr_en),
    .data_out_crc                (data_out_crc),
    .crc_first                   (crc_first),
    .crc_valid                   (crc_valid),
    .crc_last                    (crc_last),
    .crc_done_flag               (crc_done_flag),
    .crc_out_in                  (crc_out),
    .dest_mac_in                 (dest_mac_in),
    .source_mac_in               (source_mac_in),
    .eth_type_in                 (16'h08_00),
    .version_in                  (4'h4),
    .header_length_in            (4'h5),
    .type_of_service_in          (8'h08),
    .ipv4_total_length_in        (ipv4_total_length_in),
    .identification_in           (16'h00_00),
    .flags_in                    (3'b010),
    .fragment_offset_in          (13'd0),
    .time_to_live_in             (8'h40),
    .protocol_in                 (8'h11),
    .source_ip_in                (source_ip_in),
    .dest_ip_in                  (dest_ip_in),
    .source_port_in              (source_port_in),
    .dest_port_in                (dest_port_in),
    .udp_length_in               (udp_length_in),
    .udp_checksum_in             (udp_checksum)
);

crc32_data8 u_crc32_data8 (
    .clk             (clk),
    .rst_n           (rst_n),
    .crc_start_flag  (crc_first),
    .crc_valid_flag  (crc_valid),
    .crc_last_flag   (crc_last),
    .data_in         (data_out_crc),
    .crc_out         (crc_out),
    .crc_done_pulse  (crc_done_pulse),
    .crc_done_flag   (crc_done_flag)
);

eth_tx_IF u_eth_tx_IF (
    .clk                   (clk),
    .rst_n                 (rst_n),
    .eth_frame_ready_pulse (udp_checksum_done),
    .eth_tx_start_pulse    (eth_tx_start_pulse),
    .eth_tx_data_sent      (eth_tx_data_sent),
    .tx_en                 (tx_en),
    .eth_frame_length      (eth_frame_length),
    .tx_fifo_rd_en         (int_fifo_rd_en)
);

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(8),
        .PARAM_FIFO_SIZE("18Kb")
) tx_int_fifo (
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

oddr_tx u_oddr_tx (
    .clk     (clk),
    .rst_n   (rst_n),
    .data_in (int_fifo_data_out),
    .tx_en   (tx_en),
    .ddr_out (txd),
    .tx_ctl  (tx_ctl),
    .tx_c    (tx_c)
);

endmodule*/

module eth_mac_tx(
            
            input               clk,
            input               rst_n,
            
            output [3:0]        txd,
            output              tx_ctl,
            output              tx_c,
            
            input               config_done_pulse,
            
            input               eth_tx_start_pulse,
            
            input [47:0]        dest_mac_in,
            input [47:0]        source_mac_in,
            
            input [31:0]        source_ip_in,
            input [31:0]        dest_ip_in,
            
            input [15:0]        source_port_in,
            input [15:0]        dest_port_in,
            
            input [10:0]        payload_length,
            
            output              payload_fifo_rd_en,
            input               payload_fifo_empty,
            input [7:0]         payload_fifo_data_out,
            
            output              eth_tx_data_sent
            
            );

wire [15:0] udp_length_in;
assign udp_length_in = payload_length + 16'd8;
wire [15:0] ipv4_total_length_in;
assign ipv4_total_length_in = payload_length + 16'd28;
wire [15:0] eth_frame_length;
assign eth_frame_length = payload_length + 16'd54;

wire        udp_checksum_done;
wire [15:0] udp_checksum;

wire        udp_payload_rd_en;
wire        udp_payload_valid;
wire [7:0]  udp_payload;
wire        udp_payload_last;

wire        eth_frame_ready_pulse;
wire        int_fifo_full;
wire [7:0]  int_fifo_data_in;
wire        int_fifo_wr_en;
wire        int_fifo_rd_en;
wire [7:0]  int_fifo_data_out;
wire        int_fifo_empty;

wire [7:0]  data_out_crc;
wire        crc_first;
wire        crc_valid;
wire        crc_last;
wire        crc_done_flag;
wire [31:0] crc_out;
wire        crc_done_pulse;

wire        tx_en;
wire        udp_checksum_read_ack;

udp_checksum_calculator u_udp_checksum_calculator (
    .clk                         (clk),
    .rst_n                       (rst_n),
    .config_done_pulse           (config_done_pulse),
    .udp_checksum_read_ack       (udp_checksum_read_ack),
    .udp_checksum_done           (udp_checksum_done),
    .udp_checksum                (udp_checksum),
    .udp_payload_rd_en      (udp_payload_rd_en),
    .udp_payload_valid (udp_payload_valid),
    .udp_payload                 (udp_payload),
    .udp_payload_last (udp_payload_last),
    .source_port_in              (source_port_in),
    .dest_port_in                (dest_port_in),
    .source_ip_in                (source_ip_in),
    .dest_ip_in                  (dest_ip_in),
    .protocol_in                 (8'h11),
    .udp_length_in               (udp_length_in),
    .ext_fifo_rd_en              (payload_fifo_rd_en),
    .ext_fifo_empty              (payload_fifo_empty),
    .ext_fifo_data_out           (payload_fifo_data_out)
);

eth_tx_frame_maker u_eth_tx_frame_maker (
    .clk                         (clk),
    .rst_n                       (rst_n),
    .config_done_pulse           (config_done_pulse),
    .udp_checksum_read_ack       (udp_checksum_read_ack),
    .udp_checksum_done           (udp_checksum_done),
    .udp_payload_rd_en      (udp_payload_rd_en),
    .udp_payload_valid (udp_payload_valid),
    .udp_payload_in              (udp_payload),
    .udp_payload_last (udp_payload_last),
    .eth_frame_ready_pulse       (eth_frame_ready_pulse),
    .fifo_full                   (int_fifo_full),
    .data_out_fifo               (int_fifo_data_in),
    .fifo_wr_en                  (int_fifo_wr_en),
    .data_out_crc                (data_out_crc),
    .crc_first                   (crc_first),
    .crc_valid                   (crc_valid),
    .crc_last                    (crc_last),
    .crc_done_flag               (crc_done_flag),
    .crc_out_in                  (crc_out),
    .dest_mac_in                 (dest_mac_in),
    .source_mac_in               (source_mac_in),
    .eth_type_in                 (16'h08_00),
    .version_in                  (4'h4),
    .header_length_in            (4'h5),
    .type_of_service_in          (8'h08),
    .ipv4_total_length_in        (ipv4_total_length_in),
    .identification_in           (16'h00_00),
    .flags_in                    (3'b010),
    .fragment_offset_in          (13'd0),
    .time_to_live_in             (8'h40),
    .protocol_in                 (8'h11),
    .source_ip_in                (source_ip_in),
    .dest_ip_in                  (dest_ip_in),
    .source_port_in              (source_port_in),
    .dest_port_in                (dest_port_in),
    .udp_length_in               (udp_length_in),
    .udp_checksum_in             (udp_checksum)
);

crc32_data8 u_crc32_data8 (
    .clk             (clk),
    .rst_n           (rst_n),
    .crc_start_flag  (crc_first),
    .crc_valid_flag  (crc_valid),
    .crc_last_flag   (crc_last),
    .data_in         (data_out_crc),
    .crc_out         (crc_out),
    .crc_done_pulse  (crc_done_pulse),
    .crc_done_flag   (crc_done_flag)
);

eth_tx_IF u_eth_tx_IF (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .udp_checksum_done_pulse(udp_checksum_done),
    .eth_tx_start_pulse     (eth_tx_start_pulse),
    .eth_tx_data_sent       (eth_tx_data_sent),
    .tx_en                  (tx_en),
    .eth_frame_length       (eth_frame_length),
    .tx_fifo_rd_en          (int_fifo_rd_en)
);

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(8),
        .PARAM_FIFO_SIZE("18Kb")
) tx_int_fifo (
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

oddr_tx u_oddr_tx (
    .clk     (clk),
    .rst_n   (rst_n),
    .data_in (int_fifo_data_out),
    .tx_en   (tx_en),
    .ddr_out (txd),
    .tx_ctl  (tx_ctl),
    .tx_c    (tx_c)
);

endmodule