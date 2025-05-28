module reg_file(
    input clk,
    input rst,
    input [15:0] PC_ctrl_in,
    input jmp_ctrl,
    input [2:0] addra,
    input [2:0] addrb,
    input [2:0] addrc,
    input [15:0] rf_data_c,
    input regsel,
    input rf_w,
    input freeze_ctrl,
    ///
    input mispredict,
    input [15:0] pc_reg,
    input btb_hit_wire,
    ////////
    output reg [15:0] rf_data_a,
    output reg [15:0] rf_data_b,
    output reg [15:0] PC_ctrl_out
);

reg [15:0] regfile [7:0];
reg rst_d;

always @(posedge clk) begin
  rst_d <= rst;
end
always@(posedge clk) begin
    
    if (rst || rst_d) begin
        PC_ctrl_out <= 0;
        regfile[0] <= 0;
        regfile[1] <= 0;
        regfile[2] <= 0;
        regfile[3] <= 0;
        regfile[4] <= 0;
        regfile[5] <= 0;
        regfile[6] <= 0;
        regfile[7] <= 0;
    end
    else begin
        if (jmp_ctrl ) begin
            regfile[0] <= (mispredict || btb_hit_wire)? pc_reg+1:PC_ctrl_in + 1; ///  +2
            PC_ctrl_out <=(mispredict || btb_hit_wire)? pc_reg+1: PC_ctrl_in + 1; 

        end 
        else if (mispredict || btb_hit_wire)
        begin 
            regfile[0] <= pc_reg+1;
            PC_ctrl_out <= pc_reg+1;
        end
        else if (!freeze_ctrl) begin
            regfile[0] <= regfile[0] + 1; // Increment PC
            PC_ctrl_out <= regfile[0] + 1;
        end
        else begin
            regfile[0] <= regfile[0];   
            PC_ctrl_out <= regfile[0];
        end     
           
        if (regsel && rf_w) begin
            regfile[addrc] <= rf_data_c; // Write to register
        end
    end
end

// Combinational read logic
always@(*) begin // short circuit no delay from here 
    if (rst) begin
        rf_data_a = 0;
        rf_data_b = 0;
//        PC_ctrl_out <= 0;
    end
    else if (regsel) begin
        rf_data_a = regfile[addra];
        rf_data_b = regfile[addrb];
    end
    else begin
        rf_data_a = 16'b0;
        rf_data_b = 16'b0;
    end

end

endmodule
