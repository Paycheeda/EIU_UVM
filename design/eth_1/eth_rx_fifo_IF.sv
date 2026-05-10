/*module eth_rx_fifo_IF(

			input clk,
			input rst_n,
			
			output reg eth_rx_data_valid,
			
			input [10:0] payload_length,
			
			output reg[10:0] valid_eth_frame,
			
			output reg rx_fifo_wr_en,
			output reg [7:0] rx_fifo_data_in,
			
			output reg int_fifo_rd_en,
			input [7:0] int_fifo_data_out,
			
			input rx_transaction_done_pulse,
			input packet_received_corrupt_pulse,
			input [10:0] invalid_bytes,
			output reg [10:0] corrupt_packet_counter,
			
			output reg ext_fifo_rst_n

		);

reg[10:0] byte_counter;

reg[10:0] bytes_to_remove;
reg[10:0] invalid_byte_counter;

reg[2:0] rst_counter;

reg[2:0] state;

localparam IDLE = 3'd0;
localparam INVALID_BYTE_CHECK_STATE = 3'd1;
localparam INVALID_BYTE_WAIT_STATE = 3'd2;
localparam INVALID_BYTE_COUNT_STATE = 3'd3;
localparam RST_STATE = 3'd4;
localparam WAIT_STATE = 3'd5;
localparam BYTE_ACQ_STATE = 3'd6;
localparam ACQ_DONE_STATE = 3'd7;

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		eth_rx_data_valid <= 0;
		rx_fifo_wr_en <= 0;
		rx_fifo_data_in <= 0;
		byte_counter <= 0;
		valid_eth_frame <= 0;
		invalid_byte_counter <= 0;
		corrupt_packet_counter <= 0;
		bytes_to_remove <= 0;
		int_fifo_rd_en <= 0;
		ext_fifo_rst_n <= 1;
		rst_counter <= 0;
		state <= 0;
	end
	else
	begin
		case(state)
			IDLE:
			begin
				eth_rx_data_valid <= 0;
				invalid_byte_counter <= 0;
				if(rx_transaction_done_pulse)
				begin
					rx_fifo_wr_en <= 0;
					byte_counter <= 0;
					ext_fifo_rst_n <= 1;
					if(!packet_received_corrupt_pulse)
					begin
						valid_eth_frame <= payload_length + 11'd42;
						bytes_to_remove <= 0;
						ext_fifo_rst_n <= 0;
						rst_counter <= 1;
						int_fifo_rd_en <= 0;
						state <= RST_STATE;
					end
					else
					begin
						corrupt_packet_counter <= corrupt_packet_counter + 1;
						rst_counter <= 0;
						bytes_to_remove <= invalid_bytes;
						int_fifo_rd_en <= 0;
						state <= INVALID_BYTE_CHECK_STATE;
					end
				end
				else
				begin
					state <= IDLE;
				end
			end
			
			INVALID_BYTE_CHECK_STATE:
			begin
				invalid_byte_counter <= 0;
				if(bytes_to_remove == 0)
				begin
					int_fifo_rd_en <= 0;
					state <= IDLE;
				end
				else
				begin
					int_fifo_rd_en <= 1;
					state <= INVALID_BYTE_WAIT_STATE;
				end
			end
			
			INVALID_BYTE_WAIT_STATE:
			begin
				if(bytes_to_remove == 11'd1)
				begin
					int_fifo_rd_en <= 0;
					invalid_byte_counter <= 0;
					state <= IDLE;
				end
				else
				begin
					int_fifo_rd_en <= 1;
					invalid_byte_counter <= 11'd1;
					state <= INVALID_BYTE_COUNT_STATE;
				end
			end
			
			INVALID_BYTE_COUNT_STATE:
			begin
				if(invalid_byte_counter < bytes_to_remove - 11'd1)
				begin
					int_fifo_rd_en <= 1;
					invalid_byte_counter <= invalid_byte_counter + 11'd1;
					state <= INVALID_BYTE_COUNT_STATE;
				end
				else
				begin
					int_fifo_rd_en <= 0;
					invalid_byte_counter <= 0;
					state <= IDLE;
				end
			end
			
			RST_STATE:
			begin	
				rst_counter <= rst_counter + 1;
				if(rst_counter < 6)
				begin
					ext_fifo_rst_n <= 0;
					state <= RST_STATE;
				end
				else
				begin
					ext_fifo_rst_n <= 1;
					int_fifo_rd_en <= 1;
					state <= WAIT_STATE;
				end
			end
			
			WAIT_STATE:
			begin
				rx_fifo_wr_en <= 0;
				int_fifo_rd_en <= 1;
				state <= BYTE_ACQ_STATE;
			end
			
			BYTE_ACQ_STATE:
			begin
				rx_fifo_data_in <= int_fifo_data_out;
				rx_fifo_wr_en <= 1;
				if(byte_counter < valid_eth_frame - 2)
				begin
					byte_counter <= byte_counter + 1;
					int_fifo_rd_en <= 1;
					state <= BYTE_ACQ_STATE;
				end
				else if(byte_counter == valid_eth_frame - 2)
				begin
					byte_counter <= byte_counter + 1;
					int_fifo_rd_en <= 0;
					state <= BYTE_ACQ_STATE;
				end
				else
				begin
					int_fifo_rd_en <= 0;
					byte_counter <= 0;
					state <= ACQ_DONE_STATE;
				end
			end
			
			ACQ_DONE_STATE:
			begin
				int_fifo_rd_en <= 0;
				rx_fifo_wr_en <= 0;
				eth_rx_data_valid <= 1;
				state <= IDLE;
			end
			
			default:
			begin
				int_fifo_rd_en <= 0;
				rx_fifo_wr_en <= 0;
				eth_rx_data_valid <= 0;
				state <= IDLE;
			end
			
		endcase
	end
end

endmodule*/
module eth_rx_fifo_IF(

			input clk,
			input rst_n,
			
			input metadata_fifo_empty,
			output reg metadata_fifo_rd_en,
			input [22:0] metadata_fifo_data_out,
			
			output reg eth_rx_data_valid,
			
			output reg[10:0] valid_eth_frame,
			
			output reg rx_fifo_wr_en,
			output reg [7:0] rx_fifo_data_in,
			
			output reg int_fifo_rd_en,
			input [7:0] int_fifo_data_out,
			
			output reg [10:0] corrupt_packet_counter,
			
			output reg ext_fifo_rst_n

		);

reg[10:0] byte_counter;

reg[10:0] bytes_to_remove;
reg[10:0] invalid_byte_counter;

reg[4:0] rst_counter;

reg[3:0] state;

localparam IDLE = 4'd0;
localparam METADATA_FIFO_WAIT_STATE = 4'd1;
localparam METADATA_FIFO_READ_STATE = 4'd2;
localparam INVALID_BYTE_CHECK_STATE = 4'd3;
localparam INVALID_BYTE_WAIT_STATE = 4'd4;
localparam INVALID_BYTE_COUNT_STATE = 4'd5;
localparam RST_STATE = 4'd6;
localparam WAIT_STATE = 4'd7;
localparam BYTE_ACQ_STATE = 4'd8;
localparam ACQ_DONE_STATE = 4'd9;

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		eth_rx_data_valid <= 0;
		rx_fifo_wr_en <= 0;
		rx_fifo_data_in <= 0;
		byte_counter <= 0;
		valid_eth_frame <= 0;
		invalid_byte_counter <= 0;
		corrupt_packet_counter <= 0;
		bytes_to_remove <= 0;
		int_fifo_rd_en <= 0;
		ext_fifo_rst_n <= 0;
		metadata_fifo_rd_en <= 0;
		rst_counter <= 0;
		state <= 0;
	end
	else
	begin
		case(state)
			IDLE:
			begin
				ext_fifo_rst_n <= 1;
				rx_fifo_wr_en <= 0;
				int_fifo_rd_en <= 0;
				metadata_fifo_rd_en <= 0;
				eth_rx_data_valid <= 0;
				invalid_byte_counter <= 0;
				if(!metadata_fifo_empty)
				begin
					metadata_fifo_rd_en <= 1;
					state <= METADATA_FIFO_WAIT_STATE;
				end
				else
				begin
					state <= IDLE;
				end
			end
			
			METADATA_FIFO_WAIT_STATE:
			begin
				metadata_fifo_rd_en <= 0;
				state <= METADATA_FIFO_READ_STATE;
			end
			
			
			METADATA_FIFO_READ_STATE:
			begin					
				rx_fifo_wr_en <= 0;
				byte_counter <= 0;
				ext_fifo_rst_n <= 1;
				if(!metadata_fifo_data_out[22])
				begin
					valid_eth_frame <= metadata_fifo_data_out[10:0] + 11'd42;
					bytes_to_remove <= 0;
					ext_fifo_rst_n <= 0;
					rst_counter <= 1;
					int_fifo_rd_en <= 0;
					state <= RST_STATE;
				end
				else
				begin
					corrupt_packet_counter <= corrupt_packet_counter + 1;
					rst_counter <= 0;
					bytes_to_remove <= metadata_fifo_data_out[21:11];
					int_fifo_rd_en <= 0;
					state <= INVALID_BYTE_CHECK_STATE;
				end
			end
			
			INVALID_BYTE_CHECK_STATE:
			begin
				invalid_byte_counter <= 0;
				if(bytes_to_remove == 0)
				begin
					int_fifo_rd_en <= 0;
					state <= IDLE;
				end
				else
				begin
					int_fifo_rd_en <= 1;
					state <= INVALID_BYTE_WAIT_STATE;
				end
			end
			
			INVALID_BYTE_WAIT_STATE:
			begin
				if(bytes_to_remove == 11'd1)
				begin
					int_fifo_rd_en <= 0;
					invalid_byte_counter <= 0;
					state <= IDLE;
				end
				else
				begin
					int_fifo_rd_en <= 1;
					invalid_byte_counter <= 11'd1;
					state <= INVALID_BYTE_COUNT_STATE;
				end
			end
			
			INVALID_BYTE_COUNT_STATE:
			begin
				if(invalid_byte_counter < bytes_to_remove - 11'd1)
				begin
					int_fifo_rd_en <= 1;
					invalid_byte_counter <= invalid_byte_counter + 11'd1;
					state <= INVALID_BYTE_COUNT_STATE;
				end
				else
				begin
					int_fifo_rd_en <= 0;
					invalid_byte_counter <= 0;
					state <= IDLE;
				end
			end
			
			RST_STATE:
			begin	
				if(rst_counter < 16)
				begin
					rst_counter <= rst_counter + 1;
					ext_fifo_rst_n <= 0;
					state <= RST_STATE;
				end
				else
				begin
					rst_counter <= 0;
					ext_fifo_rst_n <= 1;
					int_fifo_rd_en <= 1;
					state <= WAIT_STATE;
				end
			end
			
			WAIT_STATE:
			begin
				rx_fifo_wr_en <= 0;
				int_fifo_rd_en <= 1;
				state <= BYTE_ACQ_STATE;
			end
			
			BYTE_ACQ_STATE:
			begin
				rx_fifo_data_in <= int_fifo_data_out;
				rx_fifo_wr_en <= 1;
				if(byte_counter < valid_eth_frame - 2)
				begin
					byte_counter <= byte_counter + 1;
					int_fifo_rd_en <= 1;
					state <= BYTE_ACQ_STATE;
				end
				else if(byte_counter == valid_eth_frame - 2)
				begin
					byte_counter <= byte_counter + 1;
					int_fifo_rd_en <= 0;
					state <= BYTE_ACQ_STATE;
				end
				else
				begin
					int_fifo_rd_en <= 0;
					byte_counter <= 0;
					state <= ACQ_DONE_STATE;
				end
			end
			
			ACQ_DONE_STATE:
			begin
				int_fifo_rd_en <= 0;
				rx_fifo_wr_en <= 0;
				eth_rx_data_valid <= 1;
				state <= IDLE;
			end
			
			default:
			begin
				int_fifo_rd_en <= 0;
				rx_fifo_wr_en <= 0;
				eth_rx_data_valid <= 0;
				state <= IDLE;
			end
			
		endcase
	end
end

endmodule