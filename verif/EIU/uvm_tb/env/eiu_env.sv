/*`ifndef EIU_ENV_SV
`define EIU_ENV_SV

class eiu_env extends uvm_env;
    `uvm_component_utils(eiu_env)

    eiu_config cfg;

    bkp_agent  bkp_agt;
    nrz_agent  nrz_agt;

    line_rx_agent uart_rx_agts[3];
    line_tx_agent uart_tx_agts[3];

    phy_rx_agent  eth_rx_agts[4]; 
    eth_tx_agent  eth_tx_agts[5];

    eiu_scoreboard scb; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(eiu_config)::get(this, "", "eiu_cfg", cfg))
            `uvm_fatal("NO_CFG", "Could not find eiu_cfg in config DB!")

        uvm_config_db#(virtual bkp_intf)::set(this, "bkp_agt*", "bkp_vif", cfg.bkp_vif);
        bkp_agt = bkp_agent::type_id::create("bkp_agt", this);

        uvm_config_db#(virtual nrz_intf)::set(this, "nrz_agt*", "nrz_vif", cfg.nrz_vif);
        nrz_agt = nrz_agent::type_id::create("nrz_agt", this);

        for(int i = 0; i < 3; i++) begin
            uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("uart_rx_agts[%0d]*", i), "is_active", UVM_ACTIVE);
            uvm_config_db#(virtual uart_unified_intf)::set(this, $sformatf("uart_rx_agts[%0d]*", i), "uart_unified_intf", cfg.uart_rx_vifs[i]);
            uart_rx_agts[i] = line_rx_agent::type_id::create($sformatf("uart_rx_agts[%0d]", i), this);

            uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("uart_tx_agts[%0d]*", i), "is_active", UVM_PASSIVE);
            uvm_config_db#(virtual uart_unified_intf)::set(this, $sformatf("uart_tx_agts[%0d]*", i), "uart_unified_intf", cfg.uart_tx_vifs[i]);
            uart_tx_agts[i] = line_tx_agent::type_id::create($sformatf("uart_tx_agts[%0d]", i), this);
        end

        for(int i = 0; i < 4; i++) begin
            uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("eth_rx_agts[%0d]*", i), "is_active", UVM_ACTIVE);
            uvm_config_db#(virtual mac_rx_if)::set(this, $sformatf("eth_rx_agts[%0d]*", i), "mac_rx_vif", cfg.eth_rx_vifs[i]);
            uvm_config_db#(virtual eth_rx_if)::set(this, $sformatf("eth_rx_agts[%0d]*", i), "vif", cfg.eth_rx_drv_vifs[i]);
            eth_rx_agts[i] = phy_rx_agent::type_id::create($sformatf("eth_rx_agts[%0d]", i), this);
        end

        for(int i = 0; i < 5; i++) begin
            uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("eth_tx_agts[%0d]*", i), "is_active", UVM_PASSIVE);
            // ---> FIX: Changed the string to "tx_vif" <---
            uvm_config_db#(virtual eth_tx_if)::set(this, $sformatf("eth_tx_agts[%0d]*", i), "tx_vif", cfg.eth_tx_vifs[i]);
            eth_tx_agts[i] = eth_tx_agent::type_id::create($sformatf("eth_tx_agts[%0d]", i), this);
        end

        scb = eiu_scoreboard::type_id::create("scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect Backplane Monitor (The Golden/Expected TX Data) to Scoreboard
        bkp_agt.mon.ap.connect(scb.bkp_fifo.analysis_export);
        
        // ---> FIXED: Correctly map 'mntr' to 'uart_tx_fifo[i].analysis_export' <---
        for(int i=0; i<3; i++) begin
            uart_tx_agts[i].mntr.mon_analysis_port.connect(scb.uart_tx_fifo[i].analysis_export);
            
            // Note: If you also need to connect the RX monitors to the scoreboard:
            uart_rx_agts[i].mntr.mon_analysis_port.connect(scb.uart_rx_fifo[i].analysis_export);
        end
        
        // Peripheral Scoreboards Bypassed to prevent legacy TLM mismatches
        // Provide legacy UART Config so the driver doesn't run in 0-time
        begin
            uart_config u_cfg = uart_config::type_id::create("u_cfg");
            uvm_config_db#(uart_config)::set(this, "*", "uart_cfg", u_cfg);
        end
    endfunction

endclass

`endif*/

`ifndef EIU_ENV_SV
`define EIU_ENV_SV

class eiu_env extends uvm_env;
    `uvm_component_utils(eiu_env)

    eiu_config cfg;

    bkp_agent  bkp_agt;
    nrz_agent  nrz_agt;

    line_rx_agent uart_rx_agts[3];
    line_tx_agent uart_tx_agts[3];

    phy_rx_agent  eth_rx_agts[4]; 
    eth_tx_agent  eth_tx_agts[5];

    eiu_scoreboard scb; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(eiu_config)::get(this, "", "eiu_cfg", cfg))
            `uvm_fatal("NO_CFG", "Could not find eiu_cfg in config DB!")

        // ---------------------------------------------------------
        // 1. Create and setup the UART Config FIRST
        // ---------------------------------------------------------
        begin
            uart_config u_cfg = uart_config::type_id::create("u_cfg");
            
            // Set Defaults
            u_cfg.baudrate = 115200;
            u_cfg.data_width = 8;
            u_cfg.parity_en = 0;
            u_cfg.parity_odd_even = 0;
            
            // Override with Plusargs if provided
            $value$plusargs("UART_BAUD=%d", u_cfg.baudrate);
            $value$plusargs("UART_WIDTH=%d", u_cfg.data_width);
            $value$plusargs("UART_PARITY_EN=%d", u_cfg.parity_en);
            
            // Explicitly set it for the ENV and ALL lower components
            uvm_config_db#(uart_config)::set(this, "*", "uart_cfg", u_cfg);
        end

        uvm_config_db#(virtual bkp_intf)::set(this, "bkp_agt*", "bkp_vif", cfg.bkp_vif);
        bkp_agt = bkp_agent::type_id::create("bkp_agt", this);

        uvm_config_db#(virtual nrz_intf)::set(this, "nrz_agt*", "nrz_vif", cfg.nrz_vif);
        nrz_agt = nrz_agent::type_id::create("nrz_agt", this);

        for(int i = 0; i < 3; i++) begin
            uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("uart_rx_agts[%0d]*", i), "is_active", UVM_ACTIVE);
            uvm_config_db#(virtual uart_unified_intf)::set(this, $sformatf("uart_rx_agts[%0d]*", i), "uart_unified_intf", cfg.uart_rx_vifs[i]);
            uart_rx_agts[i] = line_rx_agent::type_id::create($sformatf("uart_rx_agts[%0d]", i), this);

            uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("uart_tx_agts[%0d]*", i), "is_active", UVM_PASSIVE);
            uvm_config_db#(virtual uart_unified_intf)::set(this, $sformatf("uart_tx_agts[%0d]*", i), "uart_unified_intf", cfg.uart_tx_vifs[i]);
            uart_tx_agts[i] = line_tx_agent::type_id::create($sformatf("uart_tx_agts[%0d]", i), this);
        end

        for(int i = 0; i < 4; i++) begin
            uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("eth_rx_agts[%0d]*", i), "is_active", UVM_ACTIVE);
            uvm_config_db#(virtual mac_rx_if)::set(this, $sformatf("eth_rx_agts[%0d]*", i), "mac_rx_vif", cfg.eth_rx_vifs[i]);
            uvm_config_db#(virtual eth_rx_if)::set(this, $sformatf("eth_rx_agts[%0d]*", i), "vif", cfg.eth_rx_drv_vifs[i]);
            eth_rx_agts[i] = phy_rx_agent::type_id::create($sformatf("eth_rx_agts[%0d]", i), this);
        end

        for(int i = 0; i < 5; i++) begin
            uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("eth_tx_agts[%0d]*", i), "is_active", UVM_PASSIVE);
            uvm_config_db#(virtual eth_tx_if)::set(this, $sformatf("eth_tx_agts[%0d]*", i), "tx_vif", cfg.eth_tx_vifs[i]);
            eth_tx_agts[i] = eth_tx_agent::type_id::create($sformatf("eth_tx_agts[%0d]", i), this);
        end

        scb = eiu_scoreboard::type_id::create("scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect Backplane Monitor (The Golden/Expected TX Data) to Scoreboard
        bkp_agt.mon.ap.connect(scb.bkp_fifo.analysis_export);

        for(int i=0; i<3; i++) begin
            uart_tx_agts[i].mntr.mon_analysis_port.connect(scb.uart_tx_fifo[i].analysis_export);
            uart_rx_agts[i].mntr.mon_analysis_port.connect(scb.uart_rx_fifo[i].analysis_export);
        end

        // ---> ADD THIS NEW BLOCK <---
        // Connect the Ethernet TX Monitors to the Scoreboard
        for(int i=0; i<4; i++) begin
            eth_tx_agts[i].mon.mon_ap.connect(scb.eth_tx_fifo[i].analysis_export);
        end

        // Provide UART Config dynamically via Command Line Plusargs
        begin
            uart_config u_cfg = uart_config::type_id::create("u_cfg");
            
            // Set Defaults
            u_cfg.baudrate = 115200;
            u_cfg.data_width = 8;
            u_cfg.parity_en = 0;
            u_cfg.parity_odd_even = 0; // 0 = Even, 1 = Odd
            
            // Override with Plusargs
            $value$plusargs("UART_BAUD=%d", u_cfg.baudrate);
            $value$plusargs("UART_WIDTH=%d", u_cfg.data_width);
            $value$plusargs("UART_PARITY_EN=%d", u_cfg.parity_en);
            $value$plusargs("UART_PARITY_OE=%d", u_cfg.parity_odd_even); // ADDED THIS!
            
            // Explicitly set it for ALL lower components
            uvm_config_db#(uart_config)::set(this, "*", "uart_cfg", u_cfg);
        end
        
    endfunction

endclass

`endif