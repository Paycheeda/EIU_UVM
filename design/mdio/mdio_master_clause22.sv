module mdio_master_clause22(

    input  wire        clk,
    input  wire        rst_n,

    input  wire        start_pulse,
    input  wire        r_w_operation, // 0 = write, 1 = read

    input  wire [4:0]  phy_add,
    input  wire [4:0]  reg_add,
    input  wire [15:0] data_tx,

    output reg  [15:0] data_rx,
    output reg         mdio_transaction_done,

    output reg         mdc,
    inout  wire        mdio
);

localparam integer CLOCK_DELAY_PARAM = 4;

localparam WRITE_OPERATION = 1'b0;
localparam READ_OPERATION  = 1'b1;

localparam IDLE                 = 3'd0;
localparam MDC_LOW_STATE        = 3'd1;
localparam MDC_LOW_DELAY_STATE  = 3'd2;
localparam MDC_HIGH_STATE       = 3'd3;
localparam MDC_HIGH_DELAY_STATE = 3'd4;
localparam ACQ_DONE_STATE       = 3'd5;

reg [2:0] state;

reg [7:0] bit_counter;
reg [7:0] clock_counter;

reg [63:0] mdio_frame;
reg r_w_operation_latched;

reg  mdio_out;
reg  mdio_oe;
wire mdio_in;

assign mdio = mdio_oe ? mdio_out : 1'bz;
assign mdio_in = mdio;

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		mdio_out <= 0;
		mdio_oe <= 0;
		mdio_transaction_done <= 0;
		data_rx <= 0;
		bit_counter <= 0;
		clock_counter <= 0;
		mdc <= 0;
		mdio_frame <= 0;
		r_w_operation_latched <= WRITE_OPERATION;
		state <= IDLE;
	end
	else
	begin
		mdio_transaction_done <= 0;
		case(state)
			IDLE:
			begin
				if(start_pulse)
				begin
					bit_counter <= 0;
					clock_counter <= 0;
					data_rx <= 0;
					mdc <= 0;
					r_w_operation_latched <= r_w_operation;
					state <= MDC_LOW_STATE;
					if(r_w_operation == WRITE_OPERATION)
					begin
						mdio_frame <= { 32'hFFFF_FFFF, 2'b01, 2'b01, phy_add, reg_add, 2'b10, data_tx };
					end
					else
					begin
						mdio_frame <= { 32'hFFFF_FFFF, 2'b01, 2'b10, phy_add, reg_add, 2'b00, 16'h0000 };
					end	
				end
				else
				begin
					mdc <= 0;
					mdio_oe <= 0;
					mdio_out <= 1;
					state <= IDLE;
				end
			end
				
			MDC_LOW_STATE:
			begin
				mdc <= 0;
				bit_counter <= bit_counter + 1;
				state <= MDC_LOW_DELAY_STATE;
				if((r_w_operation_latched == READ_OPERATION) && (bit_counter >= 46))
				begin
					mdio_oe  <= 0;
					mdio_out <= 1;
				end
				else
				begin
					mdio_oe  <= 1'b1;
					mdio_out <= mdio_frame[63 - bit_counter];
				end
			end
			
			MDC_LOW_DELAY_STATE:
			begin
				if(clock_counter < CLOCK_DELAY_PARAM - 1)
				begin
					clock_counter <= clock_counter + 1;
					state <= MDC_LOW_DELAY_STATE;
				end
				else
				begin
					clock_counter <= 0;
					state <= MDC_HIGH_STATE;
				end
			end
			
			MDC_HIGH_STATE:
			begin
				mdc <= 1'b1;
				state <= MDC_HIGH_DELAY_STATE;
				if((r_w_operation_latched == READ_OPERATION) && (bit_counter >= 49) && (bit_counter <= 64))
				begin
					data_rx <= {data_rx[14:0], mdio_in};
				end
			end
			
			MDC_HIGH_DELAY_STATE:
			begin
				if(clock_counter < CLOCK_DELAY_PARAM - 1)
				begin
					clock_counter <= clock_counter + 1;
					state <= MDC_HIGH_DELAY_STATE;
				end
				else
				begin
					clock_counter <= 0;
					if(bit_counter >= 64)
					begin
						state <= ACQ_DONE_STATE;
					end
					else
					begin
						state <= MDC_LOW_STATE;
					end
				end
			end
			
			ACQ_DONE_STATE:
			begin
				mdc  <= 0;
				mdio_oe  <= 0;
				mdio_out <= 1;
				mdio_transaction_done <= 1;
				state <= IDLE;
			end
			
			default:
			begin
				mdio_transaction_done <= 0;
				mdc <= 0;
				mdio_oe  <= 0;
				mdio_out <= 1;
				state <= IDLE;
			end
			
		endcase
	end
end


endmodule