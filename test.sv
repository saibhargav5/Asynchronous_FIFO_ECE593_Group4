class test extends uvm_test;
	`uvm_component_utils(test)

	agent agt;
	rst_seq rst;
	wr_seq wr;
	rd_seq rd;
	wr_full_seq wr_full;
	rd_empty_seq rd_empty;
	random_seq random;

	function new(string path = "test", uvm_component parent);
		super.new(path, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		agt = agent::type_id::create("agt", this);

	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

	endfunction

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
			
		phase.raise_objection(this);
	
		rst = rst_seq::type_id::create("rst");
		rst.start(agt.sqr);

		
		random = random_seq::type_id::create("random");
	        random.start(agt.sqr);
		
		phase.drop_objection(this);
	endtask: run_phase

endclass: test	

