parameter DEPTH=512;
parameter WIDTH=1024;
parameter PTR_WIDTH=9;

module consumer(
                Data_out,
                Read,
                Empty,
                clk2
                );

  input logic[WIDTH-1:0]Data_out;    //Data given by the FIFO
  input Empty;                  //Empty bit is the input given by the control unit
  input clk2;
  output logic Read;            //read is read_enable signal given to control unit

  logic [WIDTH-1:0]mem[DEPTH];
  logic [PTR_WIDTH-1:0]rd_ptr;

  always_ff@(posedge clk2) begin
    if(Read)begin
      if(Empty)
        Data_out <= 0;
      else
        Data_out <= mem[rd_ptr];
    end
  end

endmodule
