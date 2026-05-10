module kernel_start_tx(

        input           clk,
        input           rst_n,
        input           clk_uart,
        input           clk_eth1,
        input           clk_eth2,
        input           clk_eth3,
        input           clk_eth4,
        
        input           data_send_uart1,
        input           data_send_uart2,
        input           data_send_uart3,
        input           data_send_eth1,
        input           data_send_eth2,
        input           data_send_eth3,
        input           data_send_eth4,

        input           tx_fifo_empty_uart1,
        input           tx_fifo_empty_uart2,
        input           tx_fifo_empty_uart3,
        
        output reg      tx_acq_start_uart1,
        output reg      tx_acq_start_uart2,
        output reg      tx_acq_start_uart3,
        
        output reg      eth_tx_start_pulse_eth1,
        output reg      eth_tx_start_pulse_eth2,
        output reg      eth_tx_start_pulse_eth3,
        output reg      eth_tx_start_pulse_eth4,
        
        output reg      tx_data_sent_uart1,
        output reg      tx_data_sent_uart2,
        output reg      tx_data_sent_uart3

);

wire uart1_req_pulse_uart;

cdc_pulse_toggle_sync u_cdc_uart1_req (
    .src_clk   (clk),
    .dst_clk   (clk_uart),
    .rst_n     (rst_n),
    .src_pulse (data_send_uart1),
    .dst_pulse (uart1_req_pulse_uart)
);

reg tx_uart1_active_uart;
reg tx_uart1_started_uart;
reg uart1_done_pulse_uart;

always @(posedge clk_uart or negedge rst_n)
begin
    if(!rst_n)
    begin
        tx_uart1_active_uart  <= 1'b0;
        tx_uart1_started_uart <= 1'b0;
        tx_acq_start_uart1    <= 1'b0;
        uart1_done_pulse_uart <= 1'b0;
    end
    else
    begin
        uart1_done_pulse_uart <= 1'b0;

        tx_acq_start_uart1 <= tx_uart1_active_uart && !tx_fifo_empty_uart1;

        if(uart1_req_pulse_uart && !tx_uart1_active_uart)
        begin
            tx_uart1_active_uart  <= 1'b1;
            tx_uart1_started_uart <= 1'b0;
        end
        else
        begin
            if(tx_uart1_active_uart && !tx_fifo_empty_uart1)
            begin
                tx_uart1_started_uart <= 1'b1;
            end

            if(tx_uart1_active_uart && tx_uart1_started_uart && tx_fifo_empty_uart1)
            begin
                tx_uart1_active_uart  <= 1'b0;
                tx_uart1_started_uart <= 1'b0;
                uart1_done_pulse_uart <= 1'b1;
            end
        end
    end
end

wire uart1_done_pulse_64;

cdc_pulse_toggle_sync u_cdc_uart1_done (
    .src_clk   (clk_uart),
    .dst_clk   (clk),
    .rst_n     (rst_n),
    .src_pulse (uart1_done_pulse_uart),
    .dst_pulse (uart1_done_pulse_64)
);

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        tx_data_sent_uart1 <= 1'b0;
    end
    else
    begin
        if(data_send_uart1)
        begin
            tx_data_sent_uart1 <= 1'b0;
        end
        else if(uart1_done_pulse_64)
        begin
            tx_data_sent_uart1 <= 1'b1;
        end
    end
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

wire uart2_req_pulse_uart;

cdc_pulse_toggle_sync u_cdc_uart2_req (
    .src_clk   (clk),
    .dst_clk   (clk_uart),
    .rst_n     (rst_n),
    .src_pulse (data_send_uart2),
    .dst_pulse (uart2_req_pulse_uart)
);

reg tx_uart2_active_uart;
reg tx_uart2_started_uart;
reg uart2_done_pulse_uart;

always @(posedge clk_uart or negedge rst_n)
begin
    if(!rst_n)
    begin
        tx_uart2_active_uart  <= 1'b0;
        tx_uart2_started_uart <= 1'b0;
        tx_acq_start_uart2    <= 1'b0;
        uart2_done_pulse_uart <= 1'b0;
    end
    else
    begin
        uart2_done_pulse_uart <= 1'b0;

        tx_acq_start_uart2 <= tx_uart2_active_uart && !tx_fifo_empty_uart2;

        if(uart2_req_pulse_uart && !tx_uart2_active_uart)
        begin
            tx_uart2_active_uart  <= 1'b1;
            tx_uart2_started_uart <= 1'b0;
        end
        else
        begin
            if(tx_uart2_active_uart && !tx_fifo_empty_uart2)
            begin
                tx_uart2_started_uart <= 1'b1;
            end

            if(tx_uart2_active_uart && tx_uart2_started_uart && tx_fifo_empty_uart2)
            begin
                tx_uart2_active_uart  <= 1'b0;
                tx_uart2_started_uart <= 1'b0;
                uart2_done_pulse_uart <= 1'b1;
            end
        end
    end
end

wire uart2_done_pulse_64;

cdc_pulse_toggle_sync u_cdc_uart2_done (
    .src_clk   (clk_uart),
    .dst_clk   (clk),
    .rst_n     (rst_n),
    .src_pulse (uart2_done_pulse_uart),
    .dst_pulse (uart2_done_pulse_64)
);

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        tx_data_sent_uart2 <= 1'b0;
    end
    else
    begin
        if(data_send_uart2)
        begin
            tx_data_sent_uart2 <= 1'b0;
        end
        else if(uart2_done_pulse_64)
        begin
            tx_data_sent_uart2 <= 1'b1;
        end
    end
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

wire uart3_req_pulse_uart;

cdc_pulse_toggle_sync u_cdc_uart3_req (
    .src_clk   (clk),
    .dst_clk   (clk_uart),
    .rst_n     (rst_n),
    .src_pulse (data_send_uart3),
    .dst_pulse (uart3_req_pulse_uart)
);

reg tx_uart3_active_uart;
reg tx_uart3_started_uart;
reg uart3_done_pulse_uart;

always @(posedge clk_uart or negedge rst_n)
begin
    if(!rst_n)
    begin
        tx_uart3_active_uart  <= 1'b0;
        tx_uart3_started_uart <= 1'b0;
        tx_acq_start_uart3    <= 1'b0;
        uart3_done_pulse_uart <= 1'b0;
    end
    else
    begin
        uart3_done_pulse_uart <= 1'b0;

        tx_acq_start_uart3 <= tx_uart3_active_uart && !tx_fifo_empty_uart3;

        if(uart3_req_pulse_uart && !tx_uart3_active_uart)
        begin
            tx_uart3_active_uart  <= 1'b1;
            tx_uart3_started_uart <= 1'b0;
        end
        else
        begin
            if(tx_uart3_active_uart && !tx_fifo_empty_uart3)
            begin
                tx_uart3_started_uart <= 1'b1;
            end

            if(tx_uart3_active_uart && tx_uart3_started_uart && tx_fifo_empty_uart3)
            begin
                tx_uart3_active_uart  <= 1'b0;
                tx_uart3_started_uart <= 1'b0;
                uart3_done_pulse_uart <= 1'b1;
            end
        end
    end
end

wire uart3_done_pulse_64;

cdc_pulse_toggle_sync u_cdc_uart3_done (
    .src_clk   (clk_uart),
    .dst_clk   (clk),
    .rst_n     (rst_n),
    .src_pulse (uart3_done_pulse_uart),
    .dst_pulse (uart3_done_pulse_64)
);

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        tx_data_sent_uart3 <= 1'b0;
    end
    else
    begin
        if(data_send_uart3)
        begin
            tx_data_sent_uart3 <= 1'b0;
        end
        else if(uart3_done_pulse_64)
        begin
            tx_data_sent_uart3 <= 1'b1;
        end
    end
end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire eth1_req_pulse_eth;

cdc_pulse_toggle_sync u_cdc_eth1_start (
    .src_clk   (clk),
    .dst_clk   (clk_eth1),
    .rst_n     (rst_n),
    .src_pulse (data_send_eth1),
    .dst_pulse (eth1_req_pulse_eth)
);

always @(posedge clk_eth1 or negedge rst_n)
begin
    if(!rst_n)
        eth_tx_start_pulse_eth1 <= 1'b0;
    else
        eth_tx_start_pulse_eth1 <= eth1_req_pulse_eth;
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire eth2_req_pulse_eth;

cdc_pulse_toggle_sync u_cdc_eth2_start (
    .src_clk   (clk),
    .dst_clk   (clk_eth2),
    .rst_n     (rst_n),
    .src_pulse (data_send_eth2),
    .dst_pulse (eth2_req_pulse_eth)
);

always @(posedge clk_eth2 or negedge rst_n)
begin
    if(!rst_n)
        eth_tx_start_pulse_eth2 <= 1'b0;
    else
        eth_tx_start_pulse_eth2 <= eth2_req_pulse_eth;
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire eth3_req_pulse_eth;

cdc_pulse_toggle_sync u_cdc_eth3_start (
    .src_clk   (clk),
    .dst_clk   (clk_eth3),
    .rst_n     (rst_n),
    .src_pulse (data_send_eth3),
    .dst_pulse (eth3_req_pulse_eth)
);

always @(posedge clk_eth3 or negedge rst_n)
begin
    if(!rst_n)
        eth_tx_start_pulse_eth3 <= 1'b0;
    else
        eth_tx_start_pulse_eth3 <= eth3_req_pulse_eth;
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire eth4_req_pulse_eth;

cdc_pulse_toggle_sync u_cdc_eth4_start (
    .src_clk   (clk),
    .dst_clk   (clk_eth4),
    .rst_n     (rst_n),
    .src_pulse (data_send_eth4),
    .dst_pulse (eth4_req_pulse_eth)
);

always @(posedge clk_eth4 or negedge rst_n)
begin
    if(!rst_n)
        eth_tx_start_pulse_eth4 <= 1'b0;
    else
        eth_tx_start_pulse_eth4 <= eth4_req_pulse_eth;
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule