module kernel_nrz(

		input 						clk,
		input 						clk_eth,
		input 						rst_n,
		
		input 						bkp_prg_mode_on,
		input 						clk_20MHz,
		input 						data_in_nrz,
		
		output 						config_done_pulse_eth_nrz,
		input 						config_done_pulse,
		input [1:0]					tx_bpw_eth_nrz,
		input [10:0]				tx_payload_length_eth_nrz,
		input 						tx_zero_endian_eth_nrz,
		input [11:0]				tx_sync_word1_eth_nrz,
		input [11:0]				tx_sync_word2_eth_nrz,
		
		output [10:0]				tx_payload_length_actual,
		
		output wire					eth_tx_start_pulse_eth_nrz,
		output reg 					tx_fifo_wr_en_eth_nrz,
		output reg [7:0]			tx_fifo_data_in_eth_nrz


);
wire ctrl_blk_rst_n_64;
reg eth_tx_start_pulse_eth_nrz_64;

reg kernel_config_done;

(* ASYNC_REG = "TRUE" *) reg kernel_config_done_meta_20;
(* ASYNC_REG = "TRUE" *) reg kernel_config_done_sync_20;

always @(negedge clk_20MHz or negedge rst_n)
begin
    if(!rst_n)
    begin
        kernel_config_done_meta_20 <= 1'b0;
        kernel_config_done_sync_20 <= 1'b0;
    end
    else
    begin
        kernel_config_done_meta_20 <= kernel_config_done;
        kernel_config_done_sync_20 <= kernel_config_done_meta_20;
    end
end

wire [1:0] 	tx_bpw;
wire [10:0] tx_payload_internal;
wire 		tx_zero_endian;
wire [11:0] tx_sync_word1;
wire [11:0] tx_sync_word2;


assign tx_bpw = (kernel_config_done) ? tx_bpw_eth_nrz : 0;
assign tx_payload_internal = (kernel_config_done) ? tx_payload_length_eth_nrz : 0;
assign tx_zero_endian = (kernel_config_done) ? tx_zero_endian_eth_nrz : 0;
assign tx_sync_word1 = (kernel_config_done) ? tx_sync_word1_eth_nrz : 0;
assign tx_sync_word2 = (kernel_config_done) ? tx_sync_word2_eth_nrz : 0;
assign tx_payload_length_actual = (tx_bpw == 2'd0) ? tx_payload_internal : (tx_payload_internal + tx_payload_internal) ;

reg [11:0] 	word_done_buff;
reg [3:0]  	bit_counter;
reg [11:0] 	word_in_buff;
reg [11:0] 	word_in_buff2;
reg 		ctrl_blk_rst_n;
reg [10:0]	byte_counter;

reg 		sync_word1_detected;
reg 		sync_word2_detected;

reg [3:0]	state;
localparam IDLE = 4'd0;
localparam SYNC_WORD1_DETECT_STATE = 4'd1;
localparam SYNC_WORD2_DETECT_STATE = 4'd2;
localparam PAYLOAD_WRITE_HEADER1_STATE = 4'd3;
localparam PAYLOAD_WRITE_HEADER1_BYTE2_STATE = 4'd4;
localparam PAYLOAD_WRITE_HEADER2_STATE = 4'd5;
localparam PAYLOAD_WRITE_HEADER2_BYTE2_STATE = 4'd6;
localparam PAYLOAD_WRITE_DATA_STATE = 4'd7;
localparam PAYLOAD_WRITE_DATA_BYTE2_STATE = 4'd8;
localparam BYTE_COUNT_STATE = 4'd9;


reg 		word_done_toggle_20;

(* ASYNC_REG = "TRUE" *) reg word_done_toggle_meta;
(* ASYNC_REG = "TRUE" *) reg word_done_toggle_sync;
reg word_done_toggle_sync_d;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        word_done_toggle_meta   <= 1'b0;
        word_done_toggle_sync   <= 1'b0;
        word_done_toggle_sync_d <= 1'b0;
    end
    else if(!ctrl_blk_rst_n_64)
    begin
        word_done_toggle_meta   <= 1'b0;
        word_done_toggle_sync   <= 1'b0;
        word_done_toggle_sync_d <= 1'b0;
    end
    else
    begin
        word_done_toggle_meta   <= word_done_toggle_20;
        word_done_toggle_sync   <= word_done_toggle_meta;
        word_done_toggle_sync_d <= word_done_toggle_sync;
    end
end

wire word_done_pulse_64;

assign word_done_pulse_64 = word_done_toggle_sync ^ word_done_toggle_sync_d;


(* ASYNC_REG = "TRUE" *) reg bkp_prg_mode_on_meta_20;
(* ASYNC_REG = "TRUE" *) reg bkp_prg_mode_on_sync_20;

always @(negedge clk_20MHz or negedge rst_n)
begin
    if(!rst_n)
    begin
        bkp_prg_mode_on_meta_20 <= 1'b1;
        bkp_prg_mode_on_sync_20 <= 1'b1;
    end
    else
    begin
        bkp_prg_mode_on_meta_20 <= bkp_prg_mode_on;
        bkp_prg_mode_on_sync_20 <= bkp_prg_mode_on_meta_20;
    end
end


always @ (negedge clk_20MHz or negedge rst_n)
begin
	if(!rst_n)
	begin
		bit_counter <= 0;
		word_in_buff <= 0;
		word_done_buff <= 0;
		ctrl_blk_rst_n <= 0;
		word_done_toggle_20 <= 0;
	end
	else
	begin
		if(!bkp_prg_mode_on_sync_20 && kernel_config_done_sync_20)
		begin
			ctrl_blk_rst_n <= 1;
			word_in_buff <= {word_in_buff[10:0] , data_in_nrz};
			case(tx_bpw)
				2'd0:
				begin
					if(bit_counter < 7)
					begin
						bit_counter <= bit_counter + 1;
					end
					else
					begin
						word_done_buff  <= {4'd0, word_in_buff[6:0], data_in_nrz};
						bit_counter <= 0;
						word_done_toggle_20 <= ~word_done_toggle_20;
					end
				end
				
				2'd1:
				begin
					if(bit_counter < 8)
					begin
						bit_counter <= bit_counter + 1;
					end
					else
					begin
						word_done_buff  <= {3'd0, word_in_buff[7:0], data_in_nrz};
						bit_counter <= 0;
						word_done_toggle_20 <= ~word_done_toggle_20;
					end
				end
				
				2'd2:
				begin
					if(bit_counter < 9)
					begin
						bit_counter <= bit_counter + 1;
					end
					else
					begin
						word_done_buff  <= {2'd0, word_in_buff[8:0], data_in_nrz};
						bit_counter <= 0;
						word_done_toggle_20 <= ~word_done_toggle_20;
					end
				end
				
				2'd3:
				begin
					if(bit_counter < 11)
					begin
						bit_counter <= bit_counter + 1;
					end
					else
					begin
						word_done_buff  <= {word_in_buff[10:0], data_in_nrz};
						bit_counter <= 0;
						word_done_toggle_20 <= ~word_done_toggle_20;
					end
				end
				
				default:
				begin
					bit_counter <= 0;
				end
				
			endcase
		end
		else
		begin
			word_done_toggle_20 <= 0;
			ctrl_blk_rst_n <= 0;
			word_done_buff <= 0;
			word_in_buff <= 0;
			bit_counter <= 0;
		end	
	end
end


(* ASYNC_REG = "TRUE" *) reg [1:0] ctrl_blk_rst_sync_64;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        ctrl_blk_rst_sync_64 <= 2'b00;
    end
    else
    begin
        ctrl_blk_rst_sync_64 <= {ctrl_blk_rst_sync_64[0], ctrl_blk_rst_n};
    end
end


assign ctrl_blk_rst_n_64 = ctrl_blk_rst_sync_64[1];



always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		eth_tx_start_pulse_eth_nrz_64 <= 0;
		tx_fifo_wr_en_eth_nrz <= 0;
		tx_fifo_data_in_eth_nrz <= 0;
		word_in_buff2 <= 0;
		byte_counter <= 0;
		sync_word1_detected <= 0;
		sync_word2_detected <= 0;
		state <= IDLE;
	end
	else if(!ctrl_blk_rst_n_64)
	begin
		eth_tx_start_pulse_eth_nrz_64 <= 0;
		tx_fifo_wr_en_eth_nrz <= 0;
		tx_fifo_data_in_eth_nrz <= 0;
		word_in_buff2 <= 0;
		byte_counter <= 0;
		sync_word1_detected <= 0;
		sync_word2_detected <= 0;
		state <= IDLE;
	end
	else
	begin
		eth_tx_start_pulse_eth_nrz_64 <= 0;
		tx_fifo_wr_en_eth_nrz <= 0;
		case(state)
			IDLE:
			begin
				if(word_done_pulse_64)
				begin
					word_in_buff2 <= word_done_buff;
					if(!sync_word1_detected && !sync_word2_detected)
					begin
						byte_counter <= 0;
						state <= SYNC_WORD1_DETECT_STATE;
					end
					else if(sync_word1_detected && !sync_word2_detected)
					begin
						state <= SYNC_WORD2_DETECT_STATE;
					end
					else if(sync_word1_detected && sync_word2_detected)
					begin
						state <= PAYLOAD_WRITE_DATA_STATE;
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
			
			SYNC_WORD1_DETECT_STATE:
			begin
				state <= IDLE;
				
				case(tx_bpw)
					2'd0:
					begin
						if(word_in_buff2[7:0] == tx_sync_word1[7:0])
						begin
							sync_word1_detected <= 1;
						end
						else
						begin
							sync_word1_detected <= 0;
						end
					end
					
					2'd1:
					begin
						if(word_in_buff2[8:0] == tx_sync_word1[8:0])
						begin
							sync_word1_detected <= 1;
						end
						else
						begin
							sync_word1_detected <= 0;
						end
					end
					
					2'd2:
					begin
						if(word_in_buff2[9:0] == tx_sync_word1[9:0])
						begin
							sync_word1_detected <= 1;
						end
						else
						begin
							sync_word1_detected <= 0;
						end
					end
					
					2'd3:
					begin
						if(word_in_buff2[11:0] == tx_sync_word1[11:0])
						begin
							sync_word1_detected <= 1;
						end
						else
						begin
							sync_word1_detected <= 0;
						end
					end
					
					default:
					begin
						sync_word1_detected <= 0;
					end
					
				endcase
			end
			
			SYNC_WORD2_DETECT_STATE:
			begin
				case(tx_bpw)
					2'd0:
					begin
						if(word_in_buff2[7:0] == tx_sync_word2[7:0])
						begin
							state <= PAYLOAD_WRITE_HEADER1_STATE;
							sync_word2_detected <= 1;
						end
						else
						begin
							sync_word1_detected <= 0;
							sync_word2_detected <= 0;
							state <= IDLE;	
						end
					end
					
					2'd1:
					begin
						if(word_in_buff2[8:0] == tx_sync_word2[8:0])
						begin
							state <= PAYLOAD_WRITE_HEADER1_STATE;
							sync_word2_detected <= 1;
						end
						else
						begin
							sync_word1_detected <= 0;
							sync_word2_detected <= 0;
							state <= IDLE;
						end
					end
					
					2'd2:
					begin
						if(word_in_buff2[9:0] == tx_sync_word2[9:0])
						begin
							state <= PAYLOAD_WRITE_HEADER1_STATE;
							sync_word2_detected <= 1;
						end
						else
						begin
							sync_word1_detected <= 0;
							sync_word2_detected <= 0;
							state <= IDLE;
						end
					end
					
					2'd3:
					begin
						if(word_in_buff2[11:0] == tx_sync_word2[11:0])
						begin
							state <= PAYLOAD_WRITE_HEADER1_STATE;
							sync_word2_detected <= 1;
						end
						else
						begin
							sync_word1_detected <= 0;
							sync_word2_detected <= 0;
							state <= IDLE;
						end
					end
					
					default:
					begin
						sync_word2_detected <= 0;
					end
					
				endcase
			end
			
			PAYLOAD_WRITE_HEADER1_STATE:
			begin
				byte_counter <= 1;
				tx_fifo_wr_en_eth_nrz <= 1;
				case(tx_bpw)
					2'd0:
					begin
						tx_fifo_data_in_eth_nrz <= tx_sync_word1[7:0];
						state <= PAYLOAD_WRITE_HEADER2_STATE;
					end
					
					2'd1:
					begin
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? {7'd0, tx_sync_word1[8]} : tx_sync_word1[8:1];
						state <= PAYLOAD_WRITE_HEADER1_BYTE2_STATE;
					end
					
					2'd2:
					begin
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? {6'd0, tx_sync_word1[9:8]} : tx_sync_word1[9:2];
						state <= PAYLOAD_WRITE_HEADER1_BYTE2_STATE;
					end
					
					2'd3:
					begin
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? {4'd0, tx_sync_word1[11:8]} : tx_sync_word1[11:4];
						state <= PAYLOAD_WRITE_HEADER1_BYTE2_STATE;
					end
					
					default:
					begin
						tx_fifo_wr_en_eth_nrz <= 0;
						state <= PAYLOAD_WRITE_HEADER1_STATE;
					end
					
				endcase
			end
			
			PAYLOAD_WRITE_HEADER1_BYTE2_STATE:
			begin
				byte_counter <= byte_counter + 1;
				state <= PAYLOAD_WRITE_HEADER2_STATE;
				case(tx_bpw)
					
					2'd1:
					begin
						tx_fifo_wr_en_eth_nrz <= 1;
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? tx_sync_word1[7:0] : {tx_sync_word1[0] , 7'd0};
					end
					
					2'd2:
					begin
						tx_fifo_wr_en_eth_nrz <= 1;
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? tx_sync_word1[7:0] : {tx_sync_word1[1:0], 6'd0};
					end
					
					2'd3:
					begin
						tx_fifo_wr_en_eth_nrz <= 1;
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? tx_sync_word1[7:0] : {tx_sync_word1[3:0] , 4'd0};
					end
					
					default:
					begin
						tx_fifo_wr_en_eth_nrz <= 0;
					end
					
				endcase
			end
			
			PAYLOAD_WRITE_HEADER2_STATE:
			begin
				byte_counter <= byte_counter + 1;
				tx_fifo_wr_en_eth_nrz <= 1;
				case(tx_bpw)
					2'd0:
					begin
						tx_fifo_data_in_eth_nrz <= tx_sync_word2[7:0];
						state <= BYTE_COUNT_STATE;
					end
					
					2'd1:
					begin
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? {7'd0, tx_sync_word2[8]} : tx_sync_word2[8:1];
						state <= PAYLOAD_WRITE_HEADER2_BYTE2_STATE;
					end
					
					2'd2:
					begin
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? {6'd0, tx_sync_word2[9:8]} : tx_sync_word2[9:2];
						state <= PAYLOAD_WRITE_HEADER2_BYTE2_STATE;
					end
					
					2'd3:
					begin
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? {4'd0, tx_sync_word2[11:8]} : tx_sync_word2[11:4];
						state <= PAYLOAD_WRITE_HEADER2_BYTE2_STATE;
					end
					
					default:
					begin
						tx_fifo_wr_en_eth_nrz <= 0;
						state <= PAYLOAD_WRITE_HEADER2_BYTE2_STATE;
					end
					
				endcase
			end
			
			PAYLOAD_WRITE_HEADER2_BYTE2_STATE:
			begin
				byte_counter <= byte_counter + 1;
				state <= BYTE_COUNT_STATE;
				case(tx_bpw)
					
					2'd1:
					begin
						tx_fifo_wr_en_eth_nrz <= 1;
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? tx_sync_word2[7:0] : {tx_sync_word2[0] , 7'd0};
					end
					
					2'd2:
					begin
						tx_fifo_wr_en_eth_nrz <= 1;
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? tx_sync_word2[7:0] : {tx_sync_word2[1:0], 6'd0};
					end
					
					2'd3:
					begin
						tx_fifo_wr_en_eth_nrz <= 1;
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? tx_sync_word2[7:0] : {tx_sync_word2[3:0] , 4'd0};
					end
					
					default:
					begin
						tx_fifo_wr_en_eth_nrz <= 0;
						state <= BYTE_COUNT_STATE;
					end
					
				endcase
			end
			
			PAYLOAD_WRITE_DATA_STATE:
			begin
				byte_counter <= byte_counter + 1;
				tx_fifo_wr_en_eth_nrz <= 1;
				case(tx_bpw)
					2'd0:
					begin
						tx_fifo_data_in_eth_nrz <= word_in_buff2[7:0];
						state <= BYTE_COUNT_STATE;
					end
					
					2'd1:
					begin
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? {7'd0, word_in_buff2[8]} : word_in_buff2[8:1];
						state <= PAYLOAD_WRITE_DATA_BYTE2_STATE;
					end
					
					2'd2:
					begin
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? {6'd0, word_in_buff2[9:8]} : word_in_buff2[9:2];
						state <= PAYLOAD_WRITE_DATA_BYTE2_STATE;
					end
					
					2'd3:
					begin
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? {4'd0, word_in_buff2[11:8]} : word_in_buff2[11:4];
						state <= PAYLOAD_WRITE_DATA_BYTE2_STATE;
					end
					
					default:
					begin
						tx_fifo_wr_en_eth_nrz <= 0;
						state <= PAYLOAD_WRITE_DATA_STATE;
					end
					
				endcase
			end
			
			PAYLOAD_WRITE_DATA_BYTE2_STATE:
			begin
				byte_counter <= byte_counter + 1;
				case(tx_bpw)
					2'd0:
					begin
						tx_fifo_wr_en_eth_nrz <= 0;
						state <= BYTE_COUNT_STATE;
					end
					
					2'd1:
					begin
						tx_fifo_wr_en_eth_nrz <= 1;
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? word_in_buff2[7:0] : {word_in_buff2[0] , 7'd0};
						state <= BYTE_COUNT_STATE;
					end
					
					2'd2:
					begin
						tx_fifo_wr_en_eth_nrz <= 1;
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? word_in_buff2[7:0] : {word_in_buff2[1:0], 6'd0};
						state <= BYTE_COUNT_STATE;
					end
					
					2'd3:
					begin
						tx_fifo_wr_en_eth_nrz <= 1;
						tx_fifo_data_in_eth_nrz <= (!tx_zero_endian) ? word_in_buff2[7:0] : {word_in_buff2[3:0] , 4'd0};
						state <= BYTE_COUNT_STATE;
					end
					
					default:
					begin
						tx_fifo_wr_en_eth_nrz <= 0;
						state <= PAYLOAD_WRITE_DATA_BYTE2_STATE;
					end
					
				endcase
			end
			
			BYTE_COUNT_STATE:
			begin
				if(byte_counter < tx_payload_length_actual)
				begin
					state <= IDLE;
				end
				else
				begin
					sync_word1_detected <= 0;
					sync_word2_detected <= 0;
					byte_counter <= 0;
					eth_tx_start_pulse_eth_nrz_64 <= 1;
					state <= IDLE;
				end
			end
			
			default:
			begin
				sync_word1_detected <= 0;
				sync_word2_detected <= 0;
				tx_fifo_wr_en_eth_nrz <= 0;
				eth_tx_start_pulse_eth_nrz_64 <= 0;
				state <= IDLE;
			end
			
		endcase
	end
end

///////////////////////// config done pulse detection ////////////////////////////////////////////
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		kernel_config_done <= 0;
	end
	else
	begin
		if(config_done_pulse)
		begin
			kernel_config_done <= 1;
		end
	end
end


cdc_pulse_toggle_sync u_eth_nrz_start_pulse_cdc (
		.src_clk	(clk),
		.dst_clk	(clk_eth),
		.rst_n		(rst_n),

		.src_pulse	(eth_tx_start_pulse_eth_nrz_64),
		.dst_pulse	(eth_tx_start_pulse_eth_nrz)
);


cdc_pulse_toggle_sync u_eth_nrz_config_done_pulse_cdc (
		.src_clk	(clk),
		.dst_clk	(clk_eth),
		.rst_n		(rst_n),

		.src_pulse	(eth_tx_start_pulse_eth_nrz_64),
		.dst_pulse	(config_done_pulse_eth_nrz)
);


endmodule