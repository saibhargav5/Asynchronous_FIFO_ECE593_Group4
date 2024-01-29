parameter DEPTH=512;
parameter WIDTH=1024;
parameter PTR_WIDTH=9;

module Control_Unit(
  logic W,    
  logic F,
  logic R,
  logic E,
  reg wr_clk_i
);
//************************************************************To allow  Read (R) logic********************************************************
if(rd_en_i==1)begin
    if(empty_o==1)begin
    rd_error_o=1;
      R=0;
      end
      else begin  
          //store data in memory
          rdata_o=mem[rd_ptr];
          rd_error_o=0;
            if(rd_ptr==DEPTH-1) rd_toggle_f =~rd_toggle_f;
            //increment the rd_ptr
            rd_ptr=rd_ptr+1;
              R=1;
            end

  //************************************************************************To allow Write (W) logic****************************************************
always_ff@(posedge clk_i)begin
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
//mem=0;//wrong
for(i=0;i<DEPTH;i=i+1)begin
mem[i]=1;
end
end
else begin//rst_i not applied
//write can happen
wr_error_o=0;
rd_error_o=0;
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
	end
end  
//************************************************************For the output signals F and E *********************************************************************************
always@(*)begin
      //wr_ptr,rd_ptr,wr_toggle_f,rd_toggle_f
        E=0;
        F=0;
            for(i=0;i<DEPTH;i=i+1)begin
              mem[i]=1;
                end


  
                  if(wr_ptr==rd_ptr)begin
            if(wr_toggle_f==rd_toggle_f)empty_o=1;
              if(wr_toggle_f!=rd_toggle_f)full_o=1;
                end
              end


  
