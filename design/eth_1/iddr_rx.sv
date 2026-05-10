module iddr_rx(

		input clk,
		input rst_n,
		
		input [3:0] data_in,
		input rx_ctl,
		
		output [7:0] iddr_out,
		output rx_dv,
		
		output rx_er
		);


wire rx_ctl1;
wire rx_ctl2;

assign rx_dv = rx_ctl1;
assign rx_er = rx_ctl1 ^ rx_ctl2;

genvar i;

generate
    for (i = 0; i < 4; i = i + 1)
    begin : IDDR_RXD_GEN

		IDDR #(
		   .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE"
										   //    or "SAME_EDGE_PIPELINED"
		   .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
		   .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
		   .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
		) IDDR_inst (
		   .Q1(iddr_out[i]), // 1-bit output for positive edge of clock
		   .Q2(iddr_out[i+4]), // 1-bit output for negative edge of clock
		   .C(clk),   // 1-bit clock input
		   .CE(1'b1), // 1-bit clock enable input
		   .D(data_in[i]),   // 1-bit DDR data input
		   .R(~rst_n),   // 1-bit reset
		   .S(1'b0)    // 1-bit set
		);

		// End of IDDR_inst instantiation
	end
endgenerate


IDDR #(
		   .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE"
										   //    or "SAME_EDGE_PIPELINED"
		   .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
		   .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
		   .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
		) IDDR_rx_ctl (
		   .Q1(rx_ctl1), // 1-bit output for positive edge of clock
		   .Q2(rx_ctl2), // 1-bit output for negative edge of clock
		   .C(clk),   // 1-bit clock input
		   .CE(1'b1), // 1-bit clock enable input
		   .D(rx_ctl),   // 1-bit DDR data input
		   .R(~rst_n),   // 1-bit reset
		   .S(1'b0)    // 1-bit set
		);

endmodule