module processor(
    input clk,
    input rst
);
wire [15:0] instr_out_f;
wire [15:0] PC_out_f;
wire [15:0] PC_out_d;
wire [15:0] PC_out_r;
wire valid_f;
//decode stage  outputs
wire [3:0] opcode_d;
wire [2:0] ra_d, rb_d, rc_d, ccz_d;
wire [5:0] imm6_d;
wire [8:0] imm9_d;
wire [15:0] jloc_d;
wire jvalid_d;
wire regsel_d;
wire valid_d;
wire mult_freeze_d;
//RR stage outputs
wire [2:0] addr_a_rr, addr_b_rr;
wire [3:0] opcode_out_rr;
wire [2:0] ra_rr, rb_rr, rc_rr, ccz_rr;
wire [5:0] imm6_rr;
wire [8:0] imm9_rr;
wire [15:0] PC_out_rr;
wire regsel_rr;
wire freeze_release_rr;
wire valid_rr;
// Reg File outputs
wire [15:0] data_a_rf,data_b_rf;
wire [15:0] PC_rf;
//control unit outputs
wire [15:0] jmp_loc_rf_cu;
wire jmp_valid_rf_cu;
wire freeze_ctrl_cu;
wire en_ctrl_f_cu;
wire en_ctrl_d_cu;
wire valid_ctrl_d_cu;
wire en_ctrl_rr_cu;
wire valid_ctrl_rr_cu;
wire en_ctrl_ex_cu;
wire valid_ctrl_ex_cu;
wire en_ctrl_ma_cu;
wire valid_ctrl_ma_cu;
wire en_ctrl_wb_cu;
wire valid_ctrl_wb_cu;
wire [15:0] PC_out_f_cu;
wire [15:0] data_a_cu, data_b_cu;
//Exec stage outputs
wire mem_r_ex;
wire mem_w_ex;
wire [15:0] ls_addr_ex, store_data_ex,rc_data_ex;
wire [3:0] opcode_out_ex;
wire [2:0] rc_addr_ex;
wire rc_w_valid_ex;
wire br_valid_ex;
wire [15:0] br_loc_ex;
wire valid_out;
//mem access stage outputs
wire [15:0] rc_data_out_ma;
wire [2:0] rc_addr_out_ma;
wire rc_w_valid_out_ma;
wire [3:0] opcode_out_ma;
wire valid_out_ma;
//writeback unit outputs
wire regsel_out_wb;
wire [3:0] rc_addr_out_wb;
wire [15:0] rc_data_out_wb;
wire rf_w_en_out_wb;
wire complete_wb;


wire [2:0] regc_out_rr;
wire [2:0] ccz_out_rr;
wire [5:0] imm6_out_rr;
wire [8:0] imm9_out_rr;


//BP signals
wire mispredict;
wire [15:0] pc_reg;
wire branch_update_en;
wire [15:0] branch_inst_pc;
wire btb_hit_wire;


inst_fetch fetch(
    .clk(clk),
    .rst(rst),
    .en_ctrl(en_ctrl_f_cu),
    .PC_ctrl(pc_reg),
    .PC_out(PC_out_f),
    .instr_out(instr_out_f),
    .valid_out(valid_f),
    .mispredict(mispredict),
    .pc_reg(pc_reg)
);

inst_decode decode(
    .clk(clk),
    .rst(rst),
    .en_ctrl(en_ctrl_d_cu),
    .valid_ctrl(valid_ctrl_d_cu),
    .PC_in(PC_out_f),
    .valid_f(valid_f),
    .instr(instr_out_f),
    .freeze_release(freeze_release),
    .jloc(jloc_d),
    .jvalid(jvalid_d),
    .regsel(regsel_d),
    .opcode(opcode_d),
    .ra(ra_d),
    .rb(rb_d),
    .rc(rc_d),
    .imm6(imm6_d),
    .imm9(imm9_d),
    .ccz(ccz_d),
    .valid_out(valid_d),
    .PC_out(PC_out_d),
    .mult_freeze_cu(mult_freeze_d)
);

regread rr(
    .clk(clk),
    .rst(rst),
    .rega(ra_d),
    .regb(rb_d),
    .regc(rc_d),
    .imm6(imm6_d),
    .imm9(imm9_d),
    .valid_d(valid_d),
    .ccz(ccz_d),
    .en_ctrl(en_ctrl_rr_cu),
    .valid_ctrl(valid_ctrl_rr_cu),
    .opcode_in(opcode_d),
    .regsel(regsel_d),
    .PC_in(PC_out_d),
    
    .addr_a(addr_a_rr),
    .regsel_out(regsel_out_rr),
    .addr_b(addr_b_rr),
    .regc_out(regc_out_rr),
    .ccz_out(ccz_out_rr),
    .imm6_out(imm6_out_rr),
    .imm9_out(imm9_out_rr),
    .valid_out(valid_rr),
    .opcode_out(opcode_out_rr),
    .PC_out(PC_out_rr),
    .freeze_release(freeze_release)
);



reg_file rf(
    .clk(clk),
    .rst(rst),
    .PC_ctrl_in(jmp_loc_rf_cu),
    .jmp_ctrl(jmp_valid_rf_cu),
    .addra(addr_a_rr),
    .addrb(addr_b_rr),
    .freeze_ctrl(freeze_ctrl_cu),
    .addrc(rc_addr_out_wb),
    .rf_data_c(rc_data_out_wb),
    .rf_w(rf_w_en_out_wb),
    .regsel(regsel_out_rr | regsel_out_wb),
    .rf_data_a(data_a_rf),
    .rf_data_b(data_b_rf),
    .PC_ctrl_out(PC_rf),
    
    .mispredict(mispredict),
    .pc_reg(pc_reg),
    .btb_hit_wire(btb_hit_wire)
);


inst_exec exec(
    .clk(clk),
    .rst(rst),
    .pc(PC_out_rr),
    .opcode(opcode_out_rr),
    .data_ra(data_a_cu),
    .data_rb(data_b_cu),
    .writeback_rc(regc_out_rr),
    .ccz(ccz_out_rr),
    .imm_6(imm6_out_rr),
    .imm_9(imm9_out_rr),
    .en_ctrl_ex(en_ctrl_ex_cu),
    .valid_ctrl_ex(valid_ctrl_ex_cu),
    .valid_rr(valid_rr),
    
    .mem_r(mem_r_ex),
    .mem_w(mem_w_ex),
    .ls_mem_addr(ls_addr_ex),
    .store_data(store_data_ex),
    .br_target_addr(br_loc_ex), //BRANCH P
    .br_valid(br_valid_ex),       //BRANCH P
    .writeback_valid(rc_w_valid_ex),
    .writeback_data(rc_data_ex),
    .writeback_addr(rc_addr_ex),
    .opcode_ex(opcode_out_ex),
    .valid_out(valid_out),
    
    .br_update_en(branch_update_en),
    .br_inst_pc(branch_inst_pc)
);



mem_access mem(
    .clk(clk),
    .rst(rst),
    .mem_r(mem_r_ex),
    .mem_w(mem_w_ex),
    .en_ctrl(en_ctrl_ma_cu),
    .valid_ctrl(valid_ctrl_ma_cu),
    .ls_addr(ls_addr_ex),
    .store_data(store_data_ex),
    .rc_addr(rc_addr_ex),
    .rc_data(rc_data_ex),
    .opcode_in(opcode_out_ex),
    .rc_w_valid(rc_w_valid_ex),
    
    .rc_addr_out(rc_addr_out_ma),
    .rc_data_out(rc_data_out_ma),
    .rc_w_valid_out(rc_w_valid_out_ma),
    .opcode_out(opcode_out_ma),
    .valid_out(valid_out_ma)
);

inst_wb wb(
    .clk(clk),
    .rst(rst),
    .en_ctrl(en_ctrl_wb_cu),
    .valid_ctrl(valid_ctrl_wb_cu),
    .rc_addr(rc_addr_out_ma),
    .rc_data(rc_data_out_ma),
    .rf_w_en(rc_w_valid_out_ma),
    .opcode(opcode_out_ma),
    
    .regsel_out(regsel_out_wb),
    .rc_addr_out(rc_addr_out_wb),
    .rc_data_out(rc_data_out_wb),
    .rf_w_en_out(rf_w_en_out_wb),
    .complete(complete_wb)
); 

control_unit cu(
    .clk(clk),
    .rst(rst),
    .PC_ctrl_rf(PC_rf),
    .jvalid(jvalid_d),
    .jloc(jloc_d),
    .br_valid(br_valid_ex),
    .br_loc(br_loc_ex),
    .opcode_rr(opcode_out_rr),
    .opcode_ex(opcode_out_ex),
    .valid_ex(valid_out),
    .valid_ma(valid_out_ma),
    .ra_rr(addr_a_rr),
    .rb_rr(addr_b_rr),
    .data_a_rr(data_a_rf),
    .data_b_rr(data_b_rf),
    .rc_ex(rc_addr_ex),
    .rc_mem(rc_addr_out_ma),
    .datac_ex(rc_data_ex),
    .datac_mem(rc_data_out_ma),
    .mult_freeze_d(mult_freeze_d),
    
    .freeze_ctrl(freeze_ctrl_cu),
    .en_ctrl_f(en_ctrl_f_cu),
    .en_ctrl_d(en_ctrl_d_cu),
    .valid_ctrl_d(valid_ctrl_d_cu),
    .en_ctrl_rr(en_ctrl_rr_cu),
    .valid_ctrl_rr(valid_ctrl_rr_cu),
    .en_ctrl_ex(en_ctrl_ex_cu),
    .valid_ctrl_ex(valid_ctrl_ex_cu),
    .en_ctrl_ma(en_ctrl_ma_cu),
    .valid_ctrl_ma(valid_ctrl_ma_cu),
    .en_ctrl_wb(en_ctrl_wb_cu),
    .valid_ctrl_wb(valid_ctrl_wb_cu),
    .PC_out_f(PC_out_f_cu),
    .jmp_valid_rf(jmp_valid_rf_cu),
    .jmp_loc_rf(jmp_loc_rf_cu),
    .data_a(data_a_cu),
    .data_b(data_b_cu),
    
    .mispredict(mispredict)
 
);

fetch_with_btb_mem bp(
    .clk(clk),
    .reset_n(rst),
    .pc_in(PC_out_f_cu),
    //.pc_next(),
    .br_update_en(branch_update_en),
    .br_pc(branch_inst_pc),
    .br_target(br_loc_ex),
    .br_taken(br_valid_ex),
    .pc_reg(pc_reg),
    .mispredict(mispredict),
    .btb_hit_wire(btb_hit_wire)
);

endmodule
