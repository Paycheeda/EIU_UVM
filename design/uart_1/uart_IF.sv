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
		
		input [11:0]							rx_corrupt_byte_count,
		input 									rx_acq_done,
		
		output reg [11:0]						rx_valid_byte_count,
		
		input [11:0]							count_uart//
);

reg [11:0] rx_corrupt_byte_count_buff;

reg [11:0] count_uart_d;

wire [11:0] count_uart_delta;
wire        rx_valid_byte_done;
wire [12:0] rx_count_after_add;

assign count_uart_delta = count_uart - count_uart_d;

assign rx_valid_byte_done = rx_acq_done && (rx_corrupt_byte_count_buff == rx_corrupt_byte_count);

assign rx_count_after_add = {1'b0, rx_valid_byte_count} + (rx_valid_byte_done ? 13'd1 : 13'd0);

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
		count_uart_d <= 0;
	end
	else
	begin
		count_uart_d <= count_uart;
		if(rx_acq_done)
		begin
			rx_corrupt_byte_count_buff <= rx_corrupt_byte_count;
		end
		
		if(rx_count_after_add > {1'b0, count_uart_delta})
		begin
			rx_valid_byte_count <= rx_count_after_add - {1'b0, count_uart_delta};
		end
		else
		begin
			rx_valid_byte_count <= 12'd0;
		end
	end
end

endmodule