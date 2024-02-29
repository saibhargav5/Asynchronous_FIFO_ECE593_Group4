
class agent extends uvm_agent;
	`uvm_component_utils(agent)

	driver dvr;
	monitor mtr;
	sequencer sqr;

	function new(string path = "agent", uvm_component parent);
		super.new(path,parent);
		`uvm_info("AGENT_CLASS", "Inside Constructor!", UVM_NONE);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("AGENT_CLASS", "Build Phase!", UVM_NONE);

		sqr = sequencer::type_id::create("sqr",this);
		dvr = driver::type_id::create("dvr",this);
		mtr = monitor::type_id::create("mtr",this);

	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("AGENT_CLASS", "Connect Phase!", UVM_NONE);

		dvr.seq_item_port.connect(sqr.seq_item_export);

	endfunction
	
endclass
