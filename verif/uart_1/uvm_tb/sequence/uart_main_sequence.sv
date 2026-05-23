`ifndef UART_MAIN_SEQUENCE_SV
`define UART_MAIN_SEQUENCE_SV

class uart_main_sequence extends uvm_sequence #(tx_uart);
    `uvm_object_utils(uart_main_sequence)

    uart_tx_sequence   tx_seq;
    int                num_packets = 10;

    function new (string name = "uart_main_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("UART_MAIN_SEQ", $sformatf("Starting tx_seq: %0d packet(s)...", num_packets), UVM_MEDIUM)

        tx_seq = uart_tx_sequence::type_id::create("tx_seq");
        tx_seq.num_packets = num_packets;
        tx_seq.start(get_sequencer());
        
        `uvm_info("UART_MAIN_SEQ", "tx_seq finished successfully.", UVM_MEDIUM)
    endtask 
    
endclass // uart_main_sequence

`endif