module eth_tx_frame_maker(

	input clk,
	input rst_n,
	
	input config_done_pulse,
	input eth_tx_data_sent_pulse,
	input udp_checksum_done,
	output reg udp_checksum_read_ack,
	
	output reg udp_payload_rd_en,
	input udp_payload_valid,
	input [7:0] udp_payload_in,
	input udp_payload_last,
	
	output reg eth_frame_ready_pulse,
	
	input fifo_full,
	output reg[7:0] data_out_fifo,
	output reg fifo_wr_en,
	
	output reg[7:0] data_out_crc,
	output reg crc_first,
	output reg crc_valid,
	output reg crc_last,
	input crc_done_flag,
	input [31:0] crc_out_in,
	
	
	input[47:0] dest_mac_in,
	input[47:0] source_mac_in,
	input[15:0] eth_type_in,
	
	input[3:0] version_in,
	input[3:0] header_length_in,
	input[7:0] type_of_service_in,
	input[15:0] ipv4_total_length_in,
	
	input[15:0] identification_in,
	input[2:0] flags_in,
	input[12:0] fragment_offset_in,
		
	input[7:0] time_to_live_in,
	input[7:0] protocol_in,
		
	input[31:0] source_ip_in,
	input[31:0] dest_ip_in,
	
	input[15:0] source_port_in,
	input[15:0] dest_port_in,
	input[15:0] udp_length_in,
	input[15:0] udp_checksum_in
	
	);

wire[15:0] udp_payload_length;


reg[31:0] crc_out;

reg[10:0] byte_counter;

localparam PARAM_PREAMBLE_WORD = 64'h55_55_55_55_55_55_55_d5;

reg[63:0] preamble_word;
reg[47:0] dest_mac;
reg[47:0] source_mac;
reg[15:0] eth_type;
reg[31:0] ipv4_word0;
reg[31:0] ipv4_word1;
reg[31:0] ipv4_word2;
reg[31:0] ipv4_word3;
reg[31:0] ipv4_word4;
reg[15:0] source_port;
reg[15:0] dest_port;
reg[15:0] udp_length;
reg[15:0] udp_checksum;

reg[2:0] state;

localparam IDLE = 3'd0;
localparam STATIC_STREAM_STATE = 3'd1;
localparam UDP_CHECKSUM_DETECT_STATE = 3'd2;
localparam UDP_CHECKSUM_STREAM_STATE = 3'd3;
localparam UDP_PAYLOAD_STREAM_STATE = 3'd4;
localparam CRC_DONE_DETECT_STATE = 3'd5;
localparam CRC_WRITE_STATE = 3'd6;
localparam ACQ_DONE_STATE = 3'd7;

localparam STATIC_STREAM_LAST_BYTE = 11'd47;
localparam UDP_CHECKSUM_BYTE_0 = 11'd48;
localparam UDP_CHECKSUM_BYTE_1 = 11'd49;

localparam CRC_FIRST_BYTE_INDEX = 11'd8;

wire static_stream_fire;
wire udp_checksum_stream_fire;
wire payload_stream_fire;
wire crc_write_fire;

assign static_stream_fire = (state == STATIC_STREAM_STATE) &&!fifo_full;

assign udp_checksum_stream_fire = (state == UDP_CHECKSUM_STREAM_STATE) &&!fifo_full;

assign payload_stream_fire = (state == UDP_PAYLOAD_STREAM_STATE) &&udp_payload_valid &&!fifo_full;

assign crc_write_fire = (state == CRC_WRITE_STATE) &&!fifo_full;

assign udp_payload_length = (udp_length >= 16'd8) ? (udp_length - 16'd8) : 16'd0;

always @ (*)
begin
	data_out_fifo     = 8'd0;
	fifo_wr_en        = 1'b0;
	data_out_crc      = 8'd0;
	crc_first         = 1'b0;
	crc_valid         = 1'b0;
	crc_last          = 1'b0;
	udp_payload_rd_en = 1'b0;
	if(static_stream_fire)
	begin
		data_out_fifo = get_static_frame_byte(byte_counter);
		fifo_wr_en    = 1'b1;
		if(byte_counter >= CRC_FIRST_BYTE_INDEX)
		begin
			data_out_crc = get_static_frame_byte(byte_counter);
			crc_valid    = 1'b1;
			if(byte_counter == CRC_FIRST_BYTE_INDEX)
			begin
				crc_first = 1'b1;
			end
		end
	end
	else if(udp_checksum_stream_fire)
	begin
		data_out_fifo = get_static_frame_byte(byte_counter);
		fifo_wr_en    = 1'b1;
		data_out_crc  = get_static_frame_byte(byte_counter);
		crc_valid     = 1'b1;
		if((byte_counter == UDP_CHECKSUM_BYTE_1) && (udp_payload_length == 0))
		begin
			crc_last = 1'b1;
		end
	end
	else if(payload_stream_fire)
	begin
		data_out_fifo     = udp_payload_in;
		fifo_wr_en        = 1'b1;
		data_out_crc      = udp_payload_in;
		crc_valid         = 1'b1;
		crc_last          = udp_payload_last;
		udp_payload_rd_en = 1'b1;
	end
	else if(crc_write_fire)
	begin
		data_out_fifo = get_crc_byte(byte_counter[1:0]);
		fifo_wr_en    = 1'b1;
	end
end

wire[31:0] ipv4_checksum_accum;
assign ipv4_checksum_accum = {version_in, header_length_in, type_of_service_in} + ipv4_total_length_in + 
							identification_in + {flags_in, fragment_offset_in} +{time_to_live_in, protocol_in} + 
							16'd0 + source_ip_in[31:16] + source_ip_in[15:0] + dest_ip_in[31:16] + dest_ip_in[15:0];

wire[16:0] temp_checksum1;
wire[16:0] temp_checksum2;
assign temp_checksum1 = ipv4_checksum_accum[31:16] + ipv4_checksum_accum[15:0];
assign temp_checksum2 = temp_checksum1[15:0] + temp_checksum1[16];

wire[15:0] ipv4_header_checksum;
assign ipv4_header_checksum = ~(temp_checksum2[15:0] + temp_checksum2[16]);

always @ (posedge clk or negedge rst_n)
begin
if(!rst_n)
begin
	udp_checksum_read_ack      <= 0;
	eth_frame_ready_pulse      <= 0;
	crc_out                    <= 0;
	byte_counter               <= 0;
	preamble_word              <= 0;
	dest_mac                   <= 0;
	source_mac                 <= 0;
	eth_type                   <= 0;
	ipv4_word0                 <= 0;
	ipv4_word1                 <= 0;
	ipv4_word2                 <= 0;
	ipv4_word3                 <= 0;
	ipv4_word4                 <= 0;
	source_port                <= 0;
	dest_port                  <= 0;
	udp_length                 <= 0;
	udp_checksum               <= 0;
	state                      <= IDLE;
	end
	else
	begin
		udp_checksum_read_ack      <= 0;
		eth_frame_ready_pulse      <= 0;
		case(state)
			IDLE:
			begin
				byte_counter       <= 0;
				if(config_done_pulse || eth_tx_data_sent_pulse)
				begin
					preamble_word  <= PARAM_PREAMBLE_WORD;
					dest_mac       <= dest_mac_in;
					source_mac     <= source_mac_in;
					eth_type       <= eth_type_in;
					ipv4_word0     <= {version_in, header_length_in, type_of_service_in, ipv4_total_length_in};
					ipv4_word1     <= {identification_in, flags_in, fragment_offset_in};
					ipv4_word2     <= {time_to_live_in, protocol_in, ipv4_header_checksum};
					ipv4_word3     <= source_ip_in;
					ipv4_word4     <= dest_ip_in;
					source_port    <= source_port_in;
					dest_port      <= dest_port_in;
					udp_length     <= udp_length_in;
					udp_checksum   <= 0;
					state          <= STATIC_STREAM_STATE;
				end
			end

			STATIC_STREAM_STATE:
			begin
				if(static_stream_fire)
				begin
					if(byte_counter < STATIC_STREAM_LAST_BYTE)
					begin
						byte_counter <= byte_counter + 1;
						state        <= STATIC_STREAM_STATE;
					end
					else
					begin
						byte_counter <= UDP_CHECKSUM_BYTE_0;
						state        <= UDP_CHECKSUM_DETECT_STATE;
					end
				end
				else
				begin
					state <= STATIC_STREAM_STATE;
				end
			end
			
			UDP_CHECKSUM_DETECT_STATE:
			begin
				if(udp_checksum_done)
				begin
					udp_checksum_read_ack <= 1;
					udp_checksum          <= udp_checksum_in;
					byte_counter          <= UDP_CHECKSUM_BYTE_0;
					state                 <= UDP_CHECKSUM_STREAM_STATE;
				end
				else
				begin
					state <= UDP_CHECKSUM_DETECT_STATE;
				end
			end
			
			UDP_CHECKSUM_STREAM_STATE:
			begin
				if(udp_checksum_stream_fire)
				begin
					if(byte_counter == UDP_CHECKSUM_BYTE_0)
					begin
						byte_counter <= UDP_CHECKSUM_BYTE_1;
						state        <= UDP_CHECKSUM_STREAM_STATE;
					end
					else
					begin
						byte_counter <= 0;

						if(udp_payload_length == 0)
						begin
							state <= CRC_DONE_DETECT_STATE;
						end
						else
						begin
							state <= UDP_PAYLOAD_STREAM_STATE;
						end
					end
				end
				else
				begin
					state <= UDP_CHECKSUM_STREAM_STATE;
				end
			end
			
			UDP_PAYLOAD_STREAM_STATE:
			begin
				if(payload_stream_fire)
				begin
					if(udp_payload_last)
					begin
						byte_counter <= 0;
						state        <= CRC_DONE_DETECT_STATE;
					end
					else
					begin
						byte_counter <= byte_counter + 1;
						state        <= UDP_PAYLOAD_STREAM_STATE;
					end
				end
				else
				begin
					state <= UDP_PAYLOAD_STREAM_STATE;
				end
			end
			
			CRC_DONE_DETECT_STATE:
			begin
				if(crc_done_flag)
				begin
					crc_out      <= crc_out_in;
					byte_counter <= 0;
					state        <= CRC_WRITE_STATE;
				end
				else
				begin
					state <= CRC_DONE_DETECT_STATE;
				end
			end
			
			CRC_WRITE_STATE:
			begin
				if(crc_write_fire)
				begin
					if(byte_counter == 3)
					begin
						byte_counter <= 0;
						state        <= ACQ_DONE_STATE;
					end
					else
					begin
						byte_counter <= byte_counter + 1;
						state        <= CRC_WRITE_STATE;
					end
				end
				else
				begin
					state <= CRC_WRITE_STATE;
				end
			end
			
			ACQ_DONE_STATE:
			begin
				eth_frame_ready_pulse <= 1;
				byte_counter          <= 0;
				state                 <= IDLE;
			end

			default:
			begin
				state <= IDLE;
			end

		endcase
	end
end



function [7:0] get_static_frame_byte;
	input [10:0] byte_index;
	begin
		case(byte_index)

			// Preamble + SFD
			11'd0  : get_static_frame_byte = preamble_word[63:56];
			11'd1  : get_static_frame_byte = preamble_word[55:48];
			11'd2  : get_static_frame_byte = preamble_word[47:40];
			11'd3  : get_static_frame_byte = preamble_word[39:32];
			11'd4  : get_static_frame_byte = preamble_word[31:24];
			11'd5  : get_static_frame_byte = preamble_word[23:16];
			11'd6  : get_static_frame_byte = preamble_word[15:8];
			11'd7  : get_static_frame_byte = preamble_word[7:0];

			// Destination MAC
			11'd8  : get_static_frame_byte = dest_mac[47:40];
			11'd9  : get_static_frame_byte = dest_mac[39:32];
			11'd10 : get_static_frame_byte = dest_mac[31:24];
			11'd11 : get_static_frame_byte = dest_mac[23:16];
			11'd12 : get_static_frame_byte = dest_mac[15:8];
			11'd13 : get_static_frame_byte = dest_mac[7:0];

			// Source MAC
			11'd14 : get_static_frame_byte = source_mac[47:40];
			11'd15 : get_static_frame_byte = source_mac[39:32];
			11'd16 : get_static_frame_byte = source_mac[31:24];
			11'd17 : get_static_frame_byte = source_mac[23:16];
			11'd18 : get_static_frame_byte = source_mac[15:8];
			11'd19 : get_static_frame_byte = source_mac[7:0];

			// EtherType
			11'd20 : get_static_frame_byte = eth_type[15:8];
			11'd21 : get_static_frame_byte = eth_type[7:0];

			// IPv4 header
			11'd22 : get_static_frame_byte = ipv4_word0[31:24];
			11'd23 : get_static_frame_byte = ipv4_word0[23:16];
			11'd24 : get_static_frame_byte = ipv4_word0[15:8];
			11'd25 : get_static_frame_byte = ipv4_word0[7:0];

			11'd26 : get_static_frame_byte = ipv4_word1[31:24];
			11'd27 : get_static_frame_byte = ipv4_word1[23:16];
			11'd28 : get_static_frame_byte = ipv4_word1[15:8];
			11'd29 : get_static_frame_byte = ipv4_word1[7:0];

			11'd30 : get_static_frame_byte = ipv4_word2[31:24];
			11'd31 : get_static_frame_byte = ipv4_word2[23:16];
			11'd32 : get_static_frame_byte = ipv4_word2[15:8];
			11'd33 : get_static_frame_byte = ipv4_word2[7:0];

			11'd34 : get_static_frame_byte = ipv4_word3[31:24];
			11'd35 : get_static_frame_byte = ipv4_word3[23:16];
			11'd36 : get_static_frame_byte = ipv4_word3[15:8];
			11'd37 : get_static_frame_byte = ipv4_word3[7:0];

			11'd38 : get_static_frame_byte = ipv4_word4[31:24];
			11'd39 : get_static_frame_byte = ipv4_word4[23:16];
			11'd40 : get_static_frame_byte = ipv4_word4[15:8];
			11'd41 : get_static_frame_byte = ipv4_word4[7:0];

			// UDP header before checksum
			11'd42 : get_static_frame_byte = source_port[15:8];
			11'd43 : get_static_frame_byte = source_port[7:0];

			11'd44 : get_static_frame_byte = dest_port[15:8];
			11'd45 : get_static_frame_byte = dest_port[7:0];

			11'd46 : get_static_frame_byte = udp_length[15:8];
			11'd47 : get_static_frame_byte = udp_length[7:0];

			// UDP checksum
			11'd48 : get_static_frame_byte = udp_checksum[15:8];
			11'd49 : get_static_frame_byte = udp_checksum[7:0];

			default: get_static_frame_byte = 8'd0;

		endcase
	end

endfunction

function [7:0] get_crc_byte;
	input [1:0] crc_byte_index;
	begin
		case(crc_byte_index)
			2'd0: get_crc_byte = crc_out[7:0];
			2'd1: get_crc_byte = crc_out[15:8];
			2'd2: get_crc_byte = crc_out[23:16];
			2'd3: get_crc_byte = crc_out[31:24];
			default: get_crc_byte = 8'd0;
		endcase
	end
endfunction


endmodule
