module uart_IF(
		input 									clk,
		input 									rst_n,
		
		input 									config_done_pulse,
		
		input[31:0] 							baudrate,
		input[3:0]								data_width,
		input 									parity_en,
		input 									parity_odd_even,
		
		output reg[3:0]							data_width_reg,
		output reg								parity_en_reg,
		output reg								parity_odd_even_reg,
		output reg[12:0]						clock_delay_param,
		
		input [10:0]							rx_corrupt_byte_count,
		input 									rx_acq_done,
		
		output reg [10:0]						rx_valid_byte_count
);

reg [10:0] rx_corrupt_byte_count_buff;

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_width_reg <= 4'd8;
		parity_odd_even_reg <= 0;
		parity_en_reg <= 0;
		clock_delay_param <= 13'd480;
	end
	else
	begin
		if(config_done_pulse == 1)
		begin
			parity_en_reg <= parity_en;
			parity_odd_even_reg <= parity_odd_even;
			data_width_reg <= data_width;
			case(baudrate)
				32'd9_600: 		clock_delay_param <= 13'd5760;
				32'd19_200: 	clock_delay_param <= 13'd2880;
				32'd28_800: 	clock_delay_param <= 13'd1920;
				32'd38_400: 	clock_delay_param <= 13'd1440;
				32'd57_600: 	clock_delay_param <= 13'd960;
				32'd76_800: 	clock_delay_param <= 13'd720;
				32'd115_200: 	clock_delay_param <= 13'd480;
				32'd230_400: 	clock_delay_param <= 13'd240;
				32'd460_800: 	clock_delay_param <= 13'd120;
				32'd921_600: 	clock_delay_param <= 13'd60;
				32'd1_843_200: 	clock_delay_param <= 13'd30;
				32'd3_686_400: 	clock_delay_param <= 13'd15;
				default: 		clock_delay_param <= 13'd480;
			endcase					
		end
	end
end



always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		rx_valid_byte_count <= 0;
		rx_corrupt_byte_count_buff <= 0;
	end
	else
	begin
		if(rx_acq_done)
		begin
			rx_corrupt_byte_count_buff <= rx_corrupt_byte_count;
			if(rx_corrupt_byte_count_buff == rx_corrupt_byte_count)
			begin
				rx_valid_byte_count <= rx_valid_byte_count + 1;
			end
			else
			begin
				rx_valid_byte_count <= rx_valid_byte_count;
			end
		end
		else
		begin
			rx_valid_byte_count <= rx_valid_byte_count;
		end
	end
end



endmodule