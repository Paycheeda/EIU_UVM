module cdc_count_12bit_toggle(

        input  wire        src_clk,
        input  wire        dst_clk,
        input  wire        rst_n,

        input  wire [11:0] src_count,

        output reg  [11:0] dst_count
);

reg [11:0] src_count_d;
reg [11:0] src_count_shadow;
reg        src_toggle;

(* ASYNC_REG = "TRUE" *) reg dst_toggle_meta;
(* ASYNC_REG = "TRUE" *) reg dst_toggle_sync;
reg        dst_toggle_sync_d;

wire       dst_toggle_edge;

assign dst_toggle_edge = dst_toggle_sync ^ dst_toggle_sync_d;


// =====================================================================================
// Source clock domain
// =====================================================================================

always @(posedge src_clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        src_count_d      <= 12'd0;
        src_count_shadow <= 12'd0;
        src_toggle       <= 1'b0;
    end
    else
    begin
        src_count_d <= src_count;

        if (src_count != src_count_d)
        begin
            src_count_shadow <= src_count;
            src_toggle       <= ~src_toggle;
        end
    end
end


// =====================================================================================
// Destination clock domain
// =====================================================================================

always @(posedge dst_clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        dst_toggle_meta   <= 1'b0;
        dst_toggle_sync   <= 1'b0;
        dst_toggle_sync_d <= 1'b0;
        dst_count         <= 12'd0;
    end
    else
    begin
        dst_toggle_meta   <= src_toggle;
        dst_toggle_sync   <= dst_toggle_meta;
        dst_toggle_sync_d <= dst_toggle_sync;

        if (dst_toggle_edge)
        begin
            dst_count <= src_count_shadow;
        end
    end
end

endmodule