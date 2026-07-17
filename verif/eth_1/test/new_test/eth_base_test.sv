////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_base_test.sv
//  Author        : Ahmed Ali
//  Creation Date : 16/04/2026
//
//  Copyright 2026 Avant Labs PVT LTD. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    First Floor, Jumaira Arcade,
//    Fateh Jang Road,
//    Sector F-17, Islamabad, 45230
//
//  All information contained in this document is Avant Labs PVT LTD
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  base UVM test for Ethernet verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_BASE_TEST_SV
`define ETH_BASE_TEST_SV

class eth_base_test extends uvm_test;
  `uvm_component_utils(eth_base_test)

  eth_env env;

  function new(string name = "eth_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = eth_env::type_id::create("env", this);
  endfunction

virtual task run_phase(uvm_phase phase);
    eth_tx_base_sequence tx_seq;
    phase.raise_objection(this);

    tx_seq = eth_tx_base_sequence::type_id::create("tx_seq");
    tx_seq.start(env.tx_agent.sqr);

    // Give it a MASSIVE amount of time (2 milliseconds) to guarantee all 10 finish
    #2000000; 

    phase.drop_objection(this);
  endtask
endclass

`endif