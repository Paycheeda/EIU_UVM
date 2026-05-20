`ifndef EIU_VSQR_SV
`define EIU_VSQR_SV

class eiu_vsqr extends uvm_sequencer;
    `uvm_component_utils(eiu_vsqr)

    // Handles to the physical Master sequencers
    uvm_sequencer #(bkp_item) bkp_sqr;
    uvm_sequencer #(nrz_item) nrz_sqr;

    // Handles to the physical Peripheral sequencers
    // Note: Replace 'tx_uart' and 'phy_rx_seq_item' with the exact item names your UART/ETH sequencers use
    uvm_sequencer #(tx_uart)         uart_rx_sqr[3]; 
    uvm_sequencer #(phy_rx_seq_item) eth_rx_sqr[4];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass

`endif