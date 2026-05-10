module cdc_pulse_toggle_sync(

        input  wire src_clk,
        input  wire dst_clk,
        input  wire rst_n,

        input  wire src_pulse,
        output wire dst_pulse
);

reg src_toggle;

always @(posedge src_clk or negedge rst_n)
begin
    if(!rst_n)
        src_toggle <= 1'b0;
    else if(src_pulse)
        src_toggle <= ~src_toggle;
end

wire dst_toggle_sync;

cdc_bit_sync u_cdc_bit_sync (
    .dst_clk  (dst_clk),
    .rst_n    (rst_n),
    .async_in (src_toggle),
    .sync_out (dst_toggle_sync)
);

reg dst_toggle_sync_d;

always @(posedge dst_clk or negedge rst_n)
begin
    if(!rst_n)
        dst_toggle_sync_d <= 1'b0;
    else
        dst_toggle_sync_d <= dst_toggle_sync;
end

assign dst_pulse = dst_toggle_sync ^ dst_toggle_sync_d;

endmodule