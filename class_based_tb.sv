class transaction;
	
	rand bit select;
	rand bit wr_en,rd_en;
	rand bit [63:0]din;
	bit [63:0]dout;
	bit full,empty,almost_full,almost_empty;	
	
  constraint sel { select dist{1:=2,0:=2};}
	constraint tag{	wr_en dist{1:=3,0:=1};}
	constraint tag1{ rd_en dist{1:=2,0:=1};}
	
endclass


class generator;
	transaction tr;
	mailbox #(transaction) mbx;
	int count = 0;
	int i = 0;
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
		$display("[GEN] : %0d iteration  data: %0d", i,tr.din);
		#10;
    end
	-> done;
endtask

function void display();
	$display("[Generator] : write enable = %0d, read enable = %0d, din = %0d", tr.wr_en, tr.rd_en, tr.din);
endfunction

endclass

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
    #6;
    fifo.wr_en <= 1'b0;
    $display("[DRV] : DATA WRITE  data : %0d", fifo.din);  
endtask

//Read from the FIFO
task read();
    @(negedge fifo.clk2);
    fifo.rst <= 1'b0;
    fifo.rd_en <= 1'b1;
    fifo.wr_en <= 1'b0;
    #8.89;
    fifo.rd_en <= 1'b0;      
  $display("[DRV] : DATA READ ");  
endtask

//Applying stimulus to DUT
task run();
	initialize();
    forever begin
      mbx.get(tr);  
	  @(posedge fifo.clk1);
	  if (tr.select == 1'b1)
        write();
	  else
        read();
    end
	
endtask
endclass
  
 interface fifo_inf;
  
  bit clk1,clk2, rd_en, wr_en;         		// Clock, read, and write signals
  bit full, empty,almost_full,almost_empty; // Flags indicating FIFO status
  logic [63:0] din;         				// Data input
  logic [63:0] dout;        				// Data output
  logic rst;                   				// Reset signal
 
endinterface
  

module testbench;

  generator g;
  driver d;
  event done;
  mailbox #(transaction) mbx;
  fifo_inf fifo();
  asynchronous_fifo dut (fifo.clk1, fifo.clk2, fifo.rst, fifo.wr_en, fifo.rd_en, fifo.din, fifo.dout, fifo.full, fifo.empty, fifo.almost_full, fifo.almost_empty);
    
  initial begin
    fifo.clk1 <= 0;
	fifo.clk2 <= 0;
  end
    
  always #1 fifo.clk1 <= ~fifo.clk1;
  always #2.22 fifo.clk2 <= ~fifo.clk2;
    
  initial begin
	mbx = new();
    g = new(mbx);
	d = new(mbx);
	d.fifo = fifo;
	done = g.done;
    g.count = 30;
  end
 
   initial begin
   fork
	g.run();
	d.run();
	join_none
	wait(done.triggered);
   end
   
   initial begin
     $dumpfile("dump.vcd"); $dumpvars;
   #500;
   $finish();
   end
endmodule
