module cdc_bit_sync(

        input  wire dst_clk,
        input  wire rst_n,

        input  wire async_in,

        output wire sync_out
);

(* ASYNC_REG = "TRUE" *) reg sync_meta;
(* ASYNC_REG = "TRUE" *) reg sync_reg;

always @(posedge dst_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        sync_meta <= 1'b0;
        sync_reg  <= 1'b0;
    end
    else
    begin
        sync_meta <= async_in;
        sync_reg  <= sync_meta;
    end
end

assign sync_out = sync_reg;

endmodule