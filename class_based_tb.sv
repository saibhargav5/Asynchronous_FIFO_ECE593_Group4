class transaction;
	rand bit sel;
	rand bit wr_en,rd_en;
	rand bit [63:0]din;
	logic [63:0]dout;
	logic full,empty,almost_full,almost_empty;	
	
	constraint select {  sel dist {1:=50, 0:=50};  }
	constraint tag{	 wr_en dist{1:=3,0:=1};  }
	constraint tag1{  rd_en dist{1:=2,0:=1};  }
	
endclass

//////////////////////////////////////////////////////////////////////////////// 
class generator;
	transaction tr;
	mailbox #(transaction) mbx;
	int count = 0;
	int i = 0;
	
	event sconext;
	event done;
	
function new(mailbox #(transaction) mbx);
	this.mbx = mbx;
	tr = new();
endfunction

task run();
	repeat (count) begin
		assert (tr.randomize()) else $error("Randomization failed");
		i++;
		mbx.put(tr);
		$display("[GEN] : %0d iteration ", i);
		@(sconext);
    end	
	-> done;
endtask

function void display();
$display("[Generator] : write enable = %0d, read enable = %0d, din = %0d", tr.wr_en, tr.rd_en, tr.din);
endfunction

endclass


//////////////////////////////////////////////////////////////////////////////// 
class driver;
	transaction tr;
	virtual fifo_inf fifo;
	mailbox #(transaction) mbx;    
	
function new (mailbox #(transaction) mbx);
	this.mbx = mbx;
endfunction

//Reset the DUT
task initialize();
	fifo.rst <= 1'b1;
	fifo.din <= '0;
	fifo.wr_en <= '0;
	fifo.rd_en <= '0;
	repeat (2) @(negedge fifo.clk1);
	repeat (2) @(negedge fifo.clk2);
	fifo.rst <= '0;
	$display("[DRV] : DUT Reset Done");
	$display("------------------------------------------"); 
endtask

//Write to the FIFO
task write();
@(negedge fifo.clk1);
	fifo.rst <= 1'b0;
    fifo.rd_en <= 1'b0;
    fifo.wr_en <= 1'b1;
    fifo.din <= tr.din;
	$display("[DRV] : DATA WRITE "); 
    repeat (3)@(negedge fifo.clk1);
    fifo.wr_en <= 1'b0; 
endtask

//Read from the FIFO
task read();
 @(negedge fifo.clk2);
    fifo.rst <= 1'b0;
    fifo.rd_en <= 1'b1;
    fifo.wr_en <= 1'b0;
	$display("[DRV] : DATA READ"); 
    repeat (2) @(negedge fifo.clk2);
    fifo.rd_en <= 1'b0; 
  endtask

//Applying stimulus to DUT
task run();
    forever begin
      mbx.get(tr);  
     if (tr.sel == 1'b1)
        write();
	 else
        read();
    end
  endtask
  
  endclass
  
  //////////////////////////////////////////////////////////////////////////////// 
  class monitor;
 
  virtual fifo_inf fifo;     // Virtual interface to the FIFO
  mailbox #(transaction) mbx;  // Mailbox for communication
  transaction tr;          // Transaction object for monitoring
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;   
	tr = new();	
  endfunction;
 
  task run();
    
    forever begin
	@(negedge fifo.clk1);
      tr.wr_en = fifo.wr_en;
      tr.rd_en = fifo.rd_en;
	  tr.din = fifo.din;
      tr.full = fifo.full;
      tr.empty = fifo.empty; 
	  tr.almost_full = fifo.almost_full;
	  tr.almost_empty = fifo.almost_empty;
	  tr.dout = fifo.dout;
	  	
      mbx.put(tr);
    end
    
  endtask
  
endclass

//////////////////////////////////////////////////////////////////////////////// 
class scoreboard;
  
  mailbox #(transaction) mbx;   // Mailbox for communication
  transaction tr;          		// Transaction object for monitoring
  event sconext;
  bit [63:0] din[$];            // Array to store written data
  bit [63:0] temp;         		// Temporary data storage
  int err = 0;           	    // Error count
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;     
  endfunction;
 
  task run();
    forever begin
      mbx.get(tr);
      //$display("[SCO] : Wr:%0d rd:%0d din:%0h dout:%0h full:%0d empty:%0d", tr.wr_en, tr.rd_en, tr.din, tr.dout, tr.full, tr.empty);
      
      if (tr.wr_en == 1'b1) begin
        if (tr.full == 1'b0) begin
          din.push_front(tr.din);		  
          $display("[SCO] : DATA STORED IN QUEUE");
		  #8.88;
        end
        else begin
          $display("[SCO] : FIFO is full");
        end
        $display("--------------------------------------"); 
	   -> sconext;
      end
    
      if (tr.rd_en == 1'b1) begin
        if (tr.empty == 1'b0) begin  
		  temp = din.pop_back();
			#7;
          if (tr.dout == temp)
            $display("[SCO] : DATA MATCH");
          else begin
            $error("[SCO] : DATA MISMATCH ");
            err++;
          end
        end
        else begin
          $display("[SCO] : FIFO IS EMPTY");
        end
        $display("--------------------------------------"); 
	     -> sconext;
      end
	  
		
   
    end
endtask

endclass
  
////////////////////////////////////////////////////////////////////////////////  
class env;
 
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  mailbox #(transaction) gdmbx;  // Generator + Driver mailbox
  mailbox #(transaction) msmbx;  // Monitor + Scoreboard mailbox
  virtual fifo_inf fifo;
  event nextgs;

  
function new(virtual fifo_inf fifo);
    gdmbx = new();
    gen = new(gdmbx);
    drv = new(gdmbx);
    msmbx = new();
    mon = new(msmbx);
    sco = new(msmbx);
    this.fifo = fifo;
    drv.fifo = this.fifo;
    mon.fifo = this.fifo;
	gen.sconext = nextgs;
    sco.sconext = nextgs;
  endfunction  
  
task pre_test();
    drv.initialize();
endtask
  
task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
endtask  

  task post_test(); 
    wait(gen.done.triggered);  
    $display("---------------------------------------------");
    $display("Error Count :%0d", sco.err);
    $display("---------------------------------------------");  
    $finish();
  endtask
  
  
task run();
    pre_test();
    test();
    post_test();
endtask
endclass


module testbench;

  env env_h;
  fifo_inf fifo();
  asynchronous_fifo dut (fifo.clk1, fifo.clk2, fifo.rst, fifo.wr_en, fifo.rd_en, fifo.din, fifo.dout, fifo.full, fifo.empty, fifo.almost_full, fifo.almost_empty);
    
/*covergroup cvr;

	cross wr_en_rd_en {
    bins wr_en_and_rd_en = {1, 1};
    bins wr_en_and_not_rd_en = {1, 0};
    bins not_wr_en_and_rd_en = {0, 1};
    bins not_wr_en_and_not_rd_en = {0, 0};
	}
	endgroup
	
	covergroup min_or_min_on_din;

      din_leg: coverpoint fifo.din {
         bins min = {'h0000000000000000};
         bins others= {['h0000000000000001:'hFFFFFFFFFFFFFFFE]};
         bins max  = {'hFFFFFFFFFFFFFFFF};
      }

      wr_en_leg: coverpoint fifo.wr_en {
         bins zero = {'b0};
         bins one  = {'b1};
		 }
		 
	  rd_en_leg: coverpoint fifo.rd_en {
         bins zero = {'b0};
         bins one  = {'b1};	 
		 }
		 
	  din_min_max:  cross fifo.din, fifo.wr_en, fifo.rd_en, fifo.rst {

         bins twoops = (fifo.wr_en [* 2] || fifo.rd_en [* 2]);
         bins manyops = (fifo.wr_en [* 3:10] || fifo.rd_en [* 3:10]);
	  
         bins wr_min = binsof (din_leg.min) &&  binsof (wr_en_leg.one);                  

         bins wr_max = binsof (din_leg.max) &&  binsof (wr_en_leg.one);
		 }
                       								  
	endgroup
	*/
	

covergroup cvr;
option.auto_bin_max = 10;
option.per_instance = 1;
  
  // Coverpoint for write operation
  wr:coverpoint fifo.wr_en {
    bins write_enabled = {1'b1};
    bins write_disabled = {1'b0};
  }
  // Coverpoint for read operation
  rd:coverpoint fifo.rd_en {
    bins read_enabled = {1'b1};
    bins read_disabled = {1'b0};
  }
  // Coverpoint for data input
  din:coverpoint fifo.din {
         bins min = {'h0000000000000000};
         bins others = {['h0000000000000001:'hFFFFFFFFFFFFFFFE]};
         bins max  = {'hFFFFFFFFFFFFFFFF};
  }
  // Coverpoint for data output
  dout:coverpoint fifo.dout {
		 bins min = {'h0000000000000000};
         bins others = {['h0000000000000001:'hFFFFFFFFFFFFFFFE]};
         bins max  = {'hFFFFFFFFFFFFFFFF};
  }
  // Coverpoints for FIFO states
  full:coverpoint fifo.full {
    bins full_state = {1'b1};
    bins not_full_state = {1'b0};
  }
  empty:coverpoint fifo.empty {
    bins empty_state = {1'b1};
    bins not_empty_state = {1'b0};
  }
  almost_full:coverpoint fifo.almost_full {
    bins almost_full_state = {1'b1};
    bins not_almost_full_state = {1'b0};
  }
  almost_empty:coverpoint fifo.almost_empty {
    bins almost_empty_state = {1'b1};
    bins not_almost_empty_state = {1'b0};
  }
  // Cross coverage between wr_en and rd_en
  cross wr,rd {
    bins wr_en_and_rd_en = binsof (wr.write_enabled) && binsof (rd.read_enabled);
    bins wr_en_and_not_rd_en = binsof (wr.write_enabled) && binsof (rd.read_disabled);
    bins not_wr_en_and_rd_en = binsof (wr.write_disabled) && binsof (rd.read_enabled);
    bins not_wr_en_and_not_rd_en = binsof (wr.write_disabled) && binsof (rd.read_disabled);
  }
  // Cross coverage between wr_en and full state
  cross wr,full {
    bins wr_en_and_full = binsof (wr.write_enabled) && binsof (full.full_state);
    bins wr_en_and_not_full = binsof (wr.write_enabled) && binsof (full.not_full_state);
    bins not_wr_en_and_full = binsof (wr.write_disabled) && binsof (full.full_state);
    bins not_wr_en_and_not_full = binsof (wr.write_disabled) && binsof (full.not_full_state);
  }
  // Cross coverage between rd_en and empty state
  cross rd,empty {
    bins rd_en_and_empty = binsof (rd.read_enabled) && binsof (empty.empty_state);
    bins rd_en_and_not_empty = binsof (rd.read_enabled) && binsof (empty.not_empty_state);
    bins not_rd_en_and_empty = binsof (rd.read_disabled) && binsof (empty.empty_state);
    bins not_rd_en_and_not_empty = binsof (rd.read_disabled) && binsof (empty.not_empty_state);
  }
endgroup

	cvr cv;
   // min_or_max_on_din din_min_max;

   initial begin : coverage
   
      cv = new();
    //  din_min_max = new();
   
      forever begin @(negedge fifo.clk1);
         cv.sample();
    //     din_min_max.sample();
      end
   end : coverage
   
	
  initial begin
    fifo.clk1 <= 0;
    fifo.clk2 <= 0;
  end
    
  always #1 fifo.clk1 <= ~fifo.clk1;
  always #2.22 fifo.clk2 <= ~fifo.clk2;
    
  initial begin
    env_h = new(fifo);
    env_h.gen.count = 30;
    env_h.run();
  end
   
   initial begin
   #200;
   $finish();
   end
endmodule
