`ifndef UART_MAIN_SEQUENCE_SV
`define UART_MAIN_SEQUENCE_SV

class uart_main_sequence extends uvm_sequence #(tx_uart);
    `uvm_object_utils(uart_main_sequence)
 
    uart_tx_sequence   tx_seq;

    function new (string name = "uart_main_sequence");
        super.new(name);    
    endfunction

    virtual task body();
        `uvm_info("UART_MAIN_SEQ", "Starting tx_seq for EIU Stress Test...", UVM_MEDIUM)

        // 1. Create the worker sequence
        tx_seq = uart_tx_sequence::type_id::create("tx_seq");
        
        // 2. Bypass legacy config DB and hardcode the stress test payload
        tx_seq.num_packets = 50; 
        
        // 3. Start it!
        tx_seq.start(get_sequencer());
        
        `uvm_info("UART_MAIN_SEQ", "tx_seq finished successfully.", UVM_MEDIUM)
    endtask 
    
endclass // uart_main_sequence

`endif