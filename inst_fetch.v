module inst_fetch(
    input clk,
    input rst,
    input [15:0] PC_ctrl,  // PC from control unit
    input en_ctrl, //ENABLE SIGNAL to freeze/unfreeze the pipeline
    ///
    input mispredict,
    input [15:0] pc_reg,
    //////
    output reg [15:0] PC_out,
    output reg en_mem,
    output reg valid_out,
    output [15:0] instr_out
);
always@(posedge clk)begin
    if(rst) begin
        en_mem <= 0;
        PC_out <= 0;
        valid_out <= 0;
        
    end
   else if(mispredict) begin
       PC_out <= pc_reg;
       en_mem <= 1;
       valid_out <=1;
   end 
   else if(en_ctrl) begin
        en_mem <= 1;
        PC_out <= PC_ctrl;
        valid_out <=1;
    end
    else begin //freeze the pipeline
     PC_out <= PC_out;
     en_mem <= 1;
     valid_out <= valid_out;
   end
end

inst_mem Imem(.PC(PC_out), .en(en_mem), .instr(instr_out));

endmodule