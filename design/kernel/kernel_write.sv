module kernel_write(
		
		input  wire                       clk,
		input  wire                       rst_n,

		input  wire [3:0]   			  bkp_card_id,
		input  wire [3:0]   			  fpga_card_id,
		input  wire                       bkp_data_dir,
		input  wire [5:0]                 bkp_address,
		input  wire [11:0]             	  bkp_data,
		input  wire                       word_start_strobe_pulse,
		
		output reg 						  data_send_uart1,
		output reg 						  data_send_uart2,
		output reg 						  data_send_uart3,
		output reg 						  data_send_eth1,
		output reg 						  data_send_eth2,
		output reg 						  data_send_eth3,
		output reg 						  data_send_eth4,
		
		output reg 						  fifo_wr_en_uart1,
		output reg 						  fifo_wr_en_uart2,
		output reg 						  fifo_wr_en_uart3,
		output reg 						  fifo_wr_en_eth1,
		output reg 						  fifo_wr_en_eth2,
		output reg 						  fifo_wr_en_eth3,
		output reg 						  fifo_wr_en_eth4,
		
		output reg [8:0] 				  fifo_data_in_uart1,
		output reg [8:0] 				  fifo_data_in_uart2,
		output reg [8:0] 				  fifo_data_in_uart3,
		output reg [7:0] 				  fifo_data_in_eth1,
		output reg [7:0] 				  fifo_data_in_eth2,
		output reg [7:0] 				  fifo_data_in_eth3,
		output reg [7:0] 				  fifo_data_in_eth4
		
);

wire en_detect;
assign en_detect = (bkp_data_dir) && (bkp_card_id == fpga_card_id) && (bkp_address >= 6'd41 && bkp_address <= 6'd47);

reg [5:0] captured_address;
reg [11:0] captured_data;
reg [1:0] state;

localparam IDLE = 2'd0;
localparam DATA_CAPTURE_STATE = 2'd1;
localparam DATA_WRITE_STATE = 2'd2;

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_send_uart1 <= 0;
		data_send_uart2 <= 0;
		data_send_uart3 <= 0;
		data_send_eth1 <= 0;
		data_send_eth2 <= 0;
		data_send_eth3 <= 0;
		data_send_eth4 <= 0;
		fifo_wr_en_uart1 <= 0;
		fifo_wr_en_uart2 <= 0;
		fifo_wr_en_uart3 <= 0;
		fifo_wr_en_eth1 <= 0;
		fifo_wr_en_eth2 <= 0;
		fifo_wr_en_eth3 <= 0;
		fifo_wr_en_eth4 <= 0;
		fifo_data_in_uart1 <= 0;
		fifo_data_in_uart2 <= 0;
		fifo_data_in_uart3 <= 0;
		fifo_data_in_eth1 <= 0;
		fifo_data_in_eth2 <= 0;
		fifo_data_in_eth3 <= 0;
		fifo_data_in_eth4 <= 0;
		captured_address <= 0;
		captured_data <= 0;
		state <= IDLE;
	end
	else
	begin
		case(state)
			IDLE:
			begin
				if(en_detect)
				begin
					if(word_start_strobe_pulse)
					begin
						captured_address <= bkp_address;
						captured_data <= bkp_data;
						state <= DATA_CAPTURE_STATE;
					end
					else
					begin
						state <= IDLE;
					end
				end
				else
				begin
					state <= IDLE;
				end
			end
			
			DATA_CAPTURE_STATE:
			begin
				state <= DATA_WRITE_STATE;
				case(captured_address)
					6'd41:
					begin
						data_send_uart1 <= captured_data[9];
						if(!captured_data[9])
						begin
							fifo_wr_en_uart1 <= 1;
							fifo_data_in_uart1 <= captured_data[8:0];
						end
						else
						begin
							fifo_wr_en_uart1 <= 0;
						end
						
					end
					
					6'd42:
					begin
						data_send_uart2 <= captured_data[9];
						if(!captured_data[9])
						begin
							fifo_wr_en_uart2 <= 1;
							fifo_data_in_uart2 <= captured_data[8:0];
						end
						else
						begin
							fifo_wr_en_uart2 <= 0;
						end
					end
					
					6'd43:
					begin
						data_send_uart3 <= captured_data[9];
						if(!captured_data[9])
						begin
							fifo_wr_en_uart3 <= 1;
							fifo_data_in_uart3 <= captured_data[8:0];
						end
						else
						begin
							fifo_wr_en_uart3 <= 0;
						end
					end
					
					6'd44:
					begin
						data_send_eth1 <= captured_data[8];
						if(!captured_data[8])
						begin
							fifo_wr_en_eth1 <= 1;
							fifo_data_in_eth1 <= captured_data[7:0];
						end
						else
						begin
							fifo_wr_en_eth1 <= 0;
						end
					end
					
					6'd45:
					begin
						data_send_eth2 <= captured_data[8];
						if(!captured_data[8])
						begin
							fifo_wr_en_eth2 <= 1;
							fifo_data_in_eth2 <= captured_data[7:0];
						end
						else
						begin
							fifo_wr_en_eth2 <= 0;
						end
					end
					
					6'd46:
					begin
						data_send_eth3 <= captured_data[8];
						if(!captured_data[8])
						begin
							fifo_wr_en_eth3 <= 1;
							fifo_data_in_eth3 <= captured_data[7:0];
						end
						else
						begin
							fifo_wr_en_eth3 <= 0;
						end
					end
					
					6'd47:
					begin
						data_send_eth4 <= captured_data[8];
						if(!captured_data[8])
						begin
							fifo_wr_en_eth4 <= 1;
							fifo_data_in_eth4 <= captured_data[7:0];
						end
						else
						begin
							fifo_wr_en_eth4 <= 0;
						end
					end
					
					default:
					begin
						// do nothing
					end
				endcase
			end
			
			DATA_WRITE_STATE:
			begin
				data_send_uart1 <= 0;
				data_send_uart2 <= 0;
				data_send_uart3 <= 0;
				data_send_eth1 <= 0;
				data_send_eth2 <= 0;
				data_send_eth3 <= 0;
				data_send_eth4 <= 0;
				fifo_wr_en_uart1 <= 0;
				fifo_wr_en_uart2 <= 0;
				fifo_wr_en_uart3 <= 0;
				fifo_wr_en_eth1 <= 0;
				fifo_wr_en_eth2 <= 0;
				fifo_wr_en_eth3 <= 0;
				fifo_wr_en_eth4 <= 0;
				if(word_start_strobe_pulse)
				begin
					state <= DATA_WRITE_STATE;
				end
				else
				begin
					state <= IDLE;
				end
			end
			
			default:
			begin
				fifo_wr_en_uart1 <= 0;
				fifo_wr_en_uart2 <= 0;
				fifo_wr_en_uart3 <= 0;
				fifo_wr_en_eth1 <= 0;
				fifo_wr_en_eth2 <= 0;
				fifo_wr_en_eth3 <= 0;
				fifo_wr_en_eth4 <= 0;
				state <= IDLE;
			end
			
		endcase
	end
end

endmodule