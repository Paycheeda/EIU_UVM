`ifndef KERNEL_ENV_SV
`define KERNEL_ENV_SV

class kernel_env extends uvm_env;
    `uvm_component_utils(kernel_env)

    // Agents
    bkp_agent      bkp_agt;
    out_agent      out_agt;
    kwr_agent      kwr_agt;
    kst_agent      kst_agt;
    krd_agent      krd_agt;
    nrz_agent      nrz_agt;

    // Passive Monitors
    kst_monitor    kst_mon;
    krd_monitor    krd_mon;

    // Scoreboards
    scoreboard     scb;
    kwr_scoreboard kwr_scb;
    kst_scoreboard kst_scb;
    krd_scoreboard krd_scb;
    nrz_scoreboard nrz_scb;

    kernel_cfg     cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(kernel_cfg)::get(this, "", "kernel_cfg", cfg))
            `uvm_fatal("NO_CFG", "Could not find kernel_cfg in config DB!")

        bkp_agt = bkp_agent::type_id::create("bkp_agt", this);
        out_agt = out_agent::type_id::create("out_agt", this);
        kwr_agt = kwr_agent::type_id::create("kwr_agt", this);
        kst_agt = kst_agent::type_id::create("kst_agt", this);
        krd_agt = krd_agent::type_id::create("krd_agt", this);
        nrz_agt = nrz_agent::type_id::create("nrz_agt", this);

        kst_mon = kst_monitor::type_id::create("kst_mon", this);
        krd_mon = krd_monitor::type_id::create("krd_mon", this);

        scb     = scoreboard::type_id::create("scb", this);
        kwr_scb = kwr_scoreboard::type_id::create("kwr_scb", this);
        kst_scb = kst_scoreboard::type_id::create("kst_scb", this);
        krd_scb = krd_scoreboard::type_id::create("krd_scb", this);
        nrz_scb = nrz_scoreboard::type_id::create("nrz_scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // 1. Kernel Config Scoreboard Connections
        bkp_agt.mon.ap.connect(scb.bkp_fifo.analysis_export);
        out_agt.mon.ap.connect(scb.out_fifo.analysis_export);

        // 2. Kernel Write Routing Scoreboard Connections
        bkp_agt.mon.ap.connect(kwr_scb.bkp_fifo.analysis_export);
        kwr_agt.mon.ap.connect(kwr_scb.kwr_fifo.analysis_export);

        // 3. Kernel Start TX Handshake Connections
        bkp_agt.mon.ap.connect(kst_scb.bkp_fifo.analysis_export);
        kst_mon.ap.connect(kst_scb.kst_fifo.analysis_export);

        // 4. Kernel Read Scoreboard Connections (THE MISSING LINK!)
        krd_mon.ap.connect(krd_scb.read_fifo.analysis_export);
        krd_agt.drv.ap_inject.connect(krd_scb.inject_fifo.analysis_export);

        // Connect Driver's injection port to the Scoreboard's expected FIFO
        nrz_agt.drv.ap_inject.connect(nrz_scb.inject_fifo.analysis_export);
        
        // Connect Monitor's capture port to the Scoreboard's actual FIFO
        nrz_agt.mon.ap.connect(nrz_scb.actual_fifo.analysis_export);


    endfunction
endclass

`endif