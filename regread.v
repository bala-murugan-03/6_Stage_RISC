module regread(
    input clk,
    input rst,
    input [2:0] rega,
    input [2:0] regb,
    input [2:0] regc,
    input [5:0] imm6,
    input [8:0] imm9,
    input [2:0] ccz,
    input en_ctrl,
    input regsel,
    input [3:0] opcode_in,
    input valid_ctrl,
    input [15:0] PC_in,
    input valid_d,
    
    output reg [2:0] addr_a, // to regfile
    output reg regsel_out,  // to regfile
    output reg [2:0] addr_b, // to regfile
    output reg [2:0] regc_out, // to exec
    output reg [2:0] ccz_out, // to exec
    output reg [5:0] imm6_out, //to exec
    output reg [8:0] imm9_out, //to exec
    output reg [3:0] opcode_out, // to exec
    output reg [15:0] PC_out,    // to exec
    output reg valid_out,
    output reg freeze_release
);
reg[2:0] count;
reg [2:0] addrincr;
always@(posedge clk) begin
    if(rst) begin
        addr_a <= 0;
        addr_b <= 0;
        regc_out <= 0;
        imm6_out <= 0;
        imm9_out <= 0;
        ccz_out <= 0;
        opcode_out <= 0;
        PC_out <= 0;
        regsel_out <= 0;
        valid_out <=0;
        count <= 7;
        addrincr <= 0;
        freeze_release <= 0;
    end
    else if(en_ctrl && valid_ctrl && valid_d) begin
        opcode_out <= opcode_in;
       // opcode_out <= flag_d?opcode_in:4'd0;
        imm6_out <= imm6;
        ccz_out <= ccz;
        if(opcode_in == 4'd0 || opcode_in == 4'd2 || opcode_in == 4'd5 || opcode_in == 4'd8 || opcode_in == 4'd9 || opcode_in == 4'd10) begin //ADD,NAND,STORE and BRANCH instr
            addr_a <= rega;
            addr_b <= regb;
            PC_out <= PC_in;
            regsel_out <= regsel;
            imm9_out <= imm9;
            regc_out <= regc; // register to be written back
            valid_out <= 1;
        end
        else if(opcode_in == 4'd1 || opcode_in == 4'd13)begin // ADDI, JRI instr
            addr_a <= rega;
            PC_out <= PC_in;
            addr_b <= 0;
            regsel_out <= regsel;     
            imm9_out <= imm9;
            regc_out <= regc; // register to be written back
            valid_out <=1;
        end
        else if(opcode_in == 4'd4 || opcode_in == 4'd12) begin //LW and JLR
            addr_b <= regb;
            addr_a <= 0;
            PC_out <= PC_in;
            regsel_out <= regsel; 
            imm9_out <= imm9;
            regc_out <= regc; // register to be written back
            valid_out <=1; 
        end
        else if(opcode_in == 4'd6) begin //LM 
          if(count > 0) begin
            freeze_release <= 0;
            if(imm9[count]) begin
                count <= count - 1;
                addr_b <= rega;
                addr_a <= 0;
                regsel_out <= regsel; 
                imm9_out <= addrincr;
                regc_out <= count; // register to be written back 
                valid_out <=1;
                addrincr <= addrincr + 1;
                opcode_out <= opcode_in;
                PC_out <= PC_in;
            end
            else begin
                 count <= count - 1;
                 addr_b <= rega;
                 addr_a <= 0;
                 regsel_out <= regsel;
                 imm9_out <= addrincr;
                 valid_out <= 0;
                 opcode_out <= opcode_in;
                 PC_out <= PC_in;
            end
          end
          else begin
             if(imm9[count]) begin
                addr_b <= rega;
                addr_a <= 0;
                count <= 7;
                addrincr <= 0;
                regsel_out <= regsel; 
                imm9_out <= addrincr;
                regc_out <= count; // register to be written back 
                valid_out <=1;
                freeze_release <= 1;
                addrincr <= addrincr;
                opcode_out <= opcode_in;
                PC_out <= PC_in;

            end
            else begin
                 count <= 7;
                 addr_b <= 0;
                 addr_a <= 0;
                 addrincr <= 0;
                 freeze_release <= 1; 
                 regsel_out <= regsel;
                 imm9_out <= 0;
                 regc_out <= count;
                 valid_out <= 0;
                 opcode_out <= 0;
                 PC_out <= PC_in;
            end
          end
         end   
        else if(opcode_in == 4'd7) begin //SM
          if(count > 0) begin
            freeze_release <= 0;
            if(imm9[count]) begin
                count <= count - 1;
                addr_b <= rega;
                addr_a <= count;
                regsel_out <= regsel; 
                imm9_out <= addrincr;
                regc_out <= 0; // register to be written back 
                valid_out <=1;
                addrincr <= addrincr + 1;
                opcode_out <= opcode_in;
                PC_out <= PC_in;
            end
            else begin
                 count <= count - 1;
                 addr_b <= rega;
                 addr_a <= count;
                 regsel_out <= regsel;
                 imm9_out <= addrincr;
                 valid_out <= 0;
                 opcode_out <= opcode_in;
                 PC_out <= PC_in;
            end
          end
          else begin
             if(imm9[count]) begin
                addr_b <= rega;
                addr_a <= count;
                count <= 7;
                addrincr <= 0;
                regsel_out <= regsel; 
                imm9_out <= addrincr;
                regc_out <= 0; // register to be written back 
                valid_out <=1;
                freeze_release <= 1;
                opcode_out <= opcode_in;
                PC_out <= PC_in;

            end
            else begin
                 count <= 7;
                 addr_b <= 0;
                 addr_a <= 0;
                 addrincr <= 0;
                 freeze_release <= 1; 
                 regsel_out <= regsel;
                 imm9_out <= 0;
                 valid_out <= 0;
                 opcode_out <= 0;
                 PC_out <= PC_in;
            end
          end
         end       
        else begin
            addr_a <= 0;
            addr_b <= 0;
            regsel_out <= regsel;
            PC_out <= PC_in;
            imm9_out <= imm9;
            regc_out <= regc; // register to be written back
            valid_out <=1;
        end
    end
    else if (!valid_ctrl) begin // to flush the instr
        opcode_out <= 0;
        addr_a <= 0;
        addr_b <= 0;
        PC_out <= 0;
        regsel_out <= 0;
        imm6_out <= 0;
        imm9_out <= 0;
        regc_out <= 0;
        ccz_out <= 0;
        valid_out <=0;
    end
    else if(!en_ctrl) begin  //to freeze the pipeline
        opcode_out <= opcode_out;
        addr_a <= addr_a;
        addr_b <= addr_b;
        PC_out <= PC_out;
        regsel_out <= regsel_out;
        imm6_out <= imm6_out;
        imm9_out <= imm9_out;
        regc_out <= regc_out;
        ccz_out <= ccz_out;
        valid_out <=valid_out;
    end
    else begin // if valid_d = 0
        opcode_out <= 0;
        addr_a <= 0;
        addr_b <= 0;
        PC_out <= 0;
        regsel_out <= 0;
        imm6_out <= 0;
        imm9_out <= 0;
        regc_out <= 0;
        ccz_out <= 0;
        valid_out <=0;
        freeze_release <= 0;
    end
end
endmodule