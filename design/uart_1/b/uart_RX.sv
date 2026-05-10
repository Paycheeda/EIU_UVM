module uart_RX #(
				parameter integer PARAM_MAX_DATA_WIDTH = 9
	)(
				input 										clk, 
				input 										rst_n, 
				input 										data_rx, 
				input 										parity_en,
				input 										parity_odd_even,
				//input[31:0]									baudrate,
				input[3:0]									data_width,
				//input 										baudrate_valid,
				input[12:0]									clock_delay_param,
				
				output reg[(PARAM_MAX_DATA_WIDTH-1) : 0] 	data_out, 
				output reg 									data_ready_pulse, 
				output reg 									flag_packet_corrupt,
				output reg 									uart_rx_busy
				);

//localparam integer clock_frequency = 32'd44_236_800;

localparam IDLE = 3'd0;
localparam START_BIT_STATE = 3'd1;
localparam DATA_RECEIVE_STATE = 3'd2;
localparam PARITY_BIT_STATE = 3'd3;
localparam STOP_BIT_STATE = 3'd4;
localparam DATA_READY_STATE = 3'd5;
localparam DELAY_STATE = 3'd6;

(* ASYNC_REG = "TRUE" *) reg data_rx_buf1 = 1;
(* ASYNC_REG = "TRUE" *) reg data_rx_buf2 = 1;
reg rx_sync2_d = 1'b1;

reg[3:0] data_counter = 4'd0;
reg[12:0] clock_counter = 13'd0;

reg[2:0] state = 3'd0;
reg[2:0] next_state = 3'd0;

reg parity_bit = 0;
reg parity_calc = 0;
reg[3:0] data_width_buff;

reg parity_en_buff, parity_odd_even_buff;

wire rx_falling_edge;
assign rx_falling_edge = (rx_sync2_d == 1'b1) && (data_rx_buf2 == 1'b0);

//reg[31:0] clock_delay_param = 0;

/*
//////////////////////////////// BAUDRATE BUFFER ///////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clock_delay_param <= 32'd2;
    end
    else if (baudrate_valid) begin
        if ((baudrate != 0) && ((clock_frequency / baudrate) != 0))
            clock_delay_param <= clock_frequency / baudrate;
        else
            clock_delay_param <= 32'd2;
    end
end
/////////////////////////////////////////////////////////////////////////////////////////////////
*/
//////////////////////////////// INPUT DATA BUFFER ///////////////////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_rx_buf1 <= 1;
		data_rx_buf2 <= 1;
		rx_sync2_d <= 1;
	end
	else
	begin
		data_rx_buf1 <= data_rx;
		data_rx_buf2 <= data_rx_buf1;
		rx_sync2_d <= data_rx_buf2;
	end
end
///////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////// MASTER STATE MACHINE ///////////////////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		parity_bit <= 0;
		parity_calc <= 0;
		data_out <= 0;
		data_counter <= 0;
		clock_counter <= 0;
		parity_en_buff <= 0;
		parity_odd_even_buff <= 0;
		data_width_buff <= 0;
		state <= 0;
		next_state <= 0;
		data_ready_pulse <= 0;
		uart_rx_busy <= 0;
		flag_packet_corrupt <= 0;
	end
	else
	begin
		case(state)
			IDLE:
			begin
				data_ready_pulse <= 0;
				if(rx_falling_edge)
				begin
					parity_en_buff <= parity_en;
					parity_odd_even_buff <= parity_odd_even;
					flag_packet_corrupt <= 0;
					data_counter <= 0;
					data_out <= 0;
					uart_rx_busy <= 1;
					clock_counter <= (clock_delay_param/2) - 1;
					if (data_width == 0)
						data_width_buff <= 4'd8;
					else if (data_width > PARAM_MAX_DATA_WIDTH)
						data_width_buff <= PARAM_MAX_DATA_WIDTH[3:0];
					else
						data_width_buff <= data_width;
					state <= DELAY_STATE;
					next_state <= START_BIT_STATE;
				end
				else
				begin
					uart_rx_busy <= 0;
					state <= IDLE;
				end
			end
			
			START_BIT_STATE:
			begin
				if(data_rx_buf2 == 0)
				begin
					state <= DELAY_STATE;
					next_state <= DATA_RECEIVE_STATE;
				end
				else
				begin
					state <= IDLE;
				end
			end
			
			DATA_RECEIVE_STATE:
			begin
				data_out[data_counter] <= data_rx_buf2;
				data_counter <= data_counter + 1;
				state <= DELAY_STATE;
				next_state <= DATA_RECEIVE_STATE;
			end
			
			PARITY_BIT_STATE:
			begin
				parity_bit <= data_rx_buf2;
				clock_counter <= (clock_delay_param/2) - 1;
				state <= DELAY_STATE;
				next_state <= STOP_BIT_STATE;
			end
			
			STOP_BIT_STATE:
			begin
				// 1 = Odd parity, 0 = Even parity //
				parity_calc <= (parity_odd_even_buff) ? ~(^ (data_out & ((1<<data_width_buff)-1))) :
														^(data_out & ((1<<data_width_buff)-1));	
				if(data_rx_buf2 == 1)
				begin
					clock_counter <= (clock_delay_param/2) - 1;
					state <= DELAY_STATE;
					next_state <= DATA_READY_STATE;
				end
				else
				begin
					flag_packet_corrupt <= 1;
					state <= IDLE;
				end
			end
			
			DATA_READY_STATE:
			begin
				data_ready_pulse <= 1;
				uart_rx_busy <= 0;
				state <= IDLE;
				if(parity_en_buff && (parity_bit != parity_calc))
				begin
					data_out <= 0;
					flag_packet_corrupt <= 1;
				end
				else
				begin
					flag_packet_corrupt <= 0;
				end
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
					data_out <= data_out & ((1<<data_width_buff)-1);
					clock_counter <= 0;
					state <= next_state;
				end
			end
			
			default:
			begin
				state <= IDLE;
				data_ready_pulse <= 0;
				uart_rx_busy <= 0;
			end
			
		endcase
	end
end
////////////////////////////////////////////////////////////////////////////////////////////////////


endmodule