`ifndef ERROR_INJECT_INTF_SV
`define ERROR_INJECT_INTF_SV

interface error_inject_intf(input logic clk);
    logic inject_parity_err;
    logic inject_stop_err;

    // Hijack the RTL State Machine dynamically!
    // PARITY_BIT_STATE = 4'd5
    // STOP_BIT_STATE   = 4'd6
    always @(posedge clk) begin
        // If flag is high AND the state machine is in Parity State
        if (inject_parity_err && tb_top_loopback_uart_fifo.uart_1.u_uart_TX.state == 4'd5)
            // Force the parity bit to be inverted
            force tb_top_loopback_uart_fifo.uart_1.u_uart_TX.data_tx_buff = ~tb_top_loopback_uart_fifo.uart_1.u_uart_TX.parity_bit;
            
        // If flag is high AND the state machine is in Stop Bit State
        else if (inject_stop_err && tb_top_loopback_uart_fifo.uart_1.u_uart_TX.state == 4'd6)
            // Force the stop bit LOW (Framing Error)
            force tb_top_loopback_uart_fifo.uart_1.u_uart_TX.data_tx_buff = 1'b0;
            
        else
            // Release control back to the RTL
            release tb_top_loopback_uart_fifo.uart_1.u_uart_TX.data_tx_buff;
    end
endinterface

`endif