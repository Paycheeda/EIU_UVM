module udp_packet_maker(
			input clk,
			input rst_n,
			
			input ipv4_header_done_pulse,
			
			output reg udp_frame_done_pulse,
			output reg udp_frame_ready_flag,
			
			// ETH TX FRAME FIFO //
			input fifo_full,
			output reg[7:0] data_out_fifo,
			output reg fifo_wr_en,
			
			output reg[7:0] data_out_crc,
			output reg crc_valid,
			output reg crc_last,
			
			input [31:0] crc_out,
			input crc_done_flag,
			
			input[15:0] source_port_in,
			input[15:0] dest_port_in,
			
			// pseudo header parameters
			input[31:0] source_ip_in,
			input[31:0] dest_ip_in,
			input[7:0] protocol_in,
			input[15:0] udp_length_in,
			
			// PAYLOAD FIFO signals //
			output reg ext_fifo_rd_en,	// take the data from FIFO at this pulse
			input ext_fifo_empty,
			input[7:0] ext_fifo_data_out	// FIFO output DATA
							
);

wire[15:0] udp_payload_length;
assign udp_payload_length = udp_length_in - 8;

/////////////////////////////// declarations for FSM ETH TX FIFO ///////////////////////////////////
reg read_udp_payload_pulse;
reg read_udp_checksum_pulse;

reg crc_last_word;
reg crc_signal;

reg[10:0] byte_counter;
reg[10:0] max_byte_count;

reg[15:0] source_port;
reg[15:0] dest_port;
reg[15:0] udp_length;
reg[15:0] udp_checksum_in;
reg[7:0] udp_payload_in;

reg [31:0] crc_out_in;

reg[3:0] state;
reg[3:0] current_word;
reg[3:0] next_word;

localparam IDLE = 4'd0;
localparam SOURCE_PORT_STATE = 4'd1;
localparam DEST_PORT_STATE = 4'd2;
localparam UDP_LENGTH_STATE = 4'd3;
localparam UDP_CHECKSUM_ENABLE_STATE = 4'd4;
localparam UDP_CHECKSUM_DETECT_STATE = 4'd5;
localparam UDP_CHECKSUM_SEND_STATE = 4'd6;
localparam UDP_PAYLOAD_ENABLE_STATE = 4'd7;
localparam UDP_PAYLOAD_DETECT_STATE = 4'd8;
localparam UDP_PAYLOAD_SEND_STATE = 4'd9;
localparam CRC_DONE_DETECT_STATE = 4'd10;
localparam CRC_WRITE_STATE = 4'd11;
localparam FIFO_DATA_SEND_STATE = 4'd12;
localparam CRC_DATA_SEND_STATE = 4'd13;
localparam BYTE_COUNT_STATE = 4'd14;
localparam ACQ_DONE_STATE = 4'd15;
////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////// declarations for CHECKSUM CALCULATOR FSM ///////////////////////////////////

reg udp_checksum_done_pulse;

reg[10:0] payload_byte_counter;
reg[15:0] payload_word;

reg second_byte_valid;

reg[16:0] temp_checksum;
reg[31:0] udp_checksum_accum;
reg[15:0] udp_checksum;

reg int_fifo_wr_en;
reg[7:0] int_fifo_data_in;

reg[3:0] state_checksum;

localparam CHECKSUM_IDLE = 4'd0;
localparam FIFO_WAIT_STATE = 4'd1;
localparam FIFO_FIRST_WORD_READ_STATE = 4'd2;
localparam FIFO_SECOND_WORD_READ_STATE = 4'd3;
localparam FIFO_WRITE1BYTE_STATE = 4'd4;
localparam FIFO_WRITE2BYTE_STATE = 4'd5;
localparam CHECKSUM_CALC_STATE = 4'd6;
localparam FINAL_CHECKSUM_CALC_STATE = 4'd7;
localparam FINAL_CARRY_FOLD_STATE = 4'd8;
localparam CHECKSUM_BIT_INVERSION_STATE = 4'd9;
localparam CHECKSUM_ACQ_DONE_STATE = 4'd10;

////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////// declarations for INT FIFO READ FSM ////////////////////////////////////////
reg udp_payload_byte_done_pulse;
reg[7:0] udp_payload;

reg int_fifo_rd_en;
wire int_fifo_empty;
wire[7:0] int_fifo_data_out;

reg[1:0] state_payload;

localparam PAYLOAD_IDLE = 2'd0;
localparam INT_FIFO_WAIT_STATE = 2'd1;
localparam INT_FIFO_BYTE_READ_STATE = 2'd2;
localparam PAYLOAD_ACQ_DONE_STATE = 2'd3;
/////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////// FSM FOR UDP FRAME WRITE INTO ETH TX FIFO ///////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		udp_frame_done_pulse <= 0;
		udp_frame_ready_flag <= 0;
		read_udp_payload_pulse <= 0;
		read_udp_checksum_pulse <= 0;
		udp_checksum_in <= 0;
		udp_payload_in <= 0;
		data_out_fifo <= 0;
		fifo_wr_en <= 0;
		data_out_crc <= 0;
		crc_out_in <= 0;
		crc_valid <= 0;
		crc_last <= 0;
		crc_last_word <= 0;
		crc_signal <= 0;
		byte_counter <= 0;
		max_byte_count <= 0;
		source_port <= 0;
		dest_port <= 0;
		udp_length <= 0;
		current_word <= 0;
		next_word <= 0;
		state <= 0;
	end
	else
	begin
		read_udp_payload_pulse <= 0;
		read_udp_checksum_pulse <= 0;
		udp_frame_done_pulse <= 0;
		fifo_wr_en <= 0;
		case(state)
			IDLE:
			begin
				if(ipv4_header_done_pulse)
				begin
					source_port <= source_port_in;
					dest_port <= dest_port_in;
					udp_length <= udp_length_in;
					udp_payload_in <= 0;
					udp_frame_ready_flag <= 0;
					data_out_fifo <= 0;
					data_out_crc <= 0;
					crc_valid <= 0;
					crc_last <= 0;
					crc_signal <= 0;
					crc_last_word <= 0;
					byte_counter <= 0;
					max_byte_count <= 0;
					current_word <= 0;
					next_word <= 0;
					state <= SOURCE_PORT_STATE;
				end
				else
				begin
					state <= IDLE;
				end
			end
			
			SOURCE_PORT_STATE:
			begin
				data_out_fifo <= source_port[15:8];
				source_port <= {source_port[7:0], 8'd0};
				max_byte_count <= 2;
				crc_signal <= 1;
				current_word <= SOURCE_PORT_STATE;
				next_word <= DEST_PORT_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			DEST_PORT_STATE:
			begin
				data_out_fifo <= dest_port[15:8];
				dest_port <= {dest_port[7:0], 8'd0};
				max_byte_count <= 2;
				crc_signal <= 1;
				current_word <= DEST_PORT_STATE;
				next_word <= UDP_LENGTH_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			UDP_LENGTH_STATE:
			begin
				data_out_fifo <= udp_length[15:8];
				udp_length <= {udp_length[7:0], 8'd0};
				max_byte_count <= 2;
				crc_signal <= 1;
				current_word <= UDP_LENGTH_STATE;
				next_word <= UDP_CHECKSUM_ENABLE_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			UDP_CHECKSUM_ENABLE_STATE:
			begin
				read_udp_checksum_pulse <= 1;
				state <= UDP_CHECKSUM_DETECT_STATE;
			end
			
			UDP_CHECKSUM_DETECT_STATE:
			begin	
				if(udp_checksum_done_pulse)
				begin
					udp_checksum_in <= udp_checksum;
					state <= UDP_CHECKSUM_SEND_STATE;
				end
				else
				begin
					state <= UDP_CHECKSUM_DETECT_STATE;
				end
			end
			
			UDP_CHECKSUM_SEND_STATE:
			begin
				data_out_fifo <= udp_checksum_in[15:8];
				udp_checksum_in <= {udp_checksum_in[7:0], 8'd0};
				max_byte_count <= 2;
				crc_signal <= 1;
				current_word <= UDP_CHECKSUM_SEND_STATE;
				state <= FIFO_DATA_SEND_STATE;
				if(udp_payload_length != 0)
				begin
					next_word <= UDP_PAYLOAD_ENABLE_STATE;
				end
				else
				begin
					next_word <= CRC_DONE_DETECT_STATE;
					if(byte_counter == 1)
					begin
						crc_last_word <= 1;
					end
					else
					begin
						crc_last_word <= 0;
					end
				end
			end
			
			UDP_PAYLOAD_ENABLE_STATE:
			begin
				read_udp_payload_pulse <= 1;
				state <= UDP_PAYLOAD_DETECT_STATE;
			end
			
			UDP_PAYLOAD_DETECT_STATE:
			begin
				if(udp_payload_byte_done_pulse)
				begin
					udp_payload_in <= udp_payload;
					state <= UDP_PAYLOAD_SEND_STATE;
				end
				else
				begin
					state <= UDP_PAYLOAD_DETECT_STATE;
				end
			end
			
			UDP_PAYLOAD_SEND_STATE:
			begin
				data_out_fifo <= udp_payload_in;
				max_byte_count <= udp_payload_length;
				crc_signal <= 1;
				current_word <= UDP_PAYLOAD_ENABLE_STATE;
				next_word <= CRC_DONE_DETECT_STATE;
				state <= FIFO_DATA_SEND_STATE;
				if(byte_counter == udp_payload_length-1)
				begin
					crc_last_word <= 1;
				end
				else
				begin
					crc_last_word <= 0;
				end
			end
			
			CRC_DONE_DETECT_STATE:
			begin
				if(crc_done_flag)
				begin
					crc_out_in <= crc_out;
					state <= CRC_WRITE_STATE;
				end
				else
				begin
					state <= CRC_DONE_DETECT_STATE;
				end
			end
			
			CRC_WRITE_STATE:
			begin
				data_out_fifo <= crc_out_in[7:0];
				crc_out_in <= {8'd0, crc_out_in[31:8]};
				max_byte_count <= 4;
				crc_signal <= 0;
				current_word <= CRC_WRITE_STATE;
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
				if(crc_last_word && crc_signal)
				begin
					data_out_crc <= data_out_fifo;
					crc_last <= 1;
					crc_valid <= 1;
				end
				else if (crc_signal)
				begin
					data_out_crc <= data_out_fifo;
					crc_last <= 0;
					crc_valid <= 1;
				end
				else
				begin
					crc_last <= 0;
					crc_valid <= 0;
				end
			end
			
			BYTE_COUNT_STATE:
			begin
				crc_last <= 0;
				crc_valid <= 0;
				if(byte_counter < max_byte_count - 1)
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
				udp_frame_ready_flag <= 1;
				udp_frame_done_pulse <= 1;
				state <= IDLE;
			end
			
			default:
			begin
				udp_frame_ready_flag <= 0;
				udp_frame_done_pulse <= 0;
				state <= IDLE;
			end
			
		endcase
	end
end


/////////////////////////// FSM FOR UDP CHECKSUM CALCULATIONS ///////////////////////////////////

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		payload_word <= 0;
		temp_checksum <= 0;
		udp_checksum <= 0;
		ext_fifo_rd_en <= 0;
		int_fifo_wr_en <= 0;
		int_fifo_data_in <= 0;
		udp_checksum_done_pulse <= 0;
		udp_checksum_accum <= 0;
		payload_byte_counter <= 0;
		second_byte_valid <= 0;
		state_checksum <= 0;
	end
	else
	begin
		udp_checksum_done_pulse <= 0;
		int_fifo_wr_en <= 0;
		ext_fifo_rd_en <= 0;
		case(state_checksum)
			CHECKSUM_IDLE:
			begin
				if(read_udp_checksum_pulse)
				begin
					temp_checksum <= 0;
					udp_checksum <= 0;
					udp_checksum_accum <= source_ip_in[31:16] + source_ip_in[15:0] + dest_ip_in[31:16] + dest_ip_in[15:0] + 
									{8'd0, protocol_in} + udp_length_in + source_port_in + dest_port_in + 16'd0 + udp_length_in;
					
					payload_word <= 0;
					payload_byte_counter <= 0;
					second_byte_valid <= 0;
					if(!ext_fifo_empty && udp_payload_length != 0 )
					begin
						ext_fifo_rd_en <= 1;
						state_checksum <= FIFO_WAIT_STATE;
					end
					else
					begin
						ext_fifo_rd_en <= 0;
						state_checksum <= FINAL_CHECKSUM_CALC_STATE;
					end
				end
				else
				begin
					state_checksum <= CHECKSUM_IDLE;
				end
			end
			
			FIFO_WAIT_STATE: 
			begin 
				state_checksum <= FIFO_FIRST_WORD_READ_STATE; 
				if(payload_byte_counter + 1 == udp_payload_length) 
				begin 
					ext_fifo_rd_en <= 0; 
				end 
				else 
				begin 
					ext_fifo_rd_en <= 1; 
				end 
			end
			
			FIFO_FIRST_WORD_READ_STATE:
			begin
				payload_word[15:8] <= ext_fifo_data_out;
				payload_byte_counter <= payload_byte_counter + 1;
				if(payload_byte_counter + 1 == udp_payload_length)
				begin
					second_byte_valid <= 0;
					payload_word[7:0] <= 8'd0;
					state_checksum <= FIFO_WRITE1BYTE_STATE;
				end
				else
				begin
					second_byte_valid <= 1;
					state_checksum <= FIFO_SECOND_WORD_READ_STATE;
				end
			end
			
			FIFO_SECOND_WORD_READ_STATE:
			begin
				second_byte_valid <= 1;
				payload_word[7:0] <= ext_fifo_data_out;
				state_checksum <= FIFO_WRITE1BYTE_STATE;
				payload_byte_counter <= payload_byte_counter + 1;
			end
			
			FIFO_WRITE1BYTE_STATE:
			begin
				int_fifo_wr_en <= 1;
				int_fifo_data_in <= payload_word[15:8];
				if(second_byte_valid)
				begin
					state_checksum <= FIFO_WRITE2BYTE_STATE;
				end
				else
				begin
					state_checksum <= CHECKSUM_CALC_STATE;
				end
			end
			
			FIFO_WRITE2BYTE_STATE:
			begin
				int_fifo_wr_en <= 1;
				int_fifo_data_in <= payload_word[7:0];
				state_checksum <= CHECKSUM_CALC_STATE;
			end
			
			CHECKSUM_CALC_STATE:
			begin
				udp_checksum_accum <= udp_checksum_accum + payload_word;
				if(payload_byte_counter < udp_payload_length)
				begin
					ext_fifo_rd_en <= 1;
					state_checksum <= FIFO_WAIT_STATE;
				end
				else
				begin
					payload_byte_counter <= 0;
					state_checksum <= FINAL_CHECKSUM_CALC_STATE;
				end
			end
			
			FINAL_CHECKSUM_CALC_STATE:
			begin
				temp_checksum <= udp_checksum_accum[31:16] + udp_checksum_accum[15:0];
				state_checksum <= FINAL_CARRY_FOLD_STATE;
			end
			
			FINAL_CARRY_FOLD_STATE:
			begin
				temp_checksum <= temp_checksum[15:0] + temp_checksum[16];
				state_checksum <= CHECKSUM_BIT_INVERSION_STATE;
			end
			
			CHECKSUM_BIT_INVERSION_STATE:
			begin
				udp_checksum <= ~(temp_checksum[15:0]+temp_checksum[16]);
				state_checksum <= CHECKSUM_ACQ_DONE_STATE;
			end
			
			CHECKSUM_ACQ_DONE_STATE:
			begin
				udp_checksum_done_pulse <= 1;
				state_checksum <= CHECKSUM_IDLE;
			end
			
			default:
			begin
				int_fifo_wr_en <= 0;
				ext_fifo_rd_en <= 0;
				udp_checksum_done_pulse <= 0;
				state_checksum <= CHECKSUM_IDLE;
			end
		endcase
	end
end

////////////////////// FSM for PAYLOAD DATA READING FROM INTERNAL FIFO /////////////////////////////////////


always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		udp_payload_byte_done_pulse <= 0;
		udp_payload <= 0;
		int_fifo_rd_en <= 0;
		state_payload <= 0;
	end
	else
	begin
		int_fifo_rd_en <= 0;
		udp_payload_byte_done_pulse <= 0;
		case(state_payload)
			PAYLOAD_IDLE:
			begin
				if(read_udp_payload_pulse)
				begin
					udp_payload <= 0;
					if(!int_fifo_empty)
					begin
						int_fifo_rd_en <= 1;
						state_payload <= INT_FIFO_WAIT_STATE;
					end
					else
					begin
						int_fifo_rd_en <= 0;
						state_payload <= PAYLOAD_IDLE;
					end
				end
			end
			
			INT_FIFO_WAIT_STATE:
			begin 
				state_payload <= INT_FIFO_BYTE_READ_STATE;
				int_fifo_rd_en <= 0;
			end
			
			INT_FIFO_BYTE_READ_STATE:
			begin
				udp_payload <= int_fifo_data_out;
				state_payload <= PAYLOAD_ACQ_DONE_STATE;
			end
			
			PAYLOAD_ACQ_DONE_STATE:
			begin
				udp_payload_byte_done_pulse <= 1;
				state_payload <= PAYLOAD_IDLE;
			end
			
			default:
			begin
				udp_payload_byte_done_pulse <= 0;
				state_payload <= PAYLOAD_IDLE;
			end
		endcase
	end
end

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(8),
				.PARAM_FIFO_SIZE("18Kb")
)int_payload_fifo(
			
			.rst_n(rst_n),
			
			.wr_clk(clk),
			.data_in(int_fifo_data_in),
			.wr_en(int_fifo_wr_en),

			.rd_clk(clk),
			.rd_en(int_fifo_rd_en),
			.data_out(int_fifo_data_out),
			
			.fifo_full(),
			.fifo_empty(int_fifo_empty)
		);


endmodule



			
			
			
			