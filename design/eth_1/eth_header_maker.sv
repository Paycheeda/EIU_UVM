module eth_header_maker(
		
		input clk,
		input rst_n,
		
		input eth_tx_start_pulse,
		
		output reg eth_header_ready_pulse,
		output reg eth_header_ready_flag,
		
		input fifo_full,
		output reg[7:0] data_out_fifo,
		output reg fifo_wr_en,
		
		output reg[7:0] data_out_crc,
		output reg crc_first,
		output reg crc_valid,
		
		input[47:0] dest_mac_in,
		input[47:0] source_mac_in,
		input[15:0] eth_type_in
		);
		
reg crc_first_word;
reg crc_signal;

reg[3:0] byte_counter;
reg[3:0] max_byte_count;

localparam PARAM_PREAMBLE_WORD = 64'h55_55_55_55_55_55_55_d5;

reg[63:0] preamble_word;
reg[47:0] dest_mac;
reg[47:0] source_mac;
reg[15:0] eth_type;

reg[3:0] state;
reg[3:0] current_word;
reg[3:0] next_word;

localparam IDLE = 4'd0;
localparam PREAMBLE_STATE = 4'd1;
localparam DEST_MAC_STATE = 4'd2;
localparam SOURCE_MAC_STATE = 4'd3;
localparam ETH_TYPE_STATE = 4'd4;
localparam FIFO_DATA_SEND_STATE = 4'd5;
localparam CRC_DATA_SEND_STATE = 4'd6;
localparam BYTE_COUNT_STATE = 4'd7;
localparam ACQ_DONE_STATE = 4'd8;


always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		eth_header_ready_pulse <= 0;
		eth_header_ready_flag <= 0;
		data_out_fifo <= 0;
		fifo_wr_en <= 0;
		data_out_crc <= 0;
		crc_first_word <= 0;
		crc_signal <= 0;
		crc_first <= 0;
		crc_valid <= 0;
		byte_counter <= 0;
		max_byte_count <= 0;
		preamble_word <= 0;
		dest_mac <= 0;
		source_mac <= 0;
		eth_type <= 0;
		current_word <= 0;
		next_word <= 0;
		state <= 0;
	end
	else
	begin
		eth_header_ready_pulse <= 0;
		fifo_wr_en <= 0;
		case(state)
			IDLE:
			begin
				if(eth_tx_start_pulse)
				begin
					preamble_word <= PARAM_PREAMBLE_WORD;
					dest_mac <= dest_mac_in;
					source_mac <= source_mac_in;
					eth_type <= eth_type_in;
					eth_header_ready_flag <= 0;
					data_out_fifo <= 0;
					data_out_crc <= 0;
					crc_first_word <= 0;
					crc_signal <= 0;
					crc_first <= 0;
					crc_valid <= 0;
					byte_counter <= 0;
					max_byte_count <= 0;
					current_word <= 0;
					next_word <= 0;
					state <= PREAMBLE_STATE;
				end
				else
				begin
					state <= IDLE;
				end
			end
			
			PREAMBLE_STATE:
			begin
				data_out_fifo <= preamble_word[63:56];
				preamble_word <= {preamble_word[55:0], 8'd0};
				max_byte_count <= 8;
				crc_signal <= 0;
				current_word <= PREAMBLE_STATE;
				next_word <= DEST_MAC_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			DEST_MAC_STATE:
			begin
				data_out_fifo <= dest_mac[47:40];
				dest_mac <= {dest_mac[39:0], 8'd0};
				max_byte_count <= 6;
				crc_signal <= 1;
				current_word <= DEST_MAC_STATE;
				next_word <= SOURCE_MAC_STATE;
				state <= FIFO_DATA_SEND_STATE;
				if(byte_counter == 0)
				begin
					crc_first_word <= 1;
				end
				else
				begin
					crc_first_word <= 0;
				end
			end
			
			SOURCE_MAC_STATE:
			begin
				data_out_fifo <= source_mac[47:40];
				source_mac <= {source_mac[39:0], 8'd0};
				max_byte_count <= 6;
				crc_signal <= 1;
				current_word <= SOURCE_MAC_STATE;
				next_word <= ETH_TYPE_STATE;
				state <= FIFO_DATA_SEND_STATE;
			end
			
			ETH_TYPE_STATE:
			begin
				data_out_fifo <= eth_type[15:8];
				eth_type <= {eth_type[7:0], 8'd0};
				max_byte_count <= 2;
				crc_signal <= 1;
				current_word <= ETH_TYPE_STATE;
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
				if(crc_signal && crc_first_word)
				begin
					data_out_crc <= data_out_fifo;
					crc_first <= 1;
					crc_valid <= 1;
				end
				else if(crc_signal)
				begin
					data_out_crc <= data_out_fifo;
					crc_valid <= 1;
					crc_first <= 0;
				end
				else
				begin
					crc_first <= 0;
					crc_valid <= 0;
				end
			end
			
			BYTE_COUNT_STATE:
			begin
				crc_first_word <= 0;
				crc_first <= 0;
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
				crc_signal <= 0;
				eth_header_ready_pulse <= 1;
				eth_header_ready_flag <= 1;
				state <= IDLE;
			end
			
			default:
			begin
				crc_signal <= 0;
				crc_first <= 0;
				crc_valid <= 0;
				eth_header_ready_pulse <= 0;
				eth_header_ready_flag <= 0;
				state <= IDLE;
			end
			
			
		endcase
	end
end

endmodule