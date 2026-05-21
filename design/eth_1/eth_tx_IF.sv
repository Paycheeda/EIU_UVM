module eth_tx_IF(
			
			input clk,
			input rst_n,
			
			input udp_checksum_done_pulse,
			input eth_tx_start_pulse,
			
			output reg eth_tx_data_sent,
			output reg eth_tx_data_sent_pulse,
			
			output reg tx_en,
			
			input [15:0] eth_frame_length,
			
			output reg tx_fifo_rd_en
	);

reg udp_checksum_ready_received;
reg eth_tx_start_received;

reg[10:0] byte_counter;

reg[2:0] state;

localparam IDLE = 3'd0;
localparam FIFO_WAIT_STATE = 3'd1;
localparam BYTE_COUNT_STATE = 3'd2;
localparam WAIT_STATE = 3'd3;
localparam ACQ_DONE_STATE = 3'd4;


always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		udp_checksum_ready_received <= 0;
		eth_tx_start_received <= 0;
		eth_tx_data_sent <= 0;
		eth_tx_data_sent_pulse <= 0;
		tx_en <= 0;
		tx_fifo_rd_en <= 0;
		byte_counter <= 0;
		state <= 0;
	end
	else
	begin
		eth_tx_data_sent_pulse <= 0;
		case(state)
			IDLE:
			begin
				if(udp_checksum_done_pulse)
				begin
					udp_checksum_ready_received <= 1;
				end

				if(eth_tx_start_pulse)
				begin
					eth_tx_start_received <= 1;
				end
				
				if((udp_checksum_ready_received || udp_checksum_done_pulse) && (eth_tx_start_received || eth_tx_start_pulse))
				begin
					udp_checksum_ready_received <= 0;
					eth_tx_start_received <= 0;
					byte_counter <= 0;
					eth_tx_data_sent <= 0;
					tx_fifo_rd_en <= 1;
					state <= FIFO_WAIT_STATE;
				end
				else
				begin
					state <= IDLE;
				end
			end
			
			
			FIFO_WAIT_STATE:
			begin
				tx_fifo_rd_en <= 1;   // keep reading continuously
                tx_en         <= 1;   // frame transmission active
                byte_counter  <= 11'd0;  // first valid byte cycle begins after this
				state <= BYTE_COUNT_STATE;
			end
			
			BYTE_COUNT_STATE:
			begin
				if(byte_counter < eth_frame_length - 1)
				begin
					byte_counter <= byte_counter + 1;
					state <= BYTE_COUNT_STATE;
					if (byte_counter == eth_frame_length - 2)
					begin	
						tx_fifo_rd_en <= 1'b0;
					end
					else
					begin
						tx_fifo_rd_en <= 1'b1;
					end
				end
				else
				begin
					tx_fifo_rd_en <= 0;
					byte_counter <= 0;
					tx_en <= 0;
					state <= WAIT_STATE;
				end
			end
			
			WAIT_STATE:
			begin
				state <= ACQ_DONE_STATE;
			end
			
			ACQ_DONE_STATE:
			begin
				eth_tx_data_sent_pulse <= 1;
				eth_tx_data_sent <= 1;
				state <= IDLE;
			end
			
			default:
			begin
				udp_checksum_ready_received <= 1'b0;
				eth_tx_start_received <= 1'b0;
				tx_en <= 1'b0;
				eth_tx_data_sent_pulse <= 0;
				eth_tx_data_sent <= 0;
				tx_fifo_rd_en <= 1'b0;
				byte_counter <= 11'd0;
				state <= IDLE;
			end
			
		endcase
	end
end


endmodule