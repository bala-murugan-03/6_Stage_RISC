module inst_wb(
    input clk,
    input rst,
    input en_ctrl,
    input valid_ctrl,
    input [2:0] rc_addr,
    input [15:0] rc_data,
    input rf_w_en,
    input [3:0] opcode,
    output reg regsel_out,
    output reg [2:0] rc_addr_out,
    output reg [15:0] rc_data_out,
    output reg rf_w_en_out,
    output reg complete
);

always@(posedge clk) begin
    if(rst) begin
        complete <= 0;
    end
    else if(en_ctrl && valid_ctrl) begin
        complete <= 1;
    end
    else
        complete <= 0;
end
always@(*) begin
    if(rst) begin
        rc_addr_out = 0;
        rc_data_out = 0;
        rf_w_en_out = 0;
        regsel_out = 0;
    end
    else if(en_ctrl && valid_ctrl) begin
        regsel_out = rf_w_en;
        rf_w_en_out = rf_w_en;
        rc_addr_out = rc_addr;
        rc_data_out = rc_data;
    end
    else begin 
        rc_addr_out = 0;
        rc_data_out = 0;
        rf_w_en_out = 0;
        regsel_out = 0;   
    end 
end
endmodule