class complex_env extends uvm_env;
	`uvm_component_util(complex_env)

	//constructor
	function new(string name="complex_env" ,uvm_component parent = null);
		super.new(name, class);
	endfunction 

	//handles
	inp_agent     	ingr_agnt		;
	out_agent  	  	egrs_agnt 		;
	scoreboard 	  	scrbrd 			;
	int 	   	  	wd_timer 		;
	common_config 	common_cfg 		;
	uvm_event 		in_scb_event	;

	//build phase
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		//the things to build
		ingr_agnt 	 = inp_agent::type_id::create("ingr_agnt",this);
		egrs_agnt 	 = out_agent::type_id::create("egrs_agnt",this);
		scrbrd 	  	 = scoreboard::type_id::create("scrbrd",this);

		in_scb_event = uvm_event_pool::get_global().get("in_scb_event");

		if(!uvm_config_db#(common_config)::get(this, "*", "common_cfg", common_cfg )) begin
			`uvm_fatal("CFG","common_cfg not  found in config db")
		end
		uvm_config_db#(uvm_object_wrapper)::set(this, "ingr_agnt.sqncr", "default_sequence", inp_sequence::type_id::get() );

		
	endfunction 

	//connect phase
	virtual function void connect_phase(uvm_phase phase);
		phase.raise_objection(this);
		super.connect_phase(phase);
		ingr_agnt.mntr.mon_analysis_port.connect(scrbrd.ingr_imp_port);
		egrs_agnt.mntr.mon_analysis_port.connect(scrbrd.egrs_imp_port);
	endfunction

	//main phase
	virtual task main_phase(uvm_phase phase);
		`uvm_info("complex_env","Starting main phase", UVM_MEDIUM)
		super.main_phase(phase)
		wd_timer = common_cfg.watchdog.timer;
		fork
			begin
				#wd_timer
				`uvm_error("complex_env", "watchdog timeout")
			end
			begin
				in_scb_event.trigger()
				`uvm_info("complex_env","scoreboard done")
			end
		join_any
		phase.drop_objection(this);
	endtask
endclass : complex_env