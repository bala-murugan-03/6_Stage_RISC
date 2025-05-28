`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2025 02:44:05 PM
// Design Name: 
// Module Name: alu
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


module alu( op1,op2,op3,imm,prev_carry,prev_zero,opcode,alu_control,resulto,carry,zero,wb,branch,branch_addr); 
input [15:0] op1;
input [15:0] op2;
input [15:0] op3; //PC
input [15:0] imm;
input prev_zero;
input [3:0] opcode;
input prev_carry;
input [6:0] alu_control;
input wb;  
 
output [15:0] resulto;
output branch;
output [15:0] branch_addr;             
output reg carry,zero;
reg [15:0] result;
wire [15:0] op1o,op2o,op3o,immo,result_2s;

reg branch_taken;
reg updated_pc;


twos_comp twos_comp1(op1,op1o); 
twos_comp twos_comp2(op2,op2o); 
twos_comp twos_comp3(op3,op3o); 
twos_comp twos_comp4(imm,immo); 
twos_comp twos_comp5(result,result_2s); 

always @(*)  
begin   
      case(alu_control)  
        7'b0000000: result = op1o + op2o;                                 // ADD  
        7'b0000010: result = prev_carry ? (op1o + ~op2o) : 16'b0 ;        // ADC 
		7'b0000001: result = prev_zero ? (op1o + ~op2o) : 16'b0 ;         // ADZ
		7'b0000011: result = op1o + op2o + prev_carry;                    // AWC
		7'b0000100: result = op1o + ~op2o;                                // ACA    
		7'b0000110: result = prev_carry ? (op1o + ~op2o) : 16'b0 ;        // ACC 
		7'b0000101: result = prev_zero ? (op1o + ~op2o) : 16'b0 ;         // ACZ          
		7'b0000111: result = op1o + ~op2o + prev_carry;                   // ACW
	    7'b0001000: result = op1o + immo;	                              // ADDI 
        7'b0010000: result = ~(op1 & op2);                                // NAND 
        7'b0010010: result = prev_carry ? ~(op1 & op2) : 16'b0 ;          // NDC
        7'b0010001: result = prev_zero ? ~(op1 & op2) : 16'b0 ;           // NDZ
		7'b0010100: result = ~(op1o & (~op2o));                           // NCU
		7'b0010110: result = prev_carry ? ~(op1o & (~op2o)): 16'b0 ;      // NCC
		7'b0010101: result = prev_zero ? ~(op1o & (~op2o)): 16'b0 ;       // NCZ
		7'b0011000: result = immo;                                        // LLI 
		7'b0100000: result = op1o + immo;                                  // LW
		7'b0101000: result = op1o + immo;                                  // SW
		7'b1000000: result = op3o + immo;                                  // BEQ // BLT // BLE // JAL                                
		7'b1001000: result = op3o + immo;                                  // BEQ // BLT // BLE // JAL  
		7'b1010000: result = op3o + immo;                                  // BEQ // BLT // BLE // JAL  
		7'b1011000: result = op3o + immo;                                  // BEQ // BLT // BLE // JAL  				
        7'b1101000: result = op1o + immo;                                  // JRI
      default:result = op1o + op2o;                                       // Default ADD  
      endcase  
end 

assign resulto = (opcode == 4'b0010 ) ? result : result_2s;        //NAND without twos complement

always@(*)
begin
if (opcode== 4'b1000 || opcode== 4'b1001 || opcode== 4'b1010 ) 
    begin
      if (op1 == op2)branch_taken<=1; 
      else if (op1 < op2) branch_taken<=1;
      else if (op1 <= op2) branch_taken<=1;
      else   branch_taken<=0;      
    end 
    else begin
    branch_taken<=0;
    end
    
if(wb) 
     begin
	  if(opcode == 4'b0001 | opcode == 4'b0000 | opcode==4'b0010) //ADD, ADDI and NAND modifies zero flag
      zero  = (resulto==16'd0) ? 1'b1: 1'b0; 
	  if(opcode == 4'b0001 | opcode == 4'b0000)                   //ADD, ADDI modifies carry flag
	  carry = (( ~(op1o[15]) & ~(op2o[15]) & resulto[15] ) | ( op1o[15] & op2o[15] & ~(resulto[15]) ));
     end
end
 assign branch = branch_taken;
 assign branch_addr = branch_taken ? result :0;

				                                        
endmodule  
 
module twos_comp (a_i,f_o);
input  [15:0] a_i;
output reg [15:0] f_o;

always @(a_i[15:0] or f_o[15:0])
begin
	f_o = a_i;

end
endmodule
