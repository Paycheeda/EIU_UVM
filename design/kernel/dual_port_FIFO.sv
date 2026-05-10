/*
    The read operation is also synchronous, presenting the next data word at DO whenever the
    RDEN is active one setup time before the rising RDCLK edge.
*/

/*
    The write operation is synchronous, writing the data word available at DI into the FIFO
    whenever WREN is active one setup time before the rising WRCLK edge.
*/
module dual_port_FIFO#(
                parameter integer PARAM_DATA_WIDTH = 16,
                parameter PARAM_FIFO_SIZE = "18Kb"
        )(
            input                             rst_n,
            
            input                             wr_clk,
            input[PARAM_DATA_WIDTH-1 : 0]    data_in,
            input                             wr_en,

            input                             rd_clk,
            input                            rd_en,
            output[PARAM_DATA_WIDTH-1 : 0]    data_out,
            
            
            
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
   .FIRST_WORD_FALL_THROUGH ("FALSE") // <--- THE FIX: Changed from "FALSE" to "TRUE"
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