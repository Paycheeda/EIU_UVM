module counter_8bit (

    input  wire       clk,        // 64 MHz clock
    input  wire       rst_n,      // active-low reset

    output reg [7:0]  count_value
);

    // 64 MHz = 64,000,000 clock cycles per second
    localparam ONE_SECOND_COUNT = 26'd63_999_999;

    reg [25:0] one_sec_counter;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            one_sec_counter <= 26'd0;
            count_value     <= 8'd0;
        end
        else
        begin
            if (one_sec_counter == ONE_SECOND_COUNT)
            begin
                one_sec_counter <= 26'd0;
                count_value     <= count_value + 8'd1;
            end
            else
            begin
                one_sec_counter <= one_sec_counter + 26'd1;
            end
        end
    end

endmodule