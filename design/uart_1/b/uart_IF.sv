module uart_IF#(
				parameter integer PARAM_MAX_DATA_WIDTH = 9
	)(
		input 									clk,
		input 									rst_n,
		
		input 									config_done_pulse,
		
		output reg 								fifo_read_data_pulse,
		input 									fifo_empty,
		
		input[PARAM_MAX_DATA_WIDTH-1:0] 		data_in_TX,
		output reg[PARAM_MAX_DATA_WIDTH-1:0] 	data_for_TX,

		input 									uart_tx_busy,
		input 									data_ready_TX_pulse,
		input 									send_data_TX_pulse_in,
		output reg 								data_start_TX_pulse_out,
		
		input[31:0] 							baudrate,
		input[3:0]								data_width,
		input 									parity_en,
		input 									parity_odd_even,
		
		output reg[3:0]							data_width_reg,
		output reg								parity_en_reg,
		output reg								parity_odd_even_reg,
		output reg[12:0]						clock_delay_param,
		
		input 									uart_rx_busy,
		input 									data_ready_RX_pulse,
		output reg 								flag_data_received
);

reg[31:0] baudrate_reg;
reg	baudrate_valid;

//localparam integer clock_frequency = 32'd44_236_800;

reg state_baudrate;
reg[2:0] state_tx;

localparam  BAUDRATE_VALID_PULSE_STATE = 1'd0;
localparam  BAUDRATE_CHANGE_DETECT_STATE = 1'd1;

localparam  TX_START_DETECT_STATE = 3'd0;
localparam 	FIFO_WAIT_STATE = 3'd1;
localparam 	TX_READ_FIFO_STATE = 3'd2;
localparam  TX_ACQ_START_STATE = 3'd3;
localparam  ACQ_COMPLETE_STATE = 3'd4;


reg[31:0] baudrate_buff;
/*
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clock_delay_param <= 32'd4;
    end
    else if (baudrate_valid) begin
        if ((baudrate_reg != 0) && ((clock_frequency / baudrate_reg) != 0))
            clock_delay_param <= clock_frequency / baudrate_reg;
        else
            clock_delay_param <= 32'd4;
    end
end
*/

///////////////////////// CLOCK DELAY PARAM CALCULATION BASED ON BAUDRATES //////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
        clock_delay_param <= 13'd384;		// default baudrate is 115_200
    end
	else if (baudrate_valid) 
	begin
        if (baudrate_reg != 0)
		begin
			case(baudrate_reg)
				32'd9_600: 		clock_delay_param <= 13'd4608;
				32'd19_200: 	clock_delay_param <= 13'd2304;
				32'd28_800: 	clock_delay_param <= 13'd1536;
				32'd38_400: 	clock_delay_param <= 13'd1152;
				32'd57_600: 	clock_delay_param <= 13'd768;
				32'd76_800: 	clock_delay_param <= 13'd576;
				32'd115_200: 	clock_delay_param <= 13'd384;
				32'd230_400: 	clock_delay_param <= 13'd192;
				32'd460_800: 	clock_delay_param <= 13'd96;
				32'd921_600: 	clock_delay_param <= 13'd48;
				32'd1_843_200: 	clock_delay_param <= 13'd24;
				32'd3_686_400: 	clock_delay_param <= 13'd12;
				32'd7_372_800: 	clock_delay_param <= 13'd6;
				32'd14_745_600:	clock_delay_param <= 13'd3;
				default: 		clock_delay_param <= 13'd384;
			endcase
		end
        else
		begin
            clock_delay_param <= 13'd384;
		end
    end
end
/////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////// State machine for BAUDRATE CHANGE DETECTION///////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		baudrate_buff <= 0;
	end
	else
	begin
		baudrate_buff <= baudrate;
	end
end

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		state_baudrate <= 0;
		baudrate_valid <= 0;
		baudrate_reg <= 0;
		data_width_reg <= 0;
		parity_odd_even_reg <= 0;
		parity_en_reg <= 0;
	end
	else
	begin
		case(state_baudrate)
			BAUDRATE_VALID_PULSE_STATE:
			begin
				if(config_done_pulse == 1)
				begin
					baudrate_valid <= 1;
					baudrate_reg <= baudrate;
					parity_en_reg <= parity_en;
					parity_odd_even_reg <= parity_odd_even;
					data_width_reg <= data_width;
					state_baudrate <= BAUDRATE_CHANGE_DETECT_STATE;					
				end
				else
				begin
					baudrate_valid <= 0;
					state_baudrate <= BAUDRATE_VALID_PULSE_STATE;					
				end

			end
			
			BAUDRATE_CHANGE_DETECT_STATE:
			begin
				baudrate_valid <= 0;
				if(baudrate != baudrate_buff)
				begin
					state_baudrate <= BAUDRATE_VALID_PULSE_STATE;
				end
				else
				begin
					state_baudrate <= BAUDRATE_CHANGE_DETECT_STATE;
				end
			end
			
			default: 
			begin
				state_baudrate <= BAUDRATE_CHANGE_DETECT_STATE;
			end
		endcase
	end
end

/////////////////////////////////// State machine for TX ////////////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_start_TX_pulse_out <= 0;
		fifo_read_data_pulse <= 0;
		data_for_TX <= 0;
		state_tx <= 0;
	end
	else
	begin
		case(state_tx)
			TX_START_DETECT_STATE:
			begin
				data_start_TX_pulse_out <= 0;
				if(send_data_TX_pulse_in && !fifo_empty)
				begin
					data_for_TX <= 0;
					fifo_read_data_pulse <= 1;
					state_tx <= TX_READ_FIFO_STATE;
					state_tx <= FIFO_WAIT_STATE;
				end
				else
				begin
					fifo_read_data_pulse <= 0;
					state_tx <= TX_START_DETECT_STATE;
				end
			end
			
			FIFO_WAIT_STATE:
			begin
				fifo_read_data_pulse <= 0;
				state_tx <= TX_READ_FIFO_STATE;
			end
			
			
			TX_READ_FIFO_STATE:
			begin	
				data_for_TX <= data_in_TX;
				state_tx <= TX_ACQ_START_STATE;
			end
			
			TX_ACQ_START_STATE:
			begin
				data_start_TX_pulse_out <= 1;
				state_tx <= ACQ_COMPLETE_STATE;
			end
			
			ACQ_COMPLETE_STATE:
			begin
				data_start_TX_pulse_out <= 0;
				if((data_ready_TX_pulse == 1) && (uart_tx_busy == 0))
				begin
					state_tx <= TX_START_DETECT_STATE;
				end
				else
				begin
					state_tx <= ACQ_COMPLETE_STATE;
				end
			end
			
			default: 
			begin
				fifo_read_data_pulse <= 0;
				data_start_TX_pulse_out <= 0;
				state_tx <= TX_START_DETECT_STATE;
			end
			
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        flag_data_received <= 0;
    else if((uart_rx_busy == 0) && (data_ready_RX_pulse == 1))
        flag_data_received <= 1;
    else
        flag_data_received <= 0;
end

endmodule