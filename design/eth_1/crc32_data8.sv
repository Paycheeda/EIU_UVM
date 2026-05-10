module crc32_data8 (

			input         clk,
			input         rst_n,

			input         crc_start_flag,
			input         crc_valid_flag,
			input         crc_last_flag,
			input  [7:0]  data_in,

			output [31:0] crc_out,
			output reg    crc_done_pulse,
			output reg 	  crc_done_flag
);

localparam [31:0] POLY     = 32'hEDB88320;
localparam [31:0] CRC_INIT = 32'hFFFFFFFF;

reg  [31:0] crc_reg;
wire [31:0] crc_base;
wire [31:0] crc_next;

assign crc_base      = (crc_start_flag) ? CRC_INIT : crc_reg;
assign crc_next      = nextCRC32_D8(data_in, crc_base);
assign crc_out 		 = ~crc_reg;

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        crc_reg         <= CRC_INIT;
        crc_done_pulse  <= 1'b0;
        crc_done_flag   <= 1'b0;
    end
    else 
    begin
        crc_done_pulse <= 1'b0;
        if (crc_start_flag)
        begin
            crc_done_flag <= 1'b0;
        end
        if (crc_valid_flag) 
        begin
            crc_reg <= crc_next;
            if (crc_last_flag)
            begin
                crc_done_pulse <= 1'b1;
                crc_done_flag  <= 1'b1;
            end
        end
    end
end

function [31:0] nextCRC32_D8;

input [7:0] data;
input [31:0] crc1;

reg [31:0] c0, c1, c2, c3, c4, c5, c6, c7, c8;
reg fb0, fb1, fb2, fb3, fb4, fb5, fb6, fb7;


begin
	c0 = crc1;
	
	fb0 = c0[0] ^ data[0];
	c1 = (c0 >> 1) ^ ({32{fb0}} & POLY);
	
	fb1 = c1[0] ^ data[1];
	c2 = (c1 >> 1) ^ ({32{fb1}} & POLY);
	
	fb2 = c2[0] ^ data[2];
	c3 = (c2 >> 1) ^ ({32{fb2}} & POLY);
	
	fb3 = c3[0] ^ data[3];
	c4 = (c3 >> 1) ^ ({32{fb3}} & POLY);
	
	fb4 = c4[0] ^ data[4];
	c5 = (c4 >> 1) ^ ({32{fb4}} & POLY);
	
	fb5 = c5[0] ^ data[5];
	c6 = (c5 >> 1) ^ ({32{fb5}} & POLY);
	
	fb6 = c6[0] ^ data[6];
	c7 = (c6 >> 1) ^ ({32{fb6}} & POLY);
	
	fb7 = c7[0] ^ data[7];
	c8 = (c7 >> 1) ^ ({32{fb7}} & POLY);
	
	nextCRC32_D8 = c8;

end
endfunction	


endmodule