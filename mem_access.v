module mem_access(
    input clk,
    input rst,
    input mem_r,
    input mem_w,
    input en_ctrl,
    input valid_ctrl,
    input [15:0] ls_addr,
    input [15:0] store_data,
    input [3:0] opcode_in,
    input [2:0] rc_addr,
    input [15:0] rc_data,
    input rc_w_valid,
    output reg [2:0] rc_addr_out,
    output [15:0] rc_data_out,
    output reg rc_w_valid_out,
    output reg [3:0] opcode_out,
    output reg valid_out
    
);
wire [15:0] read_data;
reg [15:0] regrc_data;
data_mem DM(.clk(clk),.rst(rst),.mem_access_addr(ls_addr),.mem_write_data(store_data),.mem_write_en(mem_w),.mem_read_en(mem_r),.mem_read_data(read_data));
always@(posedge clk) begin
    if(rst) begin
      rc_addr_out <= 0;
      rc_w_valid_out <= 0;
      opcode_out <= 0;
      regrc_data <= 0;
      valid_out <= 0;
    end
    else if (en_ctrl && valid_ctrl) begin
      rc_addr_out <= rc_addr;
      rc_w_valid_out <= rc_w_valid;
      opcode_out <= opcode_in;
      regrc_data <= rc_data;
      valid_out <= 1;
    end
    else begin // to flush the instr
      rc_addr_out <= 0;
      rc_w_valid_out <= 0;
      opcode_out <= 0; 
      regrc_data <= 0;
      valid_out <= 0;
    end
end
assign rc_data_out = (opcode_out == 4'd4 || opcode_out == 4'd6)?read_data:regrc_data; // LW and LM instr
endmodule