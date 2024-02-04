# Asynchronous_FIFO_ECE593_Group4
This repository is created to track the project work of ECE-593-WCC Winter 2024. The project we are going to work on is Design and Verification of Asynchronous FIFO using system verilog and UVM.
e async_fifo(
//write interface 
wr_clk_i,rd_clk_i,rst_i,wdata_i,full_o,wr_en_i,wr_error_o,

//read interface
rdata_o,empty_o,rd_en_i,rd_error_o
);

parameter DEPTH=512;
parameter WIDTH=1024;
parameter PTR_WIDTH=9;
//wr_ptr is internal to the design
//declare all inputs and outputs
input wr_clk_i,rd_clk_i,rst_i,wr_en_i,rd_en_i;
input [WIDTH-1:0] wdata_i;
output reg [WIDTH-1:0] rdata_o;
output reg full_o,empty_o,wr_error_o,rd_error_o;
//declare the memory
reg [WIDTH-1:0] mem [DEPTH-1:0];
integer i;
//wr_ptr,rd_ptr,toggle flags(scalar)
reg [PTR_WIDTH-1:0] wr_ptr,rd_ptr;
reg [PTR_WIDTH-1:0] wr_ptr_gray,rd_ptr_gray;
reg [PTR_WIDTH-1:0] wr_ptr_rd_clk,rd_ptr_wr_clk;
reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_clk,rd_ptr_gray_wr_clk;
reg wr_toggle_f,rd_toggle_f;
reg wr_toggle_f_rd_clk,rd_toggle_f_wr_clk;

//fifo is sequebntial design
//process in fifo
//writ,read=>do they happen on same or differnt clock?differnt clock
//both can be coded in to differnt always block
//write always block
always@(posedge wr_clk_i%3==0)begin
if(rst_i==1)begin
//all reg varibles assign to rest values
rdata_o=0;
full_o=0;
empty_o=1;
//error_o=0;
wr_error_o=0;
rd_error_o=0;
wr_ptr=0;
rd_ptr=0;
wr_toggle_f=0;
rd_toggle_f=0;
wr_ptr_gray=0;
rd_ptr_gray=0;
wr_ptr_gray_rd_clk=0;
rd_ptr_gray_wr_clk=0;
wr_toggle_f_rd_clk=0;
rd_toggle_f_wr_clk=0;
wr_ptr_rd_clk=0;
rd_ptr_wr_clk=0;
//mem=0;//wrong
for(i=0;i<DEPTH;i=i+1)begin
mem[i]=1;
end
end
else begin//rst_i not applied
//write can happen
wr_error_o=0;
	if(wr_en_i==1)begin
		if(full_o==1)begin
		wr_error_o=1;
		
		end
	else begin
 	mem[wr_ptr]=wdata_i;
	wr_error_o=0;
//increment the wr_ptr
if(wr_ptr==DEPTH-1)
wr_toggle_f=~wr_toggle_f;

	wr_ptr=wr_ptr+1;//DEPTH-1-> DEPTH(16) =>0
	wr_ptr_gray={wr_ptr,wr_ptr[3:1]^wr_ptr[2:0]};
	end
end



end

end
//***************READ always block************************
always@(posedge rd_clk_i%2 ==0)begin
if(rst_i!=1)begin//go into this code ,only if reset is not applied
rd_error_o=0;



//read can happen
	if(rd_en_i==1)begin
		if(empty_o==1)begin
		rd_error_o=1;
		end
//	end
	else begin
//store data in memory
 	rdata_o=mem[rd_ptr];
	rd_error_o=0;
	if(rd_ptr==DEPTH-1) rd_toggle_f =~rd_toggle_f;

	//increment the rd_ptr
	rd_ptr=rd_ptr+1;
	rd_ptr_gray={rd_ptr[3],rd_ptr[3:1]^rd_ptr[2:0]};
	//MSB bit ,remaining bits XOR in one bit shifted manner
	end
//increment the rd_ptr
end
end
end
//full
//
//combinational in logic
always@(*)begin

//wr_ptr,rd_ptr,wr_toggle_f,rd_toggle_f
empty_o=0;
full_o=0;
if(wr_ptr_gray==rd_ptr_gray_wr_clk)begin
if(wr_toggle_f!=rd_toggle_f)full_o=1;
end
//empty
if(wr_ptr_gray_rd_clk==rd_ptr_gray)begin 
if(wr_toggle_f_rd_clk==rd_toggle_f)empty_o=1;
end
end
always@(posedge rd_clk_i)begin//to stage synchonizer
wr_ptr_gray_rd_clk<=wr_ptr_gray;
wr_toggle_f_rd_clk<=wr_toggle_f;
end
always@(posedge wr_clk_i)begin
rd_ptr_gray_wr_clk<=rd_ptr_gray;
rd_toggle_f_wr_clk<=rd_toggle_f;
end
endmodule
