`ifndef EIU_CONFIG_SV
`define EIU_CONFIG_SV

class eiu_config extends uvm_object;
    `uvm_object_utils(eiu_config)

    // Master Kernel Interfaces
    virtual bkp_intf bkp_vif;
    virtual nrz_intf nrz_vif;

    // Peripherals
    virtual uart_unified_intf uart_rx_vifs[3];
    virtual uart_unified_intf uart_tx_vifs[3];
    virtual mac_rx_if         eth_rx_vifs[4];     // For the PHY Monitor
    virtual eth_rx_if         eth_rx_drv_vifs[4]; // For the PHY Driver
    virtual eth_tx_if         eth_tx_vifs[5];

    function new(string name = "eiu_config");
        super.new(name);
    endfunction
endclass

`endif