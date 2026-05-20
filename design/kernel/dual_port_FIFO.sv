/*
    The read operation is also synchronous, presenting the next data word at DO whenever the
    RDEN is active one setup time before the rising RDCLK edge.
*/

/*
    The write operation is synchronous, writing the data word available at DI into the FIFO
    whenever WREN is active one setup time before the rising WRCLK edge.
*/
module dual_port_FIFO#(
                parameter integer PARAM_DATA_WIDTH = 9,
                parameter PARAM_FIFO_SIZE = "18Kb",
                parameter PARAM_FIRST_WORD_FALL_THROUGH  = "FALSE"
        )(
            input                           rst_n,
            
            input                           wr_clk,
            input[PARAM_DATA_WIDTH-1 : 0]   data_in,
            input                           wr_en,

            input                           rd_clk,
            input                           rd_en,
            output[PARAM_DATA_WIDTH-1 : 0]  data_out,
            
            
            
            output wire                     fifo_full,
            output wire                     fifo_empty
        );

// FIFO_DUALCLOCK_MACRO: Dual Clock First-In, First-Out (FIFO) RAM Buffer
//                       7 Series
// Xilinx HDL Language Template, version 2025.2

/////////////////////////////////////////////////////////////////
// DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width //
// ===========|===========|============|=======================//
//   37-72    |  "36Kb"   |     512    |         9-bit         //
//   19-36    |  "36Kb"   |    1024    |        10-bit         //
//   19-36    |  "18Kb"   |     512    |         9-bit         //
//   10-18    |  "36Kb"   |    2048    |        11-bit         // 
//   10-18    |  "18Kb"   |    1024    |        10-bit         //
//    5-9     |  "36Kb"   |    4096    |        12-bit         //
//    5-9     |  "18Kb"   |    2048    |        11-bit         //
//    1-4     |  "36Kb"   |    8192    |        13-bit         //
//    1-4     |  "18Kb"   |    4096    |        12-bit         //
/////////////////////////////////////////////////////////////////

FIFO_DUALCLOCK_MACRO  #(
   .ALMOST_EMPTY_OFFSET(13'h080), // Sets the almost empty threshold
   .ALMOST_FULL_OFFSET(13'h080),  // Sets almost full threshold
   .DATA_WIDTH(PARAM_DATA_WIDTH),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
   .DEVICE("7SERIES"),  // Target device: "7SERIES"
   .FIFO_SIZE (PARAM_FIFO_SIZE), // Target BRAM: "18Kb" or "36Kb"
   .FIRST_WORD_FALL_THROUGH (PARAM_FIRST_WORD_FALL_THROUGH) // Sets the FIFO FWFT to "TRUE" or "FALSE"
) FIFO_DUALCLOCK_MACRO_inst (
   .ALMOSTEMPTY(), // 1-bit output almost empty
   .ALMOSTFULL(),   // 1-bit output almost full
   .DO(data_out),                   // Output data, width defined by DATA_WIDTH parameter
   .EMPTY(fifo_empty),             // 1-bit output empty
   .FULL(fifo_full),               // 1-bit output full
   .RDCOUNT(),         // Output read count, width determined by FIFO depth
   .RDERR(),             // 1-bit output read error
   .WRCOUNT(),         // Output write count, width determined by FIFO depth
   .WRERR(),             // 1-bit output write error
   .DI(data_in),                   // Input data, width defined by DATA_WIDTH parameter
   .RDCLK(rd_clk),             // 1-bit input read clock
   .RDEN(rd_en),               // 1-bit input read enable
   .RST(~rst_n),                 // 1-bit input reset
   .WRCLK(wr_clk),             // 1-bit input write clock
   .WREN(wr_en)                // 1-bit input write enable
);

// End of FIFO_DUALCLOCK_MACRO_inst instantiation


endmodule
        
/*
reg[PARAM_DATA_WIDTH-1 : 0] fifo_data_in;
reg wr_en;
reg state_wr_data;

localparam IDLE = 1'd0;
localparam DATA_WRITE_STATE = 1'd1;

reg rd_en;
reg[PARAM_DATA_WIDTH-1 : 0] data_out_reg;
wire[PARAM_DATA_WIDTH-1 : 0] fifo_data_out;
reg[1:0] state_rd_data;


localparam READ_DATA_DETECT_STATE = 2'd0;
localparam FIFO_EMPTY_DETECT_STATE = 2'd1;
localparam READ_WAIT_STATE = 2'd2;
localparam READ_DATA_STATE = 2'd3;

assign data_out = data_out_reg;

always @ (posedge wr_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        fifo_data_in <= 0;
        wr_en <= 0;
        state_wr_data <= 0;
    end
    else
    begin
        case(state_wr_data)
            IDLE:
            begin
                wr_en <= 0;
                if(write_pulse_in == 1 && packet_corrupt_flag == 0)
                begin
                    fifo_data_in <= data_in;
                    state_wr_data <= DATA_WRITE_STATE;
                end
                else
                begin
                    state_wr_data <= IDLE;
                end
            end
            
            DATA_WRITE_STATE:
            begin
                if(fifo_full == 0)
                begin
                    wr_en <= 1;
                    state_wr_data <= IDLE;
                end
                else
                begin
                    wr_en <= 0;
                    state_wr_data <= DATA_WRITE_STATE;
                end
            end
            
            default:
            begin
                state_wr_data <= IDLE;
                wr_en <= 0;
            end 
        endcase
    end
end


always @ (posedge rd_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        rd_en <= 0;
        data_out_reg <= 0;
        read_pulse_out <= 0;
        state_rd_data <= 0;
    end
    else
    begin
        case(state_rd_data)
            READ_DATA_DETECT_STATE:
            begin
                rd_en <= 0;
                read_pulse_out <= 0;
                if(read_data_flag == 1)
                begin
                    state_rd_data <= FIFO_EMPTY_DETECT_STATE;
                end
                else
                begin
                    state_rd_data <= READ_DATA_DETECT_STATE;
                end
            end
            
            FIFO_EMPTY_DETECT_STATE:
            begin
                if(fifo_empty == 0)
                begin
                    rd_en <= 1;
                    state_rd_data <= READ_WAIT_STATE;
                end
                else
                begin
                    rd_en <= 0;
                    state_rd_data <= READ_DATA_DETECT_STATE;
                end
            end
            
            READ_WAIT_STATE:
            begin
                rd_en <= 0;
                state_rd_data <= READ_DATA_STATE;
            end
            
            READ_DATA_STATE:
            begin
                rd_en <= 0;
                data_out_reg <= fifo_data_out;
                read_pulse_out <= 1;
                state_rd_data <= READ_DATA_DETECT_STATE;
            end
            
            default:
            begin
                rd_en <= 0;
                state_rd_data <= READ_DATA_DETECT_STATE;
            end
            
        endcase
    end
end

*/