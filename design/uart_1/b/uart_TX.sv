module uart_TX #(
					parameter integer PARAM_MAX_DATA_WIDTH = 9
	
	)(			
				input 									clk, 
				input 									rst_n, 
				input[(PARAM_MAX_DATA_WIDTH-1) : 0] 	data_in, 
				input 									parity_en, 
				input 									parity_odd_even, 
				input 									data_start_pulse,
				//input[31:0]								baudrate,
				//input 									baudrate_valid,
				input[3:0]								data_width,
				input[12:0]								clock_delay_param,
				
				output reg 								data_tx = 1,
				output reg 								data_ready_pulse = 0,
				output reg								uart_tx_busy = 0
				);
// use buffer for TX //

//localparam integer clock_frequency = 32'd44_236_800;

localparam IDLE = 3'd0;
localparam START_BIT_STATE = 3'd1;
localparam DATA_TRANSMIT_STATE = 3'd2;
localparam PARITY_BIT_STATE = 3'd3;
localparam STOP_BIT_STATE = 3'd4;
localparam DATA_READY_STATE = 3'd5;
localparam DELAY_STATE = 3'd6;

reg[2:0] state = 3'd0;
reg[2:0] next_state = 3'd0;

reg[12:0] clock_counter = 13'd0;
reg[3:0] data_counter = 4'd0;

reg[(PARAM_MAX_DATA_WIDTH-1) : 0] data_in_buff;

reg parity_bit;
reg parity_en_buff;
reg parity_odd_even_buff;
reg[3:0] data_width_buff;

//reg[31:0] clock_delay_param = 0;

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
////////////////////////////////////////////////////////////////////////////////////////////////
/*
//////////////////////////////// BAUDRATE BUFFER ///////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clock_delay_param <= 32'd1;
    end
    else if (baudrate_valid) begin
        if ((baudrate != 0) && ((clock_frequency / baudrate) != 0))
            clock_delay_param <= clock_frequency / baudrate;
        else
            clock_delay_param <= 32'd1;
    end
end
////////////////////////////////////////////////////////////////////////////////////////////////
*/
//////////////////////////////// MASTER STATE MACHINE ///////////////////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		parity_bit <= 0;
		parity_en_buff <= 0;
		parity_odd_even_buff <= 0;
		data_width_buff <= 0;
		data_tx_buff <= 1;
		state <= 0;
		next_state <= 0;
		data_ready_pulse <= 0;
		uart_tx_busy <= 0;
		clock_counter <= 0;
		data_counter <= 0;
		data_in_buff <= 0;
	end
	else
	begin
		case(state)
			IDLE:
			begin
				data_ready_pulse <= 0;
				clock_counter <= 0;
				data_counter <= 0;
				data_tx_buff <= 1;
				if(data_start_pulse == 1)
				begin
					uart_tx_busy <= 1;
					parity_en_buff <= parity_en;
					parity_odd_even_buff <= parity_odd_even;
					data_in_buff <= data_in;
					state <= START_BIT_STATE;
					if (data_width == 0)
						data_width_buff <= 4'd8;
					else if (data_width > PARAM_MAX_DATA_WIDTH)
						data_width_buff <= PARAM_MAX_DATA_WIDTH[3:0];
					else
						data_width_buff <= data_width;
				end
				else
				begin
					uart_tx_busy <= 0;
					state <= IDLE;
				end
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
				data_ready_pulse <= 1;
				uart_tx_busy <= 0;
				state <= IDLE;
			end
			
			DELAY_STATE:
			begin
				if(clock_counter < (clock_delay_param - 2))
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
				data_ready_pulse <= 0;
				uart_tx_busy <= 0;
			end
		endcase
	end
end
//////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule