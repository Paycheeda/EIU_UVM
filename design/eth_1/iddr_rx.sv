module iddr_rx#(
        parameter IODELAY_GROUP_NAME = "ETH1_IDELAY_GROUP",
        parameter integer RXD0_IDELAY_VALUE   = 22,
        parameter integer RXD1_IDELAY_VALUE   = 20,
        parameter integer RXD2_IDELAY_VALUE   = 20,
        parameter integer RXD3_IDELAY_VALUE   = 20,
        parameter integer RXCTL_IDELAY_VALUE  = 20
)(

        input clk,
        input rst_n,
        
        input [3:0] data_in,
        input       rx_ctl,
        
        output [7:0] iddr_out,
        output       rx_dv,
        output       rx_er
);

wire rx_ctl1;
wire rx_ctl2;

wire rx_ctl_delayed;
wire [3:0] data_in_delayed;

wire iddr_rst;

assign iddr_rst = ~rst_n;

assign rx_dv = rx_ctl1;
assign rx_er = rx_ctl1 ^ rx_ctl2;

genvar i;

generate
    for (i = 0; i < 4; i = i + 1)
    begin : IDDR_RXD_GEN
            
        (* IODELAY_GROUP = IODELAY_GROUP_NAME *)
        IDELAYE2 #(
            .CINVCTRL_SEL          ("FALSE"),
            .DELAY_SRC             ("IDATAIN"),
            .HIGH_PERFORMANCE_MODE ("TRUE"),
            .IDELAY_TYPE           ("FIXED"),
            .IDELAY_VALUE(
                (i == 0) ? RXD0_IDELAY_VALUE :
                (i == 1) ? RXD1_IDELAY_VALUE :
                (i == 2) ? RXD2_IDELAY_VALUE :
                           RXD3_IDELAY_VALUE
            ),
            .PIPE_SEL              ("FALSE"),
            .REFCLK_FREQUENCY      (200.0),
            .SIGNAL_PATTERN        ("DATA")
        ) IDELAYE2_RXD_inst (
            .DATAOUT     (data_in_delayed[i]),
            .DATAIN      (1'b0),
            .C           (1'b0),
            .CE          (1'b0),
            .INC         (1'b0),
            .IDATAIN     (data_in[i]),
            .LD          (1'b0),
            .REGRST      (1'b0),
            .LDPIPEEN    (1'b0),
            .CNTVALUEIN  (5'd0),
            .CNTVALUEOUT (),
            .CINVCTRL    (1'b0)
        );
        
        IDDR #(
            .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
            .INIT_Q1(1'b0),
            .INIT_Q2(1'b0),
            .SRTYPE("SYNC")
        ) IDDR_inst (
            .Q1(iddr_out[i]),
            .Q2(iddr_out[i+4]),
            .C(clk),
            .CE(1'b1),
            .D(data_in_delayed[i]),
            .R(iddr_rst),
            .S(1'b0)
        );

    end
endgenerate

(* IODELAY_GROUP = IODELAY_GROUP_NAME *)
IDELAYE2 #(
    .CINVCTRL_SEL          ("FALSE"),
    .DELAY_SRC             ("IDATAIN"),
    .HIGH_PERFORMANCE_MODE ("TRUE"),
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (RXCTL_IDELAY_VALUE),
    .PIPE_SEL              ("FALSE"),
    .REFCLK_FREQUENCY      (200.0),
    .SIGNAL_PATTERN        ("DATA")
) IDELAYE2_RX_CTL_inst (
    .DATAOUT     (rx_ctl_delayed),
    .DATAIN      (1'b0),
    .C           (1'b0),
    .CE          (1'b0),
    .INC         (1'b0),
    .IDATAIN     (rx_ctl),
    .LD          (1'b0),
    .REGRST      (1'b0),
    .LDPIPEEN    (1'b0),
    .CNTVALUEIN  (5'd0),
    .CNTVALUEOUT (),
    .CINVCTRL    (1'b0)
);

IDDR #(
    .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
    .INIT_Q1(1'b0),
    .INIT_Q2(1'b0),
    .SRTYPE("SYNC")
) IDDR_rx_ctl (
    .Q1(rx_ctl1),
    .Q2(rx_ctl2),
    .C(clk),
    .CE(1'b1),
    .D(rx_ctl_delayed),
    .R(iddr_rst),
    .S(1'b0)
);

endmodule