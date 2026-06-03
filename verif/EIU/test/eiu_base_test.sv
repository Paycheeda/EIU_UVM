/*`ifndef EIU_BASE_TEST_SV
`define EIU_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import eiu_pkg::*;

class eiu_base_test extends uvm_test;
    `uvm_component_utils(eiu_base_test)

    eiu_env    env;
    eiu_config cfg;
    eiu_vsqr   vsqr; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        virtual fault_inject_if fi_vif;
        super.build_phase(phase);
        
        cfg = eiu_config::type_id::create("cfg");

        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", cfg.bkp_vif))
            `uvm_fatal("NO_VIF", "Could not get bkp_vif!")
        if(!uvm_config_db#(virtual nrz_intf)::get(this, "", "nrz_vif", cfg.nrz_vif))
            `uvm_fatal("NO_VIF", "Could not get nrz_vif!")

        for(int i = 0; i < 3; i++) begin
            if(!uvm_config_db#(virtual uart_unified_intf)::get(this, "", $sformatf("uart_rx_vif_%0d", i), cfg.uart_rx_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get uart_rx_vif_%0d!", i))
            if(!uvm_config_db#(virtual uart_unified_intf)::get(this, "", $sformatf("uart_tx_vif_%0d", i), cfg.uart_tx_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get uart_tx_vif_%0d!", i))
        end

        for(int i = 0; i < 4; i++) begin
            if(!uvm_config_db#(virtual mac_rx_if)::get(this, "", $sformatf("eth_rx_vif_%0d", i), cfg.eth_rx_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get eth_rx_vif_%0d!", i))
            if(!uvm_config_db#(virtual eth_rx_if)::get(this, "", $sformatf("eth_rx_drv_vif_%0d", i), cfg.eth_rx_drv_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get eth_rx_drv_vif_%0d!", i))
        end

        for(int i = 0; i < 5; i++) begin
            if(!uvm_config_db#(virtual eth_tx_if)::get(this, "", $sformatf("eth_tx_vif_%0d", i), cfg.eth_tx_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get eth_tx_vif_%0d!", i))
            
            if(uvm_config_db#(virtual fault_inject_if)::get(this, "", $sformatf("fi_vif_%0d", i), fi_vif))
                uvm_config_db#(virtual fault_inject_if)::set(this, $sformatf("env.eth_tx_agts[%0d]*", i), "fi_vif", fi_vif);
        end

        uvm_config_db#(eiu_config)::set(this, "env", "eiu_cfg", cfg);
        env  = eiu_env::type_id::create("env", this);
        vsqr = eiu_vsqr::type_id::create("vsqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vsqr.bkp_sqr = env.bkp_agt.sqr;
        vsqr.nrz_sqr = env.nrz_agt.sqr;
        for(int i=0; i<3; i++) vsqr.uart_rx_sqr[i] = env.uart_rx_agts[i].sqncr;
        for(int i=0; i<4; i++) vsqr.eth_rx_sqr[i]  = env.eth_rx_agts[i].sqr;
    endfunction

    task run_phase(uvm_phase phase);
        eiu_vseq vseq; 
        vseq = eiu_vseq::type_id::create("vseq");

        phase.raise_objection(this, "Starting End-to-End System Test");
        #300ns; 
        `uvm_info("TEST", "=== BOOTING EIU_TOP SYSTEM TEST ===", UVM_LOW)
        vseq.start(vsqr);
        #2us;
        phase.drop_objection(this, "System Test Complete");
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD", "\n\n"                                                                            , UVM_NONE)
        `uvm_info("SCOREBOARD", "===============================================================================", UVM_NONE)
        `uvm_info("SCOREBOARD", "|                          FINAL EIU SYSTEM RESULTS                           |", UVM_NONE)
        `uvm_info("SCOREBOARD", "===============================================================================", UVM_NONE)
        `uvm_info("SCOREBOARD", "| INTERFACE | DIRECTION | PACKETS INJECTED | STATUS / EXTRACTED               |", UVM_NONE)
        `uvm_info("SCOREBOARD", "-------------------------------------------------------------------------------", UVM_NONE)
        `uvm_info("SCOREBOARD", "| ETH 1     | RX (In)   | Continuous Burst | Parsed & Extracted from Addr 10  |", UVM_NONE)
        `uvm_info("SCOREBOARD", "| ETH 1     | TX (Out)  | 0                | Awaiting Backplane Payload       |", UVM_NONE)
        `uvm_info("SCOREBOARD", "| UART 1    | RX (In)   | 50               | Parsed & Extracted from Addr 1   |", UVM_NONE)
        `uvm_info("SCOREBOARD", "| UART 1    | TX (Out)  | 5 Bytes          | Serialized out of Addr 0         |", UVM_NONE)
        `uvm_info("SCOREBOARD", "| NRZ Link  | RX (In)   | Continuous Stream| Configured at 0% Error Tolerance |", UVM_NONE)
        `uvm_info("SCOREBOARD", "===============================================================================\n", UVM_NONE)
        `uvm_info("SCOREBOARD", "*** ALL FIFOs VERIFIED. CDC BOUNDARIES VERIFIED. NO HANGS DETECTED. ***", UVM_NONE)
    endfunction

endclass

`endif*/

`ifndef EIU_BASE_TEST_SV
`define EIU_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import eiu_pkg::*;

class eiu_base_test extends uvm_test;
    `uvm_component_utils(eiu_base_test)

    eiu_env    env;
    eiu_config cfg;
    eiu_vsqr   vsqr; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        virtual fault_inject_if fi_vif;
        super.build_phase(phase);
        
        cfg = eiu_config::type_id::create("cfg");
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", cfg.bkp_vif))
            `uvm_fatal("NO_VIF", "Could not get bkp_vif!")
        if(!uvm_config_db#(virtual nrz_intf)::get(this, "", "nrz_vif", cfg.nrz_vif))
            `uvm_fatal("NO_VIF", "Could not get nrz_vif!")

        for(int i = 0; i < 3; i++) begin
            if(!uvm_config_db#(virtual uart_unified_intf)::get(this, "", $sformatf("uart_rx_vif_%0d", i), cfg.uart_rx_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get uart_rx_vif_%0d!", i))
            if(!uvm_config_db#(virtual uart_unified_intf)::get(this, "", $sformatf("uart_tx_vif_%0d", i), cfg.uart_tx_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get uart_tx_vif_%0d!", i))
        end

        for(int i = 0; i < 4; i++) begin
            if(!uvm_config_db#(virtual mac_rx_if)::get(this, "", $sformatf("eth_rx_vif_%0d", i), cfg.eth_rx_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get eth_rx_vif_%0d!", i))
            if(!uvm_config_db#(virtual eth_rx_if)::get(this, "", $sformatf("eth_rx_drv_vif_%0d", i), cfg.eth_rx_drv_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get eth_rx_drv_vif_%0d!", i))
        end

        for(int i = 0; i < 5; i++) begin
            if(!uvm_config_db#(virtual eth_tx_if)::get(this, "", $sformatf("eth_tx_vif_%0d", i), cfg.eth_tx_vifs[i]))
                `uvm_fatal("NO_VIF", $sformatf("Could not get eth_tx_vif_%0d!", i))
            
            if(uvm_config_db#(virtual fault_inject_if)::get(this, "", $sformatf("fi_vif_%0d", i), fi_vif))
                uvm_config_db#(virtual fault_inject_if)::set(this, $sformatf("env.eth_tx_agts[%0d]*", i), "fi_vif", fi_vif);
        end

        uvm_config_db#(eiu_config)::set(this, "env", "eiu_cfg", cfg);
        env  = eiu_env::type_id::create("env", this);
        vsqr = eiu_vsqr::type_id::create("vsqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vsqr.bkp_sqr = env.bkp_agt.sqr;
        vsqr.nrz_sqr = env.nrz_agt.sqr;
        for(int i=0; i<3; i++) vsqr.uart_rx_sqr[i] = env.uart_rx_agts[i].sqncr;
        for(int i=0; i<4; i++) vsqr.eth_rx_sqr[i]  = env.eth_rx_agts[i].sqr;
    endfunction

    task run_phase(uvm_phase phase);
        eiu_vseq vseq; 
        int drain_timeout_us = 2000;
        vseq = eiu_vseq::type_id::create("vseq");
        $value$plusargs("SCB_DRAIN_TIMEOUT_US=%d", drain_timeout_us);
        if (drain_timeout_us < 1) drain_timeout_us = 1;

        phase.raise_objection(this, "Starting End-to-End System Test");
        #300ns;
        `uvm_info("TEST", "=== BOOTING EIU_TOP SYSTEM TEST ===", UVM_LOW)
        vseq.start(vsqr);
        env.scb.wait_for_done(drain_timeout_us * 1us);
        phase.drop_objection(this, "System Test Complete");
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("TEST_SUMMARY", "===============================================================================", UVM_NONE)
        `uvm_info("TEST_SUMMARY", "                 EIU SYSTEM TEST EXECUTION COMPLETE                            ", UVM_NONE)
        `uvm_info("TEST_SUMMARY", " Check the [SCB_PASS] logs above for verification of the TX and RX pipelines.  ", UVM_NONE)
        `uvm_info("TEST_SUMMARY", "===============================================================================", UVM_NONE)
    endfunction

endclass

`endif