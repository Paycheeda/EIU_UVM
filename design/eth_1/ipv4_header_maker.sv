module ipv4_header_maker(

			input clk,
			input rst_n,
			
			input eth_header_ready_pulse,
			
			output reg ipv4_header_done_pulse,
			output reg ipv4_header_ready_flag,
			
			input fifo_full,
			output reg[7:0] data_out_fifo,
			output reg fifo_wr_en,
			
			output reg[7:0] data_out_crc,
			output reg crc_valid,
			
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
			input[31:0] dest_ip_in
	);

localparam integer MAX_BYTE_COUNT = 4;

reg[3:0] state;

reg [3:0] current_word;
reg [3:0] next_word;

localparam IDLE = 4'd0;
localparam WORD0_STATE = 4'd1;
localparam WORD1_STATE = 4'd2;
localparam WORD2_STATE = 4'd3;
localparam WORD3_STATE = 4'd4;
localparam WORD4_STATE = 4'd5;
localparam FIFO_DATA_SEND_STATE = 4'd6;
localparam CRC_DATA_SEND_STATE = 4'd7;
localparam BYTE_COUNT_STATE = 4'd8;
localparam ACQ_DONE_STATE = 4'd9;

reg [31:0] word0;
reg [31:0] word1;
reg [31:0] word2;
reg [31:0] word3;
reg [31:0] word4;

reg [2:0] byte_counter;

wire[31:0] ipv4_checksum_accum;
assign ipv4_checksum_accum = {version_in, header_length_in, type_of_service_in} + ipv4_total_length_in +
							identification_in + {flags_in, fragment_offset_in} + 
							{time_to_live_in, protocol_in} + 16'd0 +
							source_ip_in[31:16] + source_ip_in[15:0] + dest_ip_in[31:16] + dest_ip_in[15:0];


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
		ipv4_header_done_pulse <= 0;
		ipv4_header_ready_flag <= 0;
		data_out_fifo <= 0;
		fifo_wr_en <= 0;
		data_out_crc <= 0;
		crc_valid <= 0;
		byte_counter <= 0;
		word0 <= 0;
		word1 <= 0;
		word2 <= 0;
		word3 <= 0;
		word4 <= 0;
		current_word <= 0;
		next_word <= 0;
		state <= 0;
	end
	else
	begin
		ipv4_header_done_pulse <= 0;
		fifo_wr_en <= 0;
		case(state)
			IDLE:
			begin
				if(eth_header_ready_pulse)
				begin
					word0 <= {version_in, header_length_in, type_of_service_in, ipv4_total_length_in};
					word1 <= {identification_in, flags_in, fragment_offset_in};
					word2 <= {time_to_live_in, protocol_in, ipv4_header_checksum};
					word3 <= source_ip_in;
					word4 <= dest_ip_in;					
					ipv4_header_ready_flag <= 0;
					data_out_fifo <= 0;
					data_out_crc <= 0;
					crc_valid <= 0;
					byte_counter <= 0;
					current_word <= 0;
					next_word <= 0;
					state <= WORD0_STATE;
				end
				else
				begin
					state <= IDLE;
				end
			end
			
			WORD0_STATE:
			begin
				data_out_fifo <= word0[31:24];
				word0 <= {word0[23:0], 8'd0};
				current_word <= WORD0_STATE;
				next_word <= WORD1_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			WORD1_STATE:
			begin
				data_out_fifo <= word1[31:24];
				word1 <= {word1[23:0], 8'd0};
				current_word <= WORD1_STATE;
				next_word <= WORD2_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			WORD2_STATE:
			begin
				data_out_fifo <= word2[31:24];
				word2 <= {word2[23:0], 8'd0};
				current_word <= WORD2_STATE;
				next_word <= WORD3_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			WORD3_STATE:
			begin
				data_out_fifo <= word3[31:24];
				word3 <= {word3[23:0], 8'd0};
				current_word <= WORD3_STATE;
				next_word <= WORD4_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			WORD4_STATE:
			begin
				data_out_fifo <= word4[31:24];
				word4 <= {word4[23:0], 8'd0};
				current_word <= WORD4_STATE;
				next_word <= ACQ_DONE_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			FIFO_DATA_SEND_STATE:
			begin
				if(!fifo_full)
				begin
					fifo_wr_en <= 1;
					state <= CRC_DATA_SEND_STATE;
				end
				else
				begin
					fifo_wr_en <= 0;
					state <= FIFO_DATA_SEND_STATE;
				end
			end
			
			CRC_DATA_SEND_STATE:
			begin
				fifo_wr_en <= 0;
				state <= BYTE_COUNT_STATE;
				data_out_crc <= data_out_fifo;
				crc_valid <= 1;
			end
			
			BYTE_COUNT_STATE:
			begin
				crc_valid <= 0;
				if(byte_counter < MAX_BYTE_COUNT - 1)
				begin
					byte_counter <= byte_counter + 1;
					state <= current_word;
				end
				else
				begin
					byte_counter <= 0;
					state <= next_word;
				end
			end
			
			
			ACQ_DONE_STATE:
			begin
				ipv4_header_ready_flag <= 1;
				ipv4_header_done_pulse <= 1;
				state <= IDLE;
			end
			
			default:
			begin
				crc_valid <= 0;
				ipv4_header_done_pulse <= 0;
				ipv4_header_ready_flag <= 0;
				state <= IDLE;
			end
			
		endcase
	end
end



endmodule