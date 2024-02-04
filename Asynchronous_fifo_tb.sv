module asynchronous_fifo_tb;
parameter depth= 512; parameter width = 64; 
logic clk1,clk2,reset,wr_en,rd_en;
logic [width-1:0]din;
logic [width-1:0]dout;
logic full,empty,almost_full,almost_empty;
logic[8:0]rdptr,wrptr;
parameter idle=6;
parameter idle1=4.4;
asynchronous_fifo dut(clk1,clk2,reset,wr_en,rd_en,din,dout,full,empty,almost_full,almost_empty);
initial
begin
clk1=1'b1;
forever
#1 clk1=~clk1;
end

initial
begin
clk2=1'b1;
forever
#2.2 clk2=~clk2;
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
wr_en=1'b1;
begin
for(int i=0;i<124;i++) begin
#(idle);
din=$random;
end
end
//$display("wr_en=%b,rd_en=%b,full=%b,empty=%b,almost_full=%b,almost_empty=%b,din=%b,dout=%b",wr_en,wrptr,full,empty,almost_full,almost_empty,din,dout);
endtask

task read;
begin
rd_en=1'b1; 
end
//$display("wr_en=%b,rd_en=%b,full=%b,empty=%b,almost_full=%b,almost_empty=%b,din=%b,dout=%b",wr_en,wrptr,full,empty,almost_full,almost_empty,din,dout);
endtask

initial
$monitor("wr_en=%b,rd_en=%b,full=%b,empty=%b,almost_full=%b,almost_empty=%b,din=%b,dout=%b",wr_en,rd_en,full,empty,almost_full,almost_empty,din,dout);
initial
#800 $finish();
initial
begin
initialize;
rst;
fork
write;
read;
join
end


endmodule












