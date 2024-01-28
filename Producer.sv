module producer #(parameter width=1024)
  (
  input logic clk1,Full,
    output logic [width-1:0]Data_out,
  output logic write);

  always_ff(clk1) begin
    if( !Full) begin
      Write =1'b1;
      Data_out= $random;
    end
    else
      wait(!Full);
    end
endmodule
    
    
  
