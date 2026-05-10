module oddr_tx(
	
		input 			clk,
		input 			rst_n,
		
		input [7:0] 	data_in,
		input 			tx_en,
		
		output [3:0] 	ddr_out,
		output 			tx_ctl,
		output 			tx_c
	);
	
reg [7:0] data_reg;

reg tx_en_reg;
wire tx_er;
assign tx_er = 1'b0;

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
	begin
        data_reg <= 8'd0;
		tx_en_reg <= 1'b0;
    end
	else
	begin
        data_reg <= data_in;
		tx_en_reg <= tx_en;
	end
end

genvar i;

generate
    for (i = 0; i < 4; i = i + 1)
    begin : ODDR_TXD_GEN
	
		ODDR #(
		   .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
		   .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
		   .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
		) ODDR_inst (
		   .Q(ddr_out[i]),   // 1-bit DDR output
		   .C(clk),   // 1-bit clock input
		   .CE(1'b1), // 1-bit clock enable input
		   .D1(data_reg[i]), // 1-bit data input (positive edge)
		   .D2(data_reg[i+4]), // 1-bit data input (negative edge)
		   .R(~rst_n),   // 1-bit reset
		   .S(1'b0)    // 1-bit set
		);

	end
endgenerate

ODDR #(
		   .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
		   .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
		   .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
		) ODDR_TX_CTL_inst (
		   .Q(tx_ctl),   // 1-bit DDR output
		   .C(clk),   // 1-bit clock input
		   .CE(1'b1), // 1-bit clock enable input
		   .D1(tx_en_reg), // 1-bit data input (positive edge)
		   .D2(tx_en_reg ^ tx_er), // 1-bit data input (negative edge)
		   .R(~rst_n),   // 1-bit reset
		   .S(1'b0)    // 1-bit set
		);
		
ODDR #(
		   .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
		   .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
		   .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
		) ODDR_TX_C_inst (
		   .Q(tx_c),   // 1-bit DDR output
		   .C(clk),   // 1-bit clock input
		   .CE(1'b1), // 1-bit clock enable input
		   .D1(1'b1), // 1-bit data input (positive edge)
		   .D2(1'b0), // 1-bit data input (negative edge)
		   .R(~rst_n),   // 1-bit reset
		   .S(1'b0)    // 1-bit set
		);

endmodule