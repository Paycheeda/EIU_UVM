
/*


module udp_checksum_calculator(
			input clk,
			input rst_n,
			
			output reg 	udp_checksum_done,
			input 		udp_checksum_read_ack,
			input 		config_done_pulse,
			output reg [15:0] udp_checksum,
			
			input read_udp_payload_pulse,
			output reg udp_payload_byte_done_pulse,
			output reg[7:0] udp_payload,
			
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
assign udp_payload_length = (udp_length_in >= 16'd8) ? (udp_length_in - 16'd8) : 16'd0;	

/////////////////////////////// declarations for CHECKSUM CALCULATOR FSM ///////////////////////////////////


reg[10:0] payload_byte_counter;
reg[15:0] payload_word;

reg second_byte_valid;

reg[16:0] temp_checksum;
reg[31:0] udp_checksum_accum;
reg[1:0]  ext_fifo_rd_en_pipe;
reg[10:0] payload_byte_req_counter;

reg int_fifo_wr_en;
reg[7:0] int_fifo_data_in;

reg[2:0] state_checksum;

localparam CHECKSUM_IDLE = 3'd0;
localparam FIFO_NEXT_WORD_WAIT_STATE = 3'd1;
localparam FINAL_CHECKSUM_CALC_STATE = 3'd2;
localparam FINAL_CARRY_FOLD_STATE = 3'd3;
localparam CHECKSUM_BIT_INVERSION_STATE = 3'd4;
localparam CHECKSUM_ACQ_DONE_STATE = 3'd5;

////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////// declarations for INT FIFO READ FSM ////////////////////////////////////////


reg int_fifo_rd_en;
wire int_fifo_empty;
wire[7:0] int_fifo_data_out;

reg[1:0] state_payload;

localparam PAYLOAD_IDLE = 2'd0;
localparam INT_FIFO_WAIT_STATE = 2'd1;
localparam INT_FIFO_BYTE_READ_STATE = 2'd2;
localparam PAYLOAD_ACQ_DONE_STATE = 2'd3;


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
		udp_checksum_done <= 0;
		udp_checksum_accum <= 0;
		payload_byte_counter <= 0;
		second_byte_valid <= 0;
		state_checksum <= CHECKSUM_IDLE;
		ext_fifo_rd_en_pipe <= 0;
		payload_byte_req_counter <= 0;
	end
	else
	begin
		ext_fifo_rd_en <= 0;
		int_fifo_wr_en <= 0;
		ext_fifo_rd_en_pipe <= {ext_fifo_rd_en_pipe[0], ext_fifo_rd_en};
		
		if(config_done_pulse)
		begin
			udp_checksum_accum <= source_ip_in[31:16] + source_ip_in[15:0] + dest_ip_in[31:16] + dest_ip_in[15:0] + 
										{8'd0, protocol_in} + udp_length_in + source_port_in + dest_port_in + 16'd0 + udp_length_in;
			payload_word <= 0;
			temp_checksum <= 0;
			udp_checksum <= 0;
			udp_checksum_done <= 0;
			payload_byte_counter <= 0;
			payload_byte_req_counter <= 0;
			second_byte_valid <= 0;
			ext_fifo_rd_en_pipe <= 0;
			if(udp_payload_length == 0)
			begin
				state_checksum <= FINAL_CHECKSUM_CALC_STATE;
			end
			else
			begin
				state_checksum <= FIFO_NEXT_WORD_WAIT_STATE;
			end
		end		
		else
		begin
			case(state_checksum)
				CHECKSUM_IDLE:
				begin
					ext_fifo_rd_en <= 0;
					int_fifo_wr_en <= 0;
					state_checksum <= CHECKSUM_IDLE;
					if(udp_checksum_read_ack)
					begin
						udp_checksum_done <= 0;
					end
				end
				
				FIFO_NEXT_WORD_WAIT_STATE:
				begin
					if((payload_byte_req_counter < udp_payload_length) && !ext_fifo_empty)
					begin
						ext_fifo_rd_en <= 1;
						payload_byte_req_counter <= payload_byte_req_counter + 1;
					end	
					if(ext_fifo_rd_en_pipe[0])
					begin
						int_fifo_wr_en <= 1;
						int_fifo_data_in <= ext_fifo_data_out;
						payload_byte_counter <= payload_byte_counter + 1;
						if(!second_byte_valid)
						begin
							payload_word[15:8] <= ext_fifo_data_out;
							payload_word[7:0]  <= 8'd0;
							if((payload_byte_counter + 1) == udp_payload_length)
							begin
								udp_checksum_accum <= udp_checksum_accum + {ext_fifo_data_out, 8'd0};
								second_byte_valid <= 0;
								state_checksum <= FINAL_CHECKSUM_CALC_STATE;
							end
							else
							begin
								second_byte_valid <= 1;
								state_checksum <= FIFO_NEXT_WORD_WAIT_STATE;
							end
						end
						else
						begin
							payload_word[7:0] <= ext_fifo_data_out;
							udp_checksum_accum <= udp_checksum_accum + {payload_word[15:8], ext_fifo_data_out};
							second_byte_valid <= 0;
							if((payload_byte_counter + 1) == udp_payload_length)
							begin
								state_checksum <= FINAL_CHECKSUM_CALC_STATE;
							end
							else
							begin
								state_checksum <= FIFO_NEXT_WORD_WAIT_STATE;
							end
						end
					end
					else
					begin
						state_checksum <= FIFO_NEXT_WORD_WAIT_STATE;
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
					udp_checksum <= ~(temp_checksum[15:0] + temp_checksum[16]);
					state_checksum <= CHECKSUM_ACQ_DONE_STATE;
				end

				CHECKSUM_ACQ_DONE_STATE:
				begin
					ext_fifo_rd_en <= 0;
					int_fifo_wr_en <= 0;
					udp_checksum_done <= 1;
					state_checksum <= CHECKSUM_IDLE;
				end
					
				default:
				begin
					int_fifo_wr_en <= 0;
					ext_fifo_rd_en <= 0;
					udp_checksum_done <= 0;
					state_checksum <= CHECKSUM_IDLE;
				end
			endcase
		end
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


endmodule*/

module udp_checksum_calculator(
			input clk,
			input rst_n,
			
			output reg 	udp_checksum_done,
			input 		udp_checksum_read_ack,
			input 		config_done_pulse,
			output reg [15:0] udp_checksum,
			
			input udp_payload_rd_en,
			output udp_payload_valid,
			output[7:0] udp_payload,
			output udp_payload_last,
			
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
assign udp_payload_length = (udp_length_in >= 16'd8) ? (udp_length_in - 16'd8) : 16'd0;	

/////////////////////////////// declarations for CHECKSUM CALCULATOR FSM ///////////////////////////////////


reg[10:0] payload_byte_counter;
reg[15:0] payload_word;

reg second_byte_valid;

reg[16:0] temp_checksum;
reg[31:0] udp_checksum_accum;
reg[1:0]  ext_fifo_rd_en_pipe;
reg[10:0] payload_byte_req_counter;

reg int_fifo_wr_en;
reg[7:0] int_fifo_data_in;

reg[2:0] state_checksum;

localparam CHECKSUM_IDLE = 3'd0;
localparam FIFO_NEXT_WORD_WAIT_STATE = 3'd1;
localparam FINAL_CHECKSUM_CALC_STATE = 3'd2;
localparam FINAL_CARRY_FOLD_STATE = 3'd3;
localparam CHECKSUM_BIT_INVERSION_STATE = 3'd4;
localparam CHECKSUM_ACQ_DONE_STATE = 3'd5;

////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////// declarations for INT FIFO READ ////////////////////////////////////////


wire int_fifo_rd_en;
wire int_fifo_empty;
wire[7:0] int_fifo_data_out;

reg[10:0] payload_stream_counter;
reg payload_stream_active;

wire payload_byte_pop;
reg payload_stream_started;


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
		udp_checksum_done <= 0;
		udp_checksum_accum <= 0;
		payload_byte_counter <= 0;
		second_byte_valid <= 0;
		state_checksum <= CHECKSUM_IDLE;
		ext_fifo_rd_en_pipe <= 0;
		payload_byte_req_counter <= 0;
	end
	else
	begin
		ext_fifo_rd_en <= 0;
		int_fifo_wr_en <= 0;
		ext_fifo_rd_en_pipe <= {ext_fifo_rd_en_pipe[0], ext_fifo_rd_en};
		
		if(config_done_pulse)
		begin
			udp_checksum_accum <= source_ip_in[31:16] + source_ip_in[15:0] + dest_ip_in[31:16] + dest_ip_in[15:0] + 
										{8'd0, protocol_in} + udp_length_in + source_port_in + dest_port_in + 16'd0 + udp_length_in;
			payload_word <= 0;
			temp_checksum <= 0;
			udp_checksum <= 0;
			udp_checksum_done <= 0;
			payload_byte_counter <= 0;
			payload_byte_req_counter <= 0;
			second_byte_valid <= 0;
			ext_fifo_rd_en_pipe <= 0;
			if(udp_payload_length == 0)
			begin
				state_checksum <= FINAL_CHECKSUM_CALC_STATE;
			end
			else
			begin
				state_checksum <= FIFO_NEXT_WORD_WAIT_STATE;
			end
		end		
		else
		begin
			case(state_checksum)
				CHECKSUM_IDLE:
				begin
					ext_fifo_rd_en <= 0;
					int_fifo_wr_en <= 0;
					state_checksum <= CHECKSUM_IDLE;
					if(udp_checksum_read_ack)
					begin
						udp_checksum_done <= 0;
					end
				end
				
				FIFO_NEXT_WORD_WAIT_STATE:
				begin
					if((payload_byte_req_counter < udp_payload_length) && !ext_fifo_empty)
					begin
						ext_fifo_rd_en <= 1;
						payload_byte_req_counter <= payload_byte_req_counter + 1;
					end	
					if(ext_fifo_rd_en_pipe[0])
					begin
						int_fifo_wr_en <= 1;
						int_fifo_data_in <= ext_fifo_data_out;
						payload_byte_counter <= payload_byte_counter + 1;
						if(!second_byte_valid)
						begin
							payload_word[15:8] <= ext_fifo_data_out;
							payload_word[7:0]  <= 8'd0;
							if((payload_byte_counter + 1) == udp_payload_length)
							begin
								udp_checksum_accum <= udp_checksum_accum + {ext_fifo_data_out, 8'd0};
								second_byte_valid <= 0;
								state_checksum <= FINAL_CHECKSUM_CALC_STATE;
							end
							else
							begin
								second_byte_valid <= 1;
								state_checksum <= FIFO_NEXT_WORD_WAIT_STATE;
							end
						end
						else
						begin
							payload_word[7:0] <= ext_fifo_data_out;
							udp_checksum_accum <= udp_checksum_accum + {payload_word[15:8], ext_fifo_data_out};
							second_byte_valid <= 0;
							if((payload_byte_counter + 1) == udp_payload_length)
							begin
								state_checksum <= FINAL_CHECKSUM_CALC_STATE;
							end
							else
							begin
								state_checksum <= FIFO_NEXT_WORD_WAIT_STATE;
							end
						end
					end
					else
					begin
						state_checksum <= FIFO_NEXT_WORD_WAIT_STATE;
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
					udp_checksum <= ~(temp_checksum[15:0] + temp_checksum[16]);
					state_checksum <= CHECKSUM_ACQ_DONE_STATE;
				end

				CHECKSUM_ACQ_DONE_STATE:
				begin
					ext_fifo_rd_en <= 0;
					int_fifo_wr_en <= 0;
					udp_checksum_done <= 1;
					state_checksum <= CHECKSUM_IDLE;
				end
					
				default:
				begin
					int_fifo_wr_en <= 0;
					ext_fifo_rd_en <= 0;
					udp_checksum_done <= 0;
					state_checksum <= CHECKSUM_IDLE;
				end
			endcase
		end
	end
end

////////////////////// PAYLOAD DATA READING FROM INTERNAL FIFO /////////////////////////////////////

assign udp_payload       = int_fifo_data_out;

assign udp_payload_valid = payload_stream_active &&
                           !int_fifo_empty &&
                           (udp_payload_length != 0);

assign udp_payload_last  = udp_payload_valid &&
                           (payload_stream_counter == (udp_payload_length[10:0] - 11'd1));

assign payload_byte_pop  = udp_payload_valid && udp_payload_rd_en;

assign int_fifo_rd_en = payload_byte_pop;

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		payload_stream_counter <= 0;
		payload_stream_active  <= 0;
		payload_stream_started <= 0;
	end
	else
	begin
		if(config_done_pulse)
		begin
			payload_stream_counter <= 0;
			payload_stream_active  <= 0;
			payload_stream_started <= 0;
		end
		else
		begin
			if(udp_checksum_done && !payload_stream_started && (udp_payload_length != 0))
			begin
				payload_stream_counter <= 0;
				payload_stream_active  <= 1;
				payload_stream_started <= 1;
			end
			else if(payload_byte_pop)
			begin
				if(payload_stream_counter == (udp_payload_length[10:0] - 1))
				begin
					payload_stream_counter <= 0;
					payload_stream_active  <= 0;
				end
				else
				begin
					payload_stream_counter <= payload_stream_counter + 1;
					payload_stream_active  <= 1;
				end
			end
		end
	end
end

dual_port_FIFO#(
				.PARAM_DATA_WIDTH(8),
				.PARAM_FIFO_SIZE("18Kb"),
				.PARAM_FIRST_WORD_FALL_THROUGH("TRUE")
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