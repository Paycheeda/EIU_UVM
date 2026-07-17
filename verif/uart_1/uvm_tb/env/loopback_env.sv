////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : loopback_env.sv
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
//  UVM environment for UART loopback verification
////////////////////////////////////////////////////////////////////////////////

class loopback_env extends uvm_env;
  `uvm_component_utils(loopback_env)

  // =============================
  // Constructor Method
  // =============================
  function new(string name="loopback_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  inp_agent        tx_ingr_agnt;
  out_agent        tx_egrs_agnt;

  rx_inp_agent     rx_ingr_agnt;
  rx_out_agent     rx_egrs_agnt;

  loopback_scoreboard scrbrd;
  
  uart_config      cfg;
  int              wd_timer;
  uvm_event        loopback_evnt;

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    uvm_config_db#(uvm_active_passive_enum)::set(this, "rx_ingr_agnt", "is_active", UVM_PASSIVE);

    tx_ingr_agnt = inp_agent::type_id::create("tx_ingr_agnt", this);
    tx_egrs_agnt = out_agent::type_id::create("tx_egrs_agnt", this);
    rx_ingr_agnt = rx_inp_agent::type_id::create("rx_ingr_agnt", this);
    rx_egrs_agnt = rx_out_agent::type_id::create("rx_egrs_agnt", this);

    scrbrd = loopback_scoreboard::type_id::create("scrbrd", this);
    loopback_evnt = uvm_event_pool::get_global("loopback_scb_event");

    if(!uvm_config_db #(uart_config)::get(this, "*", "uart_cfg", cfg))
      `uvm_fatal("LOOPBACK_ENV", "Failed to get uart_cfg from config database")
      
    // Start the TX stimulus!
    uvm_config_db#(uvm_object_wrapper)::set(this, "tx_ingr_agnt.sqncr.main_phase", "default_sequence", uart_main_sequence::type_id::get());
  endfunction  

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    tx_ingr_agnt.mntr.mon_analysis_port.connect(scrbrd.ingr_imp_export);
    rx_egrs_agnt.mntr.mon_analysis_port.connect(scrbrd.egrs_imp_export);
  endfunction  

  // =============================
  // Main Phase Method
  // =============================
  virtual task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("LOOPBACK_ENV", "Starting Full System Loopback.. ", UVM_MEDIUM)
    wd_timer = cfg.watchdog_timer; 

    fork
      begin
        #wd_timer;
        `uvm_error("LOOPBACK_ENV", "Watchdog Timed out! The serial link is hung.")
      end
      begin
        loopback_evnt.wait_trigger();
        #10000; 
        `uvm_info("LOOPBACK_ENV", "Loopback Verification Complete!", UVM_NONE)
      end
    join_any 
    
    phase.drop_objection(this);
  endtask 

endclass