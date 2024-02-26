class sequencer extends uvm_sequencer#(transaction);
	`uvm_component_utils(sequencer)

	function new (string path = "sequencer", uvm_component parent);
		super.new(path, parent);
		`uvm_info("SEQUENCER", "Inside Constructor!", UVM_HIGH)		
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("SEQUENCER", "Build Phase", UVM_HIGH)
	endfunction: build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("SEQUENCER", "Connect Phase!", UVM_HIGH)
	endfunction: connect_phase

	
endclass: sequencer
