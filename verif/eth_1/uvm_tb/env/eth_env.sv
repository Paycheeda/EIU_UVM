////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_env.sv
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
//  UVM environment for Ethernet verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_ENV_SV
`define ETH_ENV_SV

class eth_env extends uvm_env;
  `uvm_component_utils(eth_env)

  // Components
  eth_tx_agent   tx_agent;
  eth_rx_agent   rx_agent;
  eth_scoreboard scoreboard; 

  function new(string name = "eth_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    tx_agent   = eth_tx_agent::type_id::create("tx_agent", this);
    rx_agent   = eth_rx_agent::type_id::create("rx_agent", this);
    scoreboard = eth_scoreboard::type_id::create("scoreboard", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    tx_agent.mon.mon_ap.connect(scoreboard.tx_export);
    
    rx_agent.mon.mon_ap.connect(scoreboard.rx_export);
  endfunction

endclass

`endif