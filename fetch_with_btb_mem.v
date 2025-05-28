`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2025 00:39:48
// Design Name: 
// Module Name: fetch_with_btb_mem
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
module fetch_with_btb_mem #(
  parameter NENTRY   = 16,
  parameter TAG_W    = 16,
  parameter TGT_W    = 16,
  parameter HIST_W   = 2
)(
  input  wire           clk,
  input  wire           reset_n,
 // input  wire           fetch_en,
  input  wire [TAG_W-1:0] pc_in,
  output wire [TAG_W-1:0] pc_next,
  // from execute stage:
  input  wire             br_update_en,
  input  wire [TAG_W-1:0] br_pc,
  input  wire [TGT_W-1:0] br_target,
  input  wire             br_taken,
  //output reg  [TAG_W-1:0]  pc_reg,
  output [TAG_W-1:0]  pc_reg,
  output mispredict,
  output btb_hit_wire
);



  // --------------------------------------------------------------------------
  //  BTB memories
  //  valid_mem: 1 bit per entry
  //  tag_mem:   full PC tag
  //  tgt_mem:   target PC
  //  hist_mem:  local 2-bit history counter
  // --------------------------------------------------------------------------
   reg               valid_mem [0:NENTRY-1];           // valid bits 
  reg [TAG_W-1:0]    tag_mem   [0:NENTRY-1];           // PC tags 
  reg [TGT_W-1:0]    tgt_mem   [0:NENTRY-1];           // branch targets 
   reg [HIST_W-1:0]   hist_mem  [0:NENTRY-1];           // per-entry 

  // FIFO pointer for replacement
  reg [$clog2(NENTRY)-1:0] alloc_ptr;

  integer i;
  // reset all valids and pointer
  always @(posedge clk) begin
    if (reset_n) begin
      alloc_ptr <= 0;
      for (i=0; i<NENTRY; i=i+1)
        valid_mem[i] <= 1'b0;
    end
  end

  // --------------------------------------------------------------------------
  //  Fully-assoc lookup: compare all tags in parallel
  // --------------------------------------------------------------------------
  reg                     btb_hit;
  reg [TGT_W-1:0]         btb_tgt;
  reg [HIST_W-1:0]        btb_hist;
  always @(*) begin
    btb_hit = 1'b0;
    btb_tgt  = {TGT_W{1'b0}};
    btb_hist = {HIST_W{1'b0}};
    for (i=0; i<NENTRY; i=i+1) begin
      if (valid_mem[i] && tag_mem[i] == pc_in) begin
        btb_hit = 1'b1;
        btb_tgt = tgt_mem[i];
        btb_hist = hist_mem[i];
      end
    end
  end
  assign btb_hit_wire=btb_hit;
reg found;
 integer idx;
   integer j;
  // --------------------------------------------------------------------------
  //  Update BTB on resolved taken branch: allocate or update entry
  // --------------------------------------------------------------------------
  always @(posedge clk) begin
    if (br_update_en && br_taken) begin
      // try to find existing entry
      
      found = 1'b0;
      for (idx=0; idx<NENTRY; idx=idx+1) begin
        if (valid_mem[idx] && tag_mem[idx] == br_pc) begin
          // update target and local history
          tgt_mem[idx]  <= br_target;
          // shift history and insert new outcome LSB
          hist_mem[idx] <= { hist_mem[idx][HIST_W-2:0], 1'b1 };
          found = 1'b1;
        end
      end
      if (!found) begin
        // allocate new entry at FIFO pointer
        valid_mem[alloc_ptr] <= 1'b1;
        tag_mem[alloc_ptr]   <= br_pc;
        tgt_mem[alloc_ptr]   <= br_target;
        // initialize history to "taken" just once
        hist_mem[alloc_ptr]  <= { {HIST_W-1{1'b0}}, 1'b1 };
        alloc_ptr            <= alloc_ptr + 1;
      end
    end
    else if (br_update_en && !br_taken) begin
      // for not-taken branches, update local history in BTB if present
    
      for (j=0; j<NENTRY; j=j+1) begin
        if (valid_mem[j] && tag_mem[j] == br_pc) begin
          hist_mem[j] <= { hist_mem[j][HIST_W-2:0], 1'b0 };
        end
      end
    end
  end

  // --------------------------------------------------------------------------
  //  Next-PC selection: if predictor MSB=1 (taken) AND BTB hit ? redirect
  // --------------------------------------------------------------------------

 assign  mispredict = br_update_en && (btb_hist != br_taken);
 wire [TAG_W-1:0] correct_pc = br_taken ? br_target : (br_pc + 1);           

   assign pc_next = ((btb_hist && btb_hit))
                   ? btb_tgt
                   : pc_in;
                   
                   


  
 assign pc_reg = mispredict ? correct_pc : pc_next; 
  

endmodule