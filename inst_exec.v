`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2025 15:03:13
// Design Name: 
// Module Name: inst_exec
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module inst_exec(
    input clk,
    input rst,
    input en_ctrl_ex,
    input valid_ctrl_ex,
    input [15:0] pc,
    input [3:0] opcode,
    input [15:0] data_ra,
    input [15:0] data_rb,
    input [2:0] writeback_rc,
    input [2:0] ccz,
    input [5:0] imm_6,
    input [8:0] imm_9,
    input valid_rr,
    
    output reg mem_r,
    output reg mem_w,
    output reg [15:0] ls_mem_addr,
    output reg [15:0] store_data,
    output reg [15:0] br_target_addr, //branch target address //both goes to control unit
    output reg br_valid, //high if branch is taken
    //for branch predictor signals start
    output reg br_update_en,
    output reg [15:0] br_inst_pc,
    //end
    output reg writeback_valid,
    output [15:0] writeback_data,
    output [2:0] writeback_addr,
    output [3:0] opcode_ex,
    output reg valid_out
    );

wire carry;
wire zero;
reg [15:0] alureg_result;
reg [2:0] wb_addr;
reg zero_flag;
reg carry_flag;
wire branch_valid;
reg [3:0] opcode_exec;
wire [15:0] bta;
wire [15:0] immediate = (opcode == 4'b0001 || opcode == 4'b0100 || opcode == 4'b0101 || opcode == 4'b1000 || opcode == 4'b1001 || opcode == 4'b1010)? {{10{imm_6[5]}},imm_6} : {{7{imm_9[8]}},imm_9};
wire [15:0] alu_result;
alu alu_unit(.op1(data_ra),.op2(data_rb),.op3(pc),.imm(immediate),.opcode(opcode),.prev_carry(carry_flag),.prev_zero(zero_flag),
.alu_control({opcode[3:0],ccz[2:0]}),.resulto(alu_result),.carry(carry),.zero(zero),.wb(writeback_valid),.branch(branch_valid),.branch_addr(bta));
  always @(posedge clk) begin
    if (rst) begin
        mem_r <=0;
        mem_w <=0;
        ls_mem_addr <=0;
        store_data <=0;
        br_target_addr <=16'b0;
        br_valid <=1'b0;
        br_update_en <=0; ///////
        writeback_valid <=0;
        zero_flag <=0;
        carry_flag <=0;
        alureg_result <= 0;
        wb_addr <= 0;
        valid_out <= 0;
    end
    else begin
        br_inst_pc <= pc; 
        if(en_ctrl_ex && valid_ctrl_ex && valid_rr )begin
        
        zero_flag <=zero;
        carry_flag <=carry;
        br_valid <=0; //write pc out here
        case (opcode)
        
        
        
        4'b0000: //ADD
            begin
            opcode_exec<=opcode;
            alureg_result <= alu_result;
            wb_addr <= writeback_rc;
            mem_r <=0;
            mem_w <=0;
            ls_mem_addr <=0;
            store_data <=0;
            br_target_addr <=0;
            br_update_en <=1'b0;/////////////
            br_valid <=0;            
                if (ccz[1:0]==2'b10) begin
                    writeback_valid <= carry_flag ? 1'b1 : 1'b0;
                    valid_out <= carry_flag ? 1'b1 : 1'b0;
                end
                else if (ccz[1:0]==2'b01) begin
                     writeback_valid <= zero_flag ? 1'b1 : 1'b0;
                     valid_out <= zero_flag ? 1'b1 : 1'b0;
                end
                else if (ccz[1:0]== 2'b00 || ccz[1:0]== 2'b11 ) begin
                    valid_out <= 1;
                    writeback_valid<=1'b1;
                    end
                else 
                     writeback_valid<=1'b0;
                     valid_out <= 0;
            end 
        4'b0001: begin
            opcode_exec<=opcode;
            alureg_result <= alu_result;
            wb_addr <= writeback_rc;
            mem_r <=0;
            mem_w <=0;
            valid_out <= 1;
            ls_mem_addr <=0;
            store_data <=0;
            br_target_addr <=0;
            br_valid <=0;
            br_update_en <=1'b0;//////////
            writeback_valid<=1'b1; //ADDI
            end
        4'b0010: // NAND
            begin
            opcode_exec<=opcode;
            alureg_result <= alu_result;
            wb_addr <= writeback_rc;
            mem_r <=0;
            mem_w <=0;
            ls_mem_addr <=0;
            store_data <=0;
            br_target_addr <=0;
            br_update_en <=1'b0; /////////////
            br_valid <=0;
                if (ccz[1:0]==2'b10) begin
                    writeback_valid <= carry_flag ? 1'b1 : 1'b0;
                    valid_out <= carry_flag ? 1'b1 : 1'b0; 
                end
                else if (ccz[1:0]==2'b01) begin
                    writeback_valid <= zero_flag ? 1'b1 : 1'b0;
                    valid_out <= zero_flag ? 1'b1 : 1'b0;
                end
                else if (ccz[1:0]== 2'b00) begin
                    writeback_valid<=1'b1;
                    valid_out <= 1;
                end
                else begin
                    writeback_valid<=1'b0;
                    valid_out <= 0;
                end  
            end 
        4'b0011: //LLI Load immediate
            begin
            opcode_exec<=opcode;
            alureg_result <= alu_result;
            wb_addr <= writeback_rc;
            mem_r <=0;
            mem_w <=0;
            valid_out <= 1;
            ls_mem_addr <=0;
            store_data <=0;
            br_target_addr <=0;
            br_valid <=0; 
            br_update_en <=1'b0; //////////////////
            writeback_valid<= 1'b1;
            end
        4'b0100: //LW Load Word
            begin
            opcode_exec<=opcode;
            alureg_result <= 0;
            wb_addr <= writeback_rc;
            mem_w <=0;
            store_data <=0;
            br_target_addr <=0;
            br_valid <=0;
            br_update_en <=1'b0;
            ls_mem_addr <= data_rb + immediate;
            mem_r <=1;
            valid_out <= 1;
            writeback_valid<= 1'b1;
            end
        4'b0110: //LM Load Multiple
            begin
            opcode_exec<=opcode;
            alureg_result <= 0;
            wb_addr <= writeback_rc;
            mem_w <=0;
            store_data <=0;
            br_target_addr <=0;
            br_valid <=0;
            br_update_en <=1'b0;
            ls_mem_addr <= data_rb + immediate;
            mem_r <=1;
            valid_out <= 1;
            writeback_valid<= 1'b1;
            end
        4'b0101: //SW Store word
            begin
            opcode_exec<=opcode;
            alureg_result <= 0;
            wb_addr <= writeback_rc;
            ls_mem_addr <= data_rb + immediate;
            mem_w <=1;
            store_data <= data_ra;
            br_target_addr <=0;
            br_valid <=0;
            br_update_en <=1'b0;
            mem_r <=0;
            writeback_valid<= 1'b0;
            valid_out <= 0;
            end
        4'b0111: //SM Store Multiple
            begin
            opcode_exec<=opcode;
            alureg_result <= 0;
            wb_addr <= writeback_rc;
            ls_mem_addr <= data_rb + immediate;
            mem_w <=1;
            store_data <= data_ra;
            br_target_addr <=0;
            br_valid <=0;
            br_update_en <=1'b0;
            mem_r <=0;
            valid_out <= 1;
            writeback_valid<= 1'b0;
            end
        4'b1000:  //beq
            begin
            opcode_exec<=opcode;
            alureg_result <= 0;
            wb_addr <= writeback_rc;
            ls_mem_addr <= 0;
            mem_w <=0;
            store_data <= 0;
            mem_r <=0;
            br_target_addr <=bta;
            br_update_en <=1'b1; ///////
            br_valid <=branch_valid;
            writeback_valid<= 1'b0;
            valid_out <= 0;
            end
        4'b1001: //blt
            begin
            opcode_exec<=opcode;
            alureg_result <= 0;
            wb_addr <= writeback_rc;
            ls_mem_addr <= 0;
            mem_w <=0;
            store_data <= 0;
            mem_r <=0;
            br_target_addr <=bta;
            br_update_en <=1'b1;
            br_valid <=branch_valid;
            writeback_valid<= 1'b0;
            valid_out <= 0;
            end
        4'b1010:  //ble
            begin
            opcode_exec<=opcode;
            alureg_result <= 0;
            wb_addr <= writeback_rc;
            ls_mem_addr <= 0;
            mem_w <=0;
            store_data <= 0;
            mem_r <=0;
            br_target_addr <=bta;
            br_update_en <=1'b1;  ///////////
            br_valid <=branch_valid;
            writeback_valid<= 1'b0;
            valid_out <= 0;
            end
        4'b1011:        //JAL
            begin
            opcode_exec<=opcode;
            alureg_result <= pc+1;
            wb_addr <= writeback_rc;
            ls_mem_addr <= 0;
            mem_w <=0;
            store_data <= 0;
            mem_r <=0;
            br_valid <=1'b0;
            br_update_en <=1'b0; 
//            br_target_addr <=bta;
//            br_valid <=branch_valid;
            writeback_valid<= 1'b1;
            valid_out <= 1;
            end  
        4'b1100:        //JLR
            begin
            opcode_exec<=opcode;
            alureg_result <= pc + 1 ;
            wb_addr <= writeback_rc;
            ls_mem_addr <= 0;
            mem_w <=0;
            store_data <= 0;
            mem_r <=0;
            br_target_addr <=data_rb;
            br_valid <= 1;
            br_update_en<=1'b0;
            writeback_valid<= 1'b1;
            valid_out <= 1;
            end
        4'b1101:         //JRI
            begin
            opcode_exec<=opcode;
            alureg_result <= alu_result;
            wb_addr <= writeback_rc;
            ls_mem_addr <= 0;
            mem_w <=0;
            store_data <= 0;
            mem_r <=0;
            br_target_addr <=bta;
            br_update_en<=1'b0;
            br_valid <=branch_valid;
            writeback_valid<= 1'b1;
            valid_out <= 1;
            end    
        default: begin
            mem_r <=0;
            mem_w <=0;
            ls_mem_addr <=0;
            store_data <=0;
            br_target_addr <=0;
            br_valid <=0;
            br_update_en<=1'b0;
            writeback_valid <=0;
            opcode_exec<=0;
            alureg_result <= 0;
            wb_addr <= 0; 
            opcode_exec <= 0;
            valid_out <= 0;
        end        
        endcase
        
    end
    
    else if (!valid_ctrl_ex) begin // to flush the instr
        mem_r <= 1'b0;
        mem_w <= 1'b0;
        ls_mem_addr <= 16'b0;
        store_data <= 16'b0;
        br_target_addr <= 16'b0;
        br_valid <= 1'b0;
        writeback_valid <= 16'b0;
        opcode_exec<=16'b0;
        alureg_result <= 16'b0;
        wb_addr <= 16'b0;
        valid_out <= 0;
    end
    else if(!valid_rr) begin
//        mem_r <= mem_r;
//        mem_w <= mem_w;
//        ls_mem_addr <=ls_mem_addr;
//        store_data <= store_data;
//        br_target_addr <= br_target_addr;
//        br_valid <= br_valid;
//        writeback_valid <= 0;
//        opcode_exec<=opcode;
//        alureg_result <= alureg_result;
//        wb_addr <= wb_addr;
        mem_r <= 1'b0;
        mem_w <= 1'b0;
        ls_mem_addr <= 16'b0;
        store_data <= 16'b0;
        br_target_addr <= 16'b0;
        br_valid <= 1'b0;
        writeback_valid <= 16'b0;
        opcode_exec<=16'b0;
        alureg_result <= 16'b0;
        wb_addr <= 16'b0;
        valid_out <= 0;
    end
    else begin  //to freeze the pipeline
        
        mem_r <= mem_r;
        mem_w <= mem_w;
        ls_mem_addr <=ls_mem_addr;
        store_data <= store_data;
        br_target_addr <= br_target_addr;
        br_valid <= br_valid;
        writeback_valid <= writeback_valid;
        opcode_exec<=opcode;
        alureg_result <= alureg_result;
        wb_addr <= wb_addr;
        valid_out <= valid_out;
//        mem_r <= 1'b0;
//        mem_w <= 1'b0;
//        ls_mem_addr <= 16'b0;
//        store_data <= 16'b0;
//        br_target_addr <= 16'b0;
//        br_valid <= 16'b0;
//        writeback_valid <= 16'b0;
//        opcode_exec<=16'b0;
//        alureg_result <= 16'b0;
//        wb_addr <= 16'b0;
    end
    
    end 
    end

 assign writeback_data =  alureg_result;
 assign writeback_addr = wb_addr ;  
 assign opcode_ex = opcode_exec;
endmodule