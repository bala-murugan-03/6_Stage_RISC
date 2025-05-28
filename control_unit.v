module control_unit(
    input clk,
    input rst,
    input [15:0] PC_ctrl_rf,
    input jvalid, // from decode
    input [15:0] jloc, //decode
    input br_valid, //from exec
    input [15:0] br_loc,
    input [3:0] opcode_rr, //from rr unit   (can be used at LM and SM)
    input [3:0] opcode_ex,
    input [2:0] ra_rr, // from rr
    input [2:0] rb_rr, // from rr
    input [15:0] data_a_rr,
    input [15:0] data_b_rr,
    input [2:0] rc_ex, //from ex
    input valid_ex,
    input valid_ma,
    input [2:0] rc_mem, //from mem
    input [15:0] datac_ex,
    input [15:0] datac_mem,
    input mult_freeze_d,
    /////
    input mispredict,
    //////
    
 // all blocks en ctrl and valid ctrl
    output reg freeze_ctrl,
    output reg en_ctrl_f,
    output reg en_ctrl_d,
    output reg valid_ctrl_d,
    output reg en_ctrl_rr,
    output reg valid_ctrl_rr,
    output reg en_ctrl_ex,
    output reg valid_ctrl_ex,
    output reg en_ctrl_ma,
    output reg valid_ctrl_ma,
    output reg en_ctrl_wb,
    output reg valid_ctrl_wb,
    output reg [15:0] PC_out_f,
    output reg jmp_valid_rf,
    output reg [15:0] jmp_loc_rf,
    output reg [15:0] data_a, // to exec forwarded data
    output reg [15:0] data_b  // to exec forwarded data
);
reg [1:0] count;
reg br_ctrl_ex;
reg br_ctrl_rr;
always@(posedge clk) begin
    if(rst) begin
        count <= 2;
        br_ctrl_ex <= 0;
        br_ctrl_rr <= 0;
    end
   
   else if( mispredict || br_ctrl_ex || br_ctrl_rr) begin
        
        if(count == 0) begin
            br_ctrl_ex <= 0;
            count <= 2;
        end
        else begin
            br_ctrl_ex <= 1;
            count <= count - 1;
            end
        if(count > 1) begin
            br_ctrl_rr <= 1;          
        end
        else 
            br_ctrl_rr <= 0;
    end
    else 
        count <= 2;
end
always@(*) begin  //combinational unit giving PC and does data forwarding
    if(rst) begin
        PC_out_f = 0;
        en_ctrl_f = 0;
        en_ctrl_d = 0;
        valid_ctrl_d = 0;
        en_ctrl_rr = 0;
        valid_ctrl_rr = 0;
        en_ctrl_ex = 0;
        valid_ctrl_ex = 0;
        en_ctrl_ma = 0;
        valid_ctrl_ma = 0;
        en_ctrl_wb = 0;
        valid_ctrl_wb = 0;
        freeze_ctrl = 0;  // for stopping the pc increment
        jmp_valid_rf = 0;
        jmp_loc_rf = 0;

    end
    else begin
        if(!(jvalid || br_valid || br_ctrl_ex || br_ctrl_rr || freeze_ctrl || mult_freeze_d)) begin  // normal operation
            en_ctrl_f = 1; 
            en_ctrl_d = 1;
            valid_ctrl_d = 1;
            en_ctrl_rr = 1;
            valid_ctrl_rr = 1;
            en_ctrl_ex = 1;
            valid_ctrl_ex = 1;
            en_ctrl_ma = 1;
            valid_ctrl_ma = 1;
            en_ctrl_wb = 1;
            valid_ctrl_wb = 1;
            PC_out_f =  PC_ctrl_rf;
            jmp_valid_rf = 0;
        end
        else begin
            if(jvalid) begin
                PC_out_f = jloc; //decode unit should flush the instr now 
                jmp_valid_rf = 1;
                jmp_loc_rf = jloc;
                valid_ctrl_d = 0;
                en_ctrl_f = 1;                      // for jmp procedures
            end
            else if(mult_freeze_d) begin
                en_ctrl_f = 0;
                freeze_ctrl = 1;
                en_ctrl_d = 0;
            end
            else begin
                en_ctrl_f = 1;                      // for jmp procedures
            //if(br_valid && !br_ctrl_ex && !br_ctrl_rr) begin
            if(mispredict && !br_ctrl_ex && !br_ctrl_rr) begin
//                    PC_out_f = br_loc;
//                    jmp_valid_rf = 1;
//                    jmp_loc_rf = br_loc;
                    valid_ctrl_d = 0;
                    valid_ctrl_ex = 0;
                    valid_ctrl_rr = 0;
                end
               else begin
                    valid_ctrl_d = 1;
                    en_ctrl_d = 1;
                    freeze_ctrl = 0;
                    valid_ctrl_rr = !(br_ctrl_rr);
                    valid_ctrl_ex = !(br_ctrl_ex);
                    PC_out_f = PC_ctrl_rf;
                    jmp_valid_rf = 0;
                    jmp_loc_rf = 0;                    
                end 
            end   
        end
       end
        //forwarding logic goes here 
        if ((opcode_ex != 4'd4 && opcode_ex != 4'd6) && (valid_ex || valid_ma)) begin
            if(rc_mem == ra_rr) begin          
                if(rc_ex == ra_rr) 
                    data_a = datac_ex;
                else
                    data_a = datac_mem;
            end
            else begin
                if(rc_ex == ra_rr) 
                    data_a = datac_ex;
                else
                    data_a = data_a_rr;
            end
             
           if(rc_mem == rb_rr) begin          
                if(rc_ex == rb_rr) 
                    data_b = datac_ex;
                else
                    data_b = datac_mem;
            end
            else begin
                if(rc_ex == rb_rr) 
                    data_b = datac_ex;
                else
                    data_b = data_b_rr;
            end
         end
        //immediate load dependency
        else begin
            if((ra_rr == rc_ex || rb_rr == rc_ex) && (valid_ex || valid_ma)) begin 
                en_ctrl_f = 0;
                freeze_ctrl = 1;
                en_ctrl_rr = 0;
                en_ctrl_d = 0;
                valid_ctrl_ex = 0;
 
            end
            else if((ra_rr == rc_mem || rb_rr == rc_mem) && !mult_freeze_d) begin
                freeze_ctrl = 0; //unfreezing
                en_ctrl_rr = 1;
                en_ctrl_d = 1;
                valid_ctrl_ex = 1;
                en_ctrl_f = 1;
                                
                if(ra_rr == rc_mem)
                    data_a = datac_mem;
                else
                    data_b = datac_mem;
            end
            else begin
                data_a = data_a_rr;
                data_b = data_b_rr;
            end
        end  
    end
    
    



endmodule