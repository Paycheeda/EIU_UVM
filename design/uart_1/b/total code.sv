module uart#(
				parameter integer PARAM_MAX_DATA_WIDTH = 9
	)(
		input 									clk,
		input 									rst_n,

		input[31:0] 							baudrate,
		input 									parity_en,
		input 									parity_odd_even,
		input[3:0]								data_width,
		
		input 									rx,
		output  								tx,
		
		input[PARAM_MAX_DATA_WIDTH -1 : 0] 		data_in_TX,
		output[PARAM_MAX_DATA_WIDTH -1 : 0]		data_out_RX,
		
		input 									send_data_tx,
		output wire								uart_tx_busy,
		
		output 									RX_DATA_RECEIVED,
		output 									flag_packet_RX_corrupt
);


wire data_ready_TX_pulse;
wire data_start_TX_pulse;

wire uart_rx_busy;
wire data_ready_RX_pulse;

wire[12:0] clock_delay_param;



uart_IF u_uart_IF
		(
		.clk(clk),
		.rst_n(rst_n),
		
		.baudrate(baudrate),
		//.baudrate_reg(baudrate_reg),
		//.baudrate_valid(baudrate_valid),
		.clock_delay_param(clock_delay_param),
		
		.uart_tx_busy(uart_tx_busy),
		.data_ready_TX_pulse(data_ready_TX_pulse),
		.data_start_TX_pulse(data_start_TX_pulse),
		.send_data_tx(send_data_tx),
		
		.uart_rx_busy(uart_rx_busy),
		.data_ready_RX_pulse(data_ready_RX_pulse),
		.RX_DATA_RECEIVED(RX_DATA_RECEIVED)
);


uart_TX #(
			.PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH)
	) u_uart_TX(			
				.clk(clk), 
				.rst_n(rst_n),
				
				.parity_en(parity_en), 
				.parity_odd_even(parity_odd_even), 
				//.baudrate(baudrate_reg),
				//.baudrate_valid(baudrate_valid),
				.clock_delay_param(clock_delay_param),
				.data_width(data_width),
				
				.data_tx(tx),
				
				.data_start_pulse(data_start_TX_pulse),
				.data_in(data_in_TX),
				.data_ready_pulse(data_ready_TX_pulse),
				.uart_tx_busy(uart_tx_busy)
);

uart_RX #(
				.PARAM_MAX_DATA_WIDTH(PARAM_MAX_DATA_WIDTH)
	) u_uart_RX(
				.clk(clk), 
				.rst_n(rst_n), 
				
				.data_rx(rx), 
				
				.parity_en(parity_en),
				.parity_odd_even(parity_odd_even),
				//.baudrate(baudrate_reg),
				.data_width(data_width),
				.clock_delay_param(clock_delay_param),
				//.baudrate_valid(baudrate_valid),
				
				.data_out(data_out_RX), 
				.data_ready_pulse(data_ready_RX_pulse), 
				.flag_packet_corrupt(flag_packet_RX_corrupt),
				.uart_rx_busy(uart_rx_busy)
);

endmodule
module uart_IF(
		input 									clk,
		input 									rst_n,

		input 									uart_tx_busy,
		input 									data_ready_TX_pulse,
		input 									send_data_tx,
		output reg 								data_start_TX_pulse,
		
		input[31:0] 							baudrate,
		//output reg[31:0] 						baudrate_reg,
		//output reg 								baudrate_valid,
		output reg[12:0]						clock_delay_param,
		
		input 									uart_rx_busy,
		input 									data_ready_RX_pulse,
		output reg 								RX_DATA_RECEIVED
);

reg[31:0] baudrate_reg;
reg	baudrate_valid;

//localparam integer clock_frequency = 32'd44_236_800;

reg state_baudrate;
reg[1:0] state_tx;

localparam  BAUDRATE_VALID_PULSE_STATE = 1'd0;
localparam  BAUDRATE_CHANGE_DETECT_STATE = 1'd1;

localparam  TX_START_DETECT_STATE = 2'd0;
localparam  TX_ACQ_START_STATE = 2'd1;
localparam  ACQ_COMPLETE_STATE = 2'd2;


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
	end
	else
	begin
		case(state_baudrate)
			BAUDRATE_VALID_PULSE_STATE:
			begin
				baudrate_valid <= 1;
				baudrate_reg <= baudrate;
				state_baudrate <= BAUDRATE_CHANGE_DETECT_STATE;
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
		data_start_TX_pulse <= 0;
		state_tx <= 0;
	end
	else
	begin
		case(state_tx)
			TX_START_DETECT_STATE:
			begin
				if(send_data_tx == 1)
				begin
					state_tx <= TX_ACQ_START_STATE;
				end
				else
				begin
					state_tx <= TX_START_DETECT_STATE;
				end
			end
			TX_ACQ_START_STATE:
			begin
				data_start_TX_pulse <= 1;
				state_tx <= ACQ_COMPLETE_STATE;
			end
			
			ACQ_COMPLETE_STATE:
			begin
				data_start_TX_pulse <= 0;
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
				data_start_TX_pulse <= 0;
				state_tx <= ACQ_COMPLETE_STATE;
			end
			
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        RX_DATA_RECEIVED <= 0;
    else if((uart_rx_busy == 0) && (data_ready_RX_pulse == 1))
        RX_DATA_RECEIVED <= 1;
    else
        RX_DATA_RECEIVED <= 0;
end

endmodule
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
				if(clock_counter < (clock_delay_param - 1))
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
				if(clock_counter < (clock_delay_param - 1))
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

interface uart_unified_intf(input logic clk);
  // ==========================================
  // GLOBAL SIGNALS
  // ==========================================
  logic rst_n;

  // ==========================================
  // HOST INTERFACE (Left Side - CPU Bus)
  // ==========================================
  
  // --- 1. Configuration Register (Driven by Host TX Agent) ---
  logic [31:0] baudrate;
  logic        parity_en;
  logic        parity_odd_even;
  logic [3:0]  data_width;

  // --- 2. TX Handshake (Driven by Host TX Agent) ---
  logic [(`UART_WIDTH - 1) : 0] data_in_TX;
  logic                         send_data_tx;
  logic                         uart_tx_busy; // MUST BE EXPOSED BY RTL!

  // --- 3. RX Handshake (Read by Host RX Agent) ---
  logic [(`UART_WIDTH - 1) : 0] data_out_RX;
  logic                         RX_DATA_RECEIVED;
  logic                         flag_packet_RX_corrupt;


  // ==========================================
  // LINE INTERFACE (Right Side - Physical Wires)
  // ==========================================
  
  // --- 1. Serial Input (Driven by Line RX Agent) ---
  logic rx;

  // --- 2. Serial Output (Read by Line TX Agent) ---
  logic tx;

endinterface

