module uart_TX #(
					parameter integer PARAM_MAX_DATA_WIDTH = 9
	
	)(			
				input 									clk, 
				input 									rst_n, 
				
				output reg 								data_tx,
				
				output reg 								tx_fifo_rd_en,
				input[(PARAM_MAX_DATA_WIDTH-1) : 0] 	tx_fifo_data,
				
				input 									parity_en, 
				input 									parity_odd_even, 	
				input[3:0]								data_width,
				input[12:0]								clock_delay_param,
				
				input 									tx_acq_start,
				output reg 								tx_acq_done,
				output reg								uart_tx_busy
				);

localparam IDLE = 4'd0;
localparam FIFO_WAIT_STATE = 4'd1;
localparam FIFO_DATA_SAMPLE_STATE = 4'd2;
localparam START_BIT_STATE = 4'd3;
localparam DATA_TRANSMIT_STATE = 4'd4;
localparam PARITY_BIT_STATE = 4'd5;
localparam STOP_BIT_STATE = 4'd6;
localparam DATA_READY_STATE = 4'd7;
localparam DELAY_STATE = 4'd8;

reg[3:0] state = 4'd0;
reg[3:0] next_state = 4'd0;

reg[12:0] clock_counter = 13'd0;
reg[3:0] data_counter = 4'd0;

reg[(PARAM_MAX_DATA_WIDTH-1) : 0] data_in_buff;

reg parity_bit;
reg parity_en_buff;
reg parity_odd_even_buff;
reg[3:0] data_width_buff;
reg[12:0] clock_delay_param_buff;

reg data_tx_buff = 1;

//////////////////////////////// OUTPUT TX LINE BUFFER /////////////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_tx <= 1;
	end
	else
	begin
		data_tx <= data_tx_buff;
	end
end


always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		parity_bit <= 0;
		parity_en_buff <= 0;
		parity_odd_even_buff <= 0;
		data_width_buff <= 0;
		data_tx_buff <= 1;
		clock_delay_param_buff <= 0;
		state <= 0;
		next_state <= 0;
		tx_acq_done <= 0;
		uart_tx_busy <= 0;
		clock_counter <= 0;
		data_counter <= 0;
		tx_fifo_rd_en <= 0;
		data_in_buff <= 0;
	end
	else
	begin
		case(state)
			IDLE:
			begin
				tx_fifo_rd_en <= 0;
				clock_counter <= 0;
				data_counter <= 0;
				data_tx_buff <= 1;
				tx_acq_done <= 0;
				if(tx_acq_start == 1)
				begin
					uart_tx_busy <= 1;
					parity_en_buff <= parity_en;
					parity_odd_even_buff <= parity_odd_even;
					clock_delay_param_buff <= clock_delay_param;
					tx_fifo_rd_en <= 1;
					state <= FIFO_WAIT_STATE;
					if (data_width == 0)
						data_width_buff <= 4'd8;
					else if (data_width > PARAM_MAX_DATA_WIDTH)
						data_width_buff <= 4'd9;
					else
						data_width_buff <= data_width;
				end
				else
				begin
					uart_tx_busy <= 0;
					state <= IDLE;
				end
			end
			
			FIFO_WAIT_STATE:
			begin
				tx_fifo_rd_en <= 0;
				state <= FIFO_DATA_SAMPLE_STATE;
			end
			
			FIFO_DATA_SAMPLE_STATE:
			begin
				data_in_buff <= tx_fifo_data;
				state <= START_BIT_STATE;
			end
			
			START_BIT_STATE:
			begin
				// 1 = odd parity, 0 = even parity //
				parity_bit <= (parity_odd_even_buff) ? ~(^(data_in_buff & ((1 << data_width_buff) - 1))) : 
														^(data_in_buff & ((1 << data_width_buff) - 1));
				data_tx_buff <= 0;
				state <= DELAY_STATE;
				next_state <= DATA_TRANSMIT_STATE;
			end
			
			DATA_TRANSMIT_STATE:
			begin
				data_tx_buff <= data_in_buff[0];
				data_in_buff <= data_in_buff >> 1;
				data_counter <= data_counter + 1;
				state <= DELAY_STATE;
				next_state <= DATA_TRANSMIT_STATE;
			end
			
			PARITY_BIT_STATE:
			begin
				data_tx_buff <= parity_bit;
				state <= DELAY_STATE;
				next_state <= STOP_BIT_STATE;
			end
			
			STOP_BIT_STATE:
			begin
				data_tx_buff <= 1;
				state <= DELAY_STATE;
				next_state <= DATA_READY_STATE;
			end
			
			DATA_READY_STATE:
			begin
				tx_acq_done <= 1;
				uart_tx_busy <= 0;
				state <= IDLE;
			end
			
			DELAY_STATE:
			begin
				if(clock_counter < (clock_delay_param_buff - 2))
				begin
					clock_counter <= clock_counter + 1;
					state <= DELAY_STATE;
					if(data_counter == data_width_buff)
					begin
						data_counter <= 0;
						next_state <= (parity_en_buff) ? PARITY_BIT_STATE : STOP_BIT_STATE;
					end
				end
				else
				begin
					clock_counter <= 0;
					state <= next_state;
				end
			end
			
			default:
			begin
				state <= IDLE;
				data_tx_buff <= 1;
				tx_acq_done <= 0;
				uart_tx_busy <= 0;
			end
		endcase
	end
end

endmodule