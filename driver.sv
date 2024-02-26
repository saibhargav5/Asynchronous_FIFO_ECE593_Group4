class driver extends uvm_driver#(transaction);
	`uvm_component_utils(driver)

virtual fifo_inf fifo;
transaction tr;


function new (string path = "driver", uvm_component parent);
	super.new(path, parent);
	`uvm_info("DRIVER_CLASS", "Inside Constructor!",UVM_HIGH);
endfunction

  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("DRIVER_CLASS", "Build Phase!",UVM_HIGH);

    if(!uvm_config_db#(virtual fifo_inf)::get(this, "*", "fifo", fifo))
       `uvm_fatal("fifo", get_type_name());
  endfunction: build_phase

  
  virtual task run_phase(uvm_phase phase);
  super.run_phase(phase);
  `uvm_info("DRIVER_CLASS", "Run Phase!", UVM_HIGH);
 
    initialize(tr);
    forever begin
      tr = transaction::type_id::create("tr");
      seq_item_port.get_next_item(tr);
     
	if (tr.sel == 1'b1)
		write(tr);
	else
		read(tr);

      seq_item_port.item_done();
      end
  endtask : run_phase
  
//Reset the DUT
virtual task initialize(transaction tr);
    fifo.rst <= 1'b1;
    fifo.din <= '0;
    fifo.wr_en <= '0;
    fifo.rd_en <= '0;
    repeat (2) @(negedge fifo.clk1);
    repeat (2) @(negedge fifo.clk2);
    fifo.rst <= '0;
    $display("------------------------------------------"); 
endtask

//Write to the FIFO
virtual task write(transaction tr);
@(negedge fifo.clk1);
    fifo.rst <= 1'b0;
    fifo.rd_en <= 1'b0;
    fifo.wr_en <= 1'b1;
    fifo.din <= tr.din;
    `uvm_info("DRV", "DATA WRITE",UVM_HIGH);
     $display("------------------------------------------"); 
    repeat (4)@(negedge fifo.clk1);
    fifo.wr_en <= 1'b0; 
endtask

//Read from the FIFO
virtual task read(transaction tr);
 @(negedge fifo.clk2);
    fifo.rst <= 1'b0;
    fifo.rd_en <= 1'b1;
    fifo.wr_en <= 1'b0;
    `uvm_info("DRV", "DATA READ",UVM_HIGH);
     $display("------------------------------------------"); 
    repeat (3) @(negedge fifo.clk2);
    fifo.rd_en <= 1'b0; 
endtask


endclass : driver

