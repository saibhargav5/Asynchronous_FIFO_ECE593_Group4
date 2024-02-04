`timescale 1ns/1ps

module asynchronous_fifo_tb;
parameter depth= 512; parameter width = 64; 
bit clk1,clk2;
bit reset,wr_en,rd_en;
logic [width-1:0]din;
logic [width-1:0]dout;
logic full,empty,almost_full,almost_empty;
logic[8:0]rdptr,wrptr;

asynchronous_fifo dut (clk1,clk2,reset,wr_en,rd_en,din,dout,full,empty,almost_full,almost_empty);

initial
begin
clk1=1'b1;
forever #1 clk1=~clk1;
end

initial
begin
clk2=1'b1;
forever #2.22 clk2=~clk2;
end

task initialize;
begin
din='0;
wr_en='0;
rd_en='0;
end
endtask

task rst;
@(negedge clk1)
@(negedge clk2)
reset=1'b1;
@(negedge clk1)
@(negedge clk2)
reset=1'b0;
endtask

task write;
begin
for(int i=0;i<512;i++) begin
@(posedge clk1);
wr_en=1'b1;
din=i;
repeat(2) @(posedge clk1);
end

@(posedge clk1);
wr_en=1'b0;
din=0;
end
endtask

task read;
begin
for(int i=0; i<512; i++)begin
@(posedge clk2);
rd_en=1'b1;
@(posedge clk2);
end

@(posedge clk2);
rd_en=1'b0;
end
endtask

initial
#7000 $finish();

  initial begin
    initialize;
    rst;
    fork
      write;
      read;
    join
    end

  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
  end

endmodule
