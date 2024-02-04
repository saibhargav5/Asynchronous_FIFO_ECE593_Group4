`include "asyn.sv"
module top;
parameter DEPTH=512;
parameter WIDTH=1024;
parameter PTR_WIDTH=9;
parameter WR_CLK_TP=10,RD_CLK_TP=14;
reg wr_clk_i,rd_clk_i,rst_i,wr_en_i,rd_en_i;
reg [WIDTH-1:0] wdata_i;
//reg [PTR_WIDTH-1:0] wr_ptr_gray,rd_ptr_gray,wr_ptr,rd_ptr;
reg [WIDTH-1:0] rdata_o;
//reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_clk,rd_ptr_gray_wr_clk;
//reg [PTR_WIDTH-1:0] wr_ptr_rd_clk,rd_ptr_wr_clk;
wire full_o,empty_o,wr_error_o,rd_error_o;
integer i;
integer  wr_delay,rd_delay;
//reg [30*8:1] testname;
async_fifo dut(
	//write interface
	wr_clk_i,rd_clk_i,rst_i,wdata_i,full_o,wr_en_i,wr_error_o,
	//read interface
	rdata_o,empty_o,rd_en_i,rd_error_o
);
 //async_fifo dut(.*);

//clock generation
////need two
//write clock
initial begin
wr_clk_i=0;
forever #(WR_CLK_TP/2.0) wr_clk_i=~wr_clk_i;
//don't code anything after forver in any language
end

//read clock
initial begin
rd_clk_i=0;
forever #(RD_CLK_TP/2.0) rd_clk_i=~rd_clk_i;
//don't code anything after forver in any language
end
//reset apply,release
initial begin
//$value$plusargs("testname=%s",testname);
rst_i=1;//apply
wdata_i=0;
wr_en_i=0;
rd_en_i=0;

@(posedge wr_clk_i);//holding

rst_i=0;//releasing
/*case(testname)
"test_full" : begin
write_fifo(DEPTH);
end
"test_empty" :begin
write_fifo(DEPTH);
read_fifo(DEPTH);
end
"test_full_error" :begin
write_fifo(DEPTH+1);
end
"test_empty_error":begin
#50;
write_fifo(DEPTH);
read_fifo(DEPTH+1);
#50;
$finish;
end
"test_concurrent_wr_rd":begin
		fork 
begin
for(i=0;i<500;i=i+1)begin
write_fifo(1);//write one data in to fifo
wr_delay=$urandom_range(1,10);//1 to 10 mintues 
repeat(wr_delay)@(posedge wr_clk_i);
end
end
begin
for(i=0;i<500;i=i+1)begin 
rd_delay=$urandom_range(1,10);
read_fifo(1);//read one data from FIFO
repeat(rd_delay)@(posedge wr_clk_i);

end
end
join

end
endcase
#100;*/fork 
write_fifo(DEPTH);
read_fifo(DEPTH);
join
#1000;
$finish;
end
//endgenerate
task write_fifo(input integer num_wr);
begin

//now design in a state where we can apply the inputs
//apply dtimulus :write to the fifo and read to the fifo
for(i=0;i<num_wr;i=i+1)begin
@(posedge wr_clk_i);
wr_en_i=1;
wdata_i=$random;
end
@(posedge wr_clk_i);
wr_en_i=0;
wdata_i=0;
end

endtask
task read_fifo(input integer num_rd);
begin

for(i=0;i<num_rd;i=i+1)begin
@(posedge rd_clk_i);
rd_en_i=1;
end
@(posedge rd_clk_i);
rd_en_i=0;

end

endtask
endmodule

