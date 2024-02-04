module asynchronous_fifo # ( parameter depth= 512, parameter width = 64)( 
input logic clk1,clk2,reset,wr_en,rd_en,
input logic [width-1:0]din,
output logic [width-1:0]dout,
output logic full,empty,almost_full,almost_empty);

reg [width-1:0] mem [depth-1:0];
logic [8:0]wrptr,rdptr;

int counter1=0;
int counter2=0;

assign full=(rdptr == 9'b101011110)?1'b1:1'b0;
assign empty=(rdptr == wrptr)?1'b1:1'b0;
assign almost_full=(rdptr == 9'b101001010)?1'b1:1'b0;
assign almost_empty=(rdptr == 9'b101001010)?1'b1:1'b0;

always @(posedge clk1 or negedge reset)
begin
        if(reset)
        begin
          for(int i=0;i<=depth;i=i+1)
            mem[i]<=64'b0;       
        end
        else if(counter1%3==0 && wr_en ==1 && full== 0)
          mem[wrptr]<=din;
 end

always_ff@(posedge clk1)
begin
  if(reset)    counter1=0;
  else         counter1=counter1+1;
end

always_ff@(posedge clk2)
begin
  if(reset)    counter2=0;
  else         counter2=counter2+1;
end

always_ff @(posedge clk2 or posedge  reset)
begin
  if(reset)                                                      dout<=64'b0;
  else if(counter2%2 == 0 && rd_en==1'b1 && empty==1'b0)   dout<= mem[rdptr];
end

always_ff @(posedge clk1)
begin
      if(reset)                                                   wrptr<=9'b0;
      else if( counter1%3==0 && wr_en==1'b1 && full==1'b0)  wrptr<=wrptr+1'b1; 
end

always_ff@(posedge clk2)
begin
      if(reset)                                                     rdptr<=9'b0;
      else if(counter2%2 ==0 && rd_en==1'b1 && empty==1'b0)   rdptr<=rdptr+1'b1;
end
endmodule