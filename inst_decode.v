module inst_decode(
    input clk,
    input rst,
    input [15:0] PC_in,
    input [15:0] instr,
    input en_ctrl,
    input valid_ctrl,
    input valid_f,
    input freeze_release,
    
    output reg [15:0] jloc, //to control unit
    output reg jvalid,     // to control unit
    output reg regsel,  // to select register file goes to RR stage
    output reg [3:0] opcode, // to RR stage
    output reg [2:0] ra,     // to RR stage
    output reg [2:0] rb,     // to RR stage
    output reg [2:0] rc,     // to RR stage, writeback is always passed in rc
    output reg [5:0] imm6,   // to RR stage
    output reg [8:0] imm9,   // to RR stage
    output reg [2:0] ccz,    // to RR stage
    output reg [15:0] PC_out,  // to RR stage
    output reg valid_out,
    output reg mult_freeze_cu
   
);
reg [2:0] count;
always@(posedge clk) begin
    if(rst) begin
        opcode <= 0;
        ra <= 0;
        rb <= 0;
        rc <= 0;
        imm6 <= 0;
        imm9 <= 0;
        ccz <= 0;
        PC_out <= 0;
        regsel <= 0;
        jloc <= 0;
        jvalid <= 0;
        valid_out <=0;
        mult_freeze_cu <= 0;
        count <= 7;
    end
    else if(en_ctrl && valid_ctrl && valid_f) begin
        if(instr[15:12] == 4'd1) begin //add i instr
            count <= 7;
            opcode <= instr[15:12];
            ra <= instr[11:9];
            regsel <= 1;
            rc <= instr[8:6]; // rb is not used here
            imm6 <= instr[5:0];
            PC_out <= PC_in;
            imm9 <= 0;
            rb <= 0;
            ccz <= 0;
            jloc <= 0;
            jvalid <= 0;
            valid_out <= 1;
            count <= 7;
        end
        else if(instr[15:12] == 4'd4 || instr[15:12] == 4'd12) begin // lw instr and JLR instr
            opcode <= instr[15:12];
            rc <= instr[11:9]; // address to be writeback
            regsel <= 1;
            rb <= instr[8:6]; // address to be read
            imm6 <= instr[5:0];
            PC_out <= PC_in;
            imm9 <= 0;
            ra <= 0;
            ccz <= 0;
            jloc <= 0;
            jvalid <= 0;
            valid_out <= 1;
        end
        else if(instr[15:12] == 4'd5 || instr[15:12] == 4'd8 || instr[15:12] == 4'd9 || instr[15:12] == 4'd10) begin //store and branch instr
            opcode <= instr[15:12];
            ra <= instr[11:9]; //address to be read for data
            regsel <= 1;
            rb <= instr[8:6]; // base address
            imm6 <= instr[5:0];
            PC_out <= PC_in;
            imm9 <= 0;
            rc <= 0; // writeback is to mem so no reg c addr needed
            ccz <= 0;
            jloc <= 0;
            jvalid <= 0;
            valid_out <= 1;
            count <= 7;
        end
        else if(instr[15:12] == 4'd3) begin //LLI instr
            opcode <= instr[15:12];
            rc <= instr[11:9];
            regsel <= 0; // no need to read registers
            imm9 <= instr[8:0];
            PC_out <= PC_in;
            jloc <= 0;
            jvalid <= 0;
            ra <= 0;
            rb <= 0;
            imm6 <= 0;
            ccz <=0;
            valid_out <= 1;
            count <= 7;
        end
        else if(instr[15:12] == 4'd6 || instr[15:12] == 4'd7) begin //LM and SM
            opcode <= instr[15:12];
            ra <= instr[11:9]; //read reg a for base address
            regsel <= 1; 
            imm9 <= instr[8:0];
            PC_out <= PC_in;
            mult_freeze_cu <= 1;
            jloc <= 0;
            jvalid <= 0;
            rc <= 0;
            rb <= 0;
            imm6 <= 0;
            ccz <=0;  
            valid_out <= 1; 
            count <= count - 1;         
        end
        else if(instr[15:12] == 4'd13) begin //JRI instr
            opcode <= instr[15:12];
            ra <= instr[11:9]; //read reg a for base address
            regsel <= 1; 
            imm9 <= instr[8:0];
            PC_out <= PC_in;
            jloc <= 0;
            jvalid <= 0;
            rc <= 0;
            rb <= 0;
            imm6 <= 0;
            ccz <=0;  
            valid_out <= 1;  
            count <= 7;
        end
        else if (instr[15:12] == 4'd11)begin // jal instr
            opcode <= instr[15:12];
            rc <= instr[11:9];
            jloc <= PC_in + {{7{instr[8]}},instr[8:0]};
            jvalid <= 1;
            regsel <= 1;
            imm6 <= 0;
            imm9 <= 0;
            rb <= 0;
            ra <= 0;
            ccz <= 0;
            PC_out <= PC_in;
            valid_out <= 1;
            count <= 7;
        end
        else if(instr[15:12] == 4'd0 || instr[15:12] == 4'd2) begin   //ADD and NAND (R type) instr
            opcode <= instr[15:12];
            ra <= instr[11:9];
            regsel <= 1;
            rb <= instr[8:6];
            rc <= instr[5:3];
            ccz <= instr[2:0];
            PC_out <= PC_in;
            jloc <= 0;
            imm6 <= 0;
            imm9 <= 0;
            jvalid <= 0;
            valid_out <= 1;
            count <= 7;
        end
        else begin   //to catch if the instruction is invalid
            opcode <= 0;
            ra <= 0;
            rb <= 0;
            rc <= 0;
            imm6 <= 0;
            imm9 <= 0;
            ccz <= 0;
            PC_out <= 0;
            regsel <= 0;
            jloc <= 0;
            jvalid <= 0;
            valid_out <=0;
            count <= 7;
        end
        
    end
    else if (!valid_ctrl) begin // to flush the instr
        opcode <= 0;
        ra <= 0;
        rb <= 0;
        rc <= 0;
        imm6 <= 0;
        imm9 <= 0;
        ccz <= 0;
        PC_out <= 0;
        regsel <= 0;
        jloc <= 0;
        jvalid <= 0;
        valid_out <=0;
    end
    else begin  //to freeze the pipeline
      if(count <= 0) begin
        mult_freeze_cu <= 0;
        count <= 7;
      end
      else begin
        opcode <= opcode;
        ra <= ra;
        rb <= rb;
        rc <= rc;
        imm6 <= imm6;
        imm9 <= imm9;
        ccz <= ccz;
        PC_out <= PC_out;
        regsel <= regsel;
        jloc <= jloc;
        jvalid <= jvalid; 
        count <= count - 1; 
        valid_out <= valid_out;
    end
    end
end


endmodule