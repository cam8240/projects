module res_station_adapter
import rv32i_types::*;
import params::*;
(
    input   logic                               clk,
    input   logic                               rst,

    input res_station_entry_t                   res_station_in,
    output logic                                res_station_full,
    
    output  cdb_out_t                           cdb_out,

    //LOAD AND STORES
    output  logic [31:0]                        mem_addr_ls,
    output  logic [3:0]                         read_mask_ls,
    output  logic [3:0]                         write_mask_ls,
    input   logic [31:0]                        load_read_data,
    output  logic [31:0]                        store_write_data,
    input   logic                               data_mem_resp,
    input   logic [$clog2(ROB_DEPTH) - 1:0]     rob_at_head,

    output  logic                               ls_queue_empty,
    output  logic                               ls_queue_full,
    output  logic                               load_queue_empty,
    output  logic                               load_queue_full,
    output  logic                               control_queue_full,

    output cdb_out_t                            store_out,
    output cdb_out_t                            control_out,

    output logic                                ls_enqueue,

    input  logic                                rob_commit, 
    input  logic  [$clog2(ROB_DEPTH) - 1:0]     rob_commit_idx,
    input  logic                                rob_flush,

    input  cache_state_t                        cache_state,
    output logic   [31:0]                       pc_control_out,

    output logic                                branch_write,
    output logic  [1:0]                         updated_val,

    output logic  [BITS_ROB_DEPTH:0]            rob_idx_branch,
    input  logic  [1:0]                         prediction_val_control,

    output logic  [PATTERN_HISTORY_LEN - 1:0]   pht_write_idx,
    input  logic  [PATTERN_HISTORY_LEN - 1:0]   pht_write_idx_rob,

    input  logic [LOG_ROB_DEPTH:0]              head_counter_ls

);


    funct_unit_out_t    funct_unit_out_alu;
    funct_unit_out_t    funct_unit_out_mul;
    funct_unit_out_t    funct_unit_out_div;
    funct_unit_out_t    funct_unit_out_ls;
    funct_unit_out_t    funct_unit_out_control;

    logic mul_flag, div_flag, alu_flag, ls_flag, control_flag;

    // CDB
    logic                                  regf_we;
    logic   [31:0]                         rd_v;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]   pd_s;
    logic   [4:0]                          rd_s;

    // reservation station <-> functional unit
    logic   [2:0]                          funct3_alu;
    logic   [6:0]                          funct7_alu;
    imm_reg_mux_t                          imm_reg_mux_alu;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]   pd_alu;
    logic   [4:0]                          rd_alu;
    logic                                  valid_alu;

    logic   [2:0]                          funct3_mul;
    logic   [6:0]                          funct7_mul;
    imm_reg_mux_t                          imm_reg_mux_mul;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]   pd_mul;
    logic   [4:0]                          rd_mul;
    logic                                  valid_mul;

    logic   [2:0]                          funct3_div;
    logic   [6:0]                          funct7_div;
    imm_reg_mux_t                          imm_reg_mux_div;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]   pd_div;
    logic   [4:0]                          rd_div;
    logic                                  valid_div;

    logic   [$clog2(NUM_PHYS_REG) - 1:0]   rs1_s_alu, rs2_s_alu;
    logic   [31:0]                         rs1_v_alu, rs2_v_alu;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]   rs1_s_mul, rs2_s_mul;
    logic   [31:0]                         rs1_v_mul, rs2_v_mul;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]   rs1_s_div, rs2_s_div;
    logic   [31:0]                         rs1_v_div, rs2_v_div;

    logic   [4:0]   rs1_arch_alu, rs2_arch_alu;
    logic   [4:0]   rs1_arch_mul, rs2_arch_mul;
    logic   [4:0]   rs1_arch_div, rs2_arch_div;
    logic   [4:0]   rs1_arch_ls, rs2_arch_ls;
    logic   [4:0]   rs1_arch_control, rs2_arch_control;

    logic   [31:0]  alu_imm_in, mul_imm_in, div_imm_in;

    imm_reg_mux_t   ps2_type_alu;
    imm_reg_mux_t   ps2_type_mul;
    imm_reg_mux_t   ps2_type_div;

    logic           valid_read_alu;
    logic           valid_read_mul;
    logic           valid_read_div;

    logic           alu_funct_ready;
    logic           div_funct_ready;
    logic           mult_funct_ready;

    logic           alu_ready, div_rem_ready, mult_ready;

    logic           res_alu_full, res_mul_full, res_div_full;

    logic   [$clog2(ROB_DEPTH) - 1:0]       rob_out_alu, rob_out_mul, rob_out_div, rob_out_ls, rob_out_control;

    logic   [$clog2(ROB_DEPTH) - 1:0]       rob_out_alu_reg_file, rob_out_mul_reg_file, rob_out_div_reg_file, rob_out_ls_reg_file, rob_out_control_reg_file;

    logic  [31:0]       alu_funct_out, mult_funct_out, div_funct_out, rem_funct_out;

    logic   [$clog2(NUM_PHYS_REG) - 1:0]    pd_alu_out;
    logic   [4:0]                           rd_alu_out;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]    pd_mul_out;
    logic   [4:0]                           rd_mul_out;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]    pd_div_out;
    logic   [4:0]                           rd_div_out;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]    pd_ls_out;
    logic   [4:0]                           rd_ls_out;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]    pd_control_out;
    logic   [4:0]                           rd_control_out;



    logic   cdb_ready_ls;
    logic   cdb_ready_control;


    register_t  alu_rvfi_out, mul_rvfi_out, div_rvfi_out, ls_rvfi_out, control_rvfi_out;

    logic   [$clog2(ROB_DEPTH) - 1:0]   rob_idx_alu, rob_idx_mul, rob_idx_div, rob_idx_ls, rob_idx_control;

    cdb_out_t cdb_out_internal;


    logic                              res_store_full;
    logic [$clog2(NUM_PHYS_REG) - 1:0] rs1_s_ls, rs2_s_ls;
    logic [31:0]                       rs1_v_ls, rs2_v_ls;
    logic [31:0]                       ls_imm_in;
    logic [2:0]                        funct3_ls;
    logic                              valid_read_ls;
    imm_reg_mux_t                      imm_reg_mux_ls;
    imm_reg_mux_t                      ps2_type_ls;
    logic                              valid_ls;
    logic                              ls_funct_ready;

    
    
    logic                                  res_control_full;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]   rs1_s_control, rs2_s_control;
    logic   [31:0]                         rs1_v_control, rs2_v_control;
    logic   [31:0]                         control_imm_in;
    logic   [2:0]                          funct3_control;
    logic                                  valid_read_control;
    imm_reg_mux_t                          imm_reg_mux_control;
    imm_reg_mux_t                          ps2_type_control;
    logic   [$clog2(NUM_PHYS_REG) - 1:0]   pd_control;
    logic   [4:0]                          rd_control;
    logic                                  valid_control;
    logic                                  control_funct_ready;


    assign res_station_full = res_alu_full || res_mul_full || res_div_full || res_store_full || res_control_full;

    assign ls_enqueue = valid_ls;

    logic [31:0] pc_control;
    assign pc_control_out = pc_control;

    res_stations res_station_alu(
        .clk(clk),
        .rst(rst),
        // reservation station <-> adapter
        .res_station_in(res_station_in),  // in
        .res_station_full(res_alu_full), // out
        .funct_unit_key(alu), // in
        .funct_unit_ready(alu_funct_ready),    //in

        // reservation station <-> physical register/functional unit
        .ps1_out(rs1_s_alu), // out
        .ps2_out(rs2_s_alu), // out
        .rs1_out(rs1_arch_alu), // out
        .rs2_out(rs2_arch_alu), // out
        .imm_out(alu_imm_in), // out
        .ps2_type(ps2_type_alu), // out
        .valid_read_flag(valid_read_alu), // out

        .funct3_out(funct3_alu), // out
        .funct7_out(funct7_alu), // out
        .imm_reg_mux_out(imm_reg_mux_alu), // out
        .pd_out(pd_alu),// out
        .rd_out(rd_alu), // out
        .valid_out(valid_alu), // out
        .rob_idx_out(rob_idx_alu), // out
        .pc_out(), // out
        .rob_flush(rob_flush), // in

        //reservation station <-> CDB
        .pd_cdb(cdb_out_internal.pd), // in
        .ready_commit_cdb(cdb_out_internal.ready_commit) // in
    );

    res_stations res_station_mul(
        .clk(clk),
        .rst(rst),
        // reservation station <-> adapter
        .res_station_in(res_station_in), // in
        .res_station_full(res_mul_full), // out
        .funct_unit_key(mult), // in
        .funct_unit_ready(mult_funct_ready),    //in

        // reservation station <-> physical register/functional unit
        .ps1_out(rs1_s_mul), // out
        .ps2_out(rs2_s_mul), // out
        .rs1_out(rs1_arch_mul), // out
        .rs2_out(rs2_arch_mul), // out
        .imm_out(mul_imm_in), // out
        .ps2_type(ps2_type_mul), // out
        .valid_read_flag(valid_read_mul), // out
        .rob_idx_out(rob_idx_mul), // out

        .funct3_out(funct3_mul), // out
        .funct7_out(funct7_mul), // out
        .imm_reg_mux_out(imm_reg_mux_mul), // out
        .pd_out(pd_mul), // out
        .rd_out(rd_mul), // out
        .valid_out(valid_mul), // out
        .pc_out(), // out
        .rob_flush(rob_flush), // in

        //reservation station <-> CDB
        .pd_cdb(cdb_out_internal.pd), // in
        .ready_commit_cdb(cdb_out_internal.ready_commit) // in
    );

    res_stations res_station_div_rem(
        .clk(clk),
        .rst(rst),
        // reservation station <-> adapter
        .res_station_in(res_station_in), // in
        .res_station_full(res_div_full), // out
        .funct_unit_key(divide_rem), // in
        .funct_unit_ready(div_funct_ready),

        // reservation station <-> physical register/functional unit
        .ps1_out(rs1_s_div), // out
        .ps2_out(rs2_s_div), // out
        .rs1_out(rs1_arch_div), // out
        .rs2_out(rs2_arch_div), // out
        .imm_out(div_imm_in), // out
        .ps2_type(ps2_type_div), // out
        .valid_read_flag(valid_read_div), // out
        .rob_idx_out(rob_idx_div), // out
        .pc_out(), // out
        .rob_flush(rob_flush), // in

        .funct3_out(funct3_div), // out
        .funct7_out(funct7_div),
        .imm_reg_mux_out(imm_reg_mux_div), // out
        .pd_out(pd_div), // out
        .rd_out(rd_div), // out
        .valid_out(valid_div), // out

        //reservation station <-> CDB
        .pd_cdb(cdb_out_internal.pd), // in
        .ready_commit_cdb(cdb_out_internal.ready_commit) // in
    );

    regfile phys_regfile_inst (
        .clk(clk),
        .rst(rst),

        // CDB
        .regf_we(cdb_out_internal.ready_commit),
        .rd_v(cdb_out_internal.data),
        .pd_s(cdb_out_internal.pd),
        .rd_s(cdb_out_internal.rd),

        // reservation station <-> functional unit
        .rs1_s_alu(rs1_s_alu), 
        .rs2_s_alu(rs2_s_alu),
        .rs1_v_alu(rs1_v_alu), 
        .rs2_v_alu(rs2_v_alu),
        .rs1_arch_alu(rs1_arch_alu),
        .rs2_arch_alu(rs2_arch_alu),
        .rob_idx_alu(rob_idx_alu),  //in

        .rs1_s_mul(rs1_s_mul), 
        .rs2_s_mul(rs2_s_mul),
        .rs1_v_mul(rs1_v_mul), 
        .rs2_v_mul(rs2_v_mul),
        .rs1_arch_mul(rs1_arch_mul),
        .rs2_arch_mul(rs2_arch_mul),
        .rob_idx_mul(rob_idx_mul),  //in

        .rs1_s_div(rs1_s_div), 
        .rs2_s_div(rs2_s_div),
        .rs1_v_div(rs1_v_div), 
        .rs2_v_div(rs2_v_div),
        .rs1_arch_div(rs1_arch_div),
        .rs2_arch_div(rs2_arch_div),
        .rob_idx_div(rob_idx_div),  //in


        .rs1_s_ls(rs1_s_ls), 
        .rs2_s_ls(rs2_s_ls),
        .rs1_v_ls(rs1_v_ls), 
        .rs2_v_ls(rs2_v_ls),
        .rs1_arch_ls(rs1_arch_ls),
        .rs2_arch_ls(rs2_arch_ls),
        .rob_idx_ls(rob_idx_ls),  //in

        .rs1_s_control(rs1_s_control), 
        .rs2_s_control(rs2_s_control),
        .rs1_v_control(rs1_v_control), 
        .rs2_v_control(rs2_v_control),
        .rs1_arch_control(rs1_arch_control),
        .rs2_arch_control(rs2_arch_control),
        .rob_idx_control(rob_idx_control),  //in

        .alu_imm_in(alu_imm_in), 
        .mul_imm_in(mul_imm_in), 
        .div_imm_in(div_imm_in),
        .ls_imm_in(ls_imm_in),
        .control_imm_in(control_imm_in),

        .ps2_type_alu(ps2_type_alu),
        .ps2_type_mul(ps2_type_mul),
        .ps2_type_div(ps2_type_div),
        .ps2_type_ls(ps2_type_ls),
        .ps2_type_control(ps2_type_control),

        .valid_read_alu(valid_read_alu),
        .valid_read_mul(valid_read_mul),
        .valid_read_div(valid_read_div),
        .valid_read_ls(valid_read_ls),
        .valid_read_control(valid_read_control),


        .valid_rob_out_alu(rob_out_alu_reg_file),
        .valid_rob_out_mul(rob_out_mul_reg_file),
        .valid_rob_out_div(rob_out_div_reg_file),
        .valid_rob_out_ls(rob_out_ls_reg_file),
        .valid_rob_out_control(rob_out_control_reg_file)
    );

    //FUNCTIONAL UNITS
    funct_unit_alu funct_unit_alu_inst(
    .clk(clk),
    .rst(rst),
    .funct3_alu(funct3_alu),
    .funct7_alu(funct7_alu),
    .imm_reg_mux(imm_reg_mux_alu),
    .pd_alu_in(pd_alu),
    .rd_alu_in(rd_alu),
    .valid_alu(valid_alu),
    
    .rs1_v_alu(rs1_v_alu),
    .rs2_v_alu(rs2_v_alu),

    .alu_flag(alu_flag),

    .alu_funct_out(alu_funct_out),
    .pd_alu_out(pd_alu_out),
    .rd_alu_out(rd_alu_out),
    .ready_commit(alu_ready),

    .funct_unit_ready(alu_funct_ready),


    .rob_alu_in(rob_out_alu_reg_file),
    .rob_alu_out(rob_out_alu),

    .alu_reg_out(alu_rvfi_out),
    .rob_flush(rob_flush) // in
    );

    funct_unit_mult funct_unit_mult_inst(
    .inst_clk(clk),
    .inst_rst_n(rst),
    .inst_start(valid_mul),
    .inst_a(rs1_v_mul),
    .inst_b(rs2_v_mul),
    .pd_mul_in(pd_mul),
    .rd_mul_in(rd_mul),
    .complete_inst(mult_ready),
    .product_inst(mult_funct_out),
    .pd_mul_out(pd_mul_out),
    .rd_mul_out(rd_mul_out),
    .funct_unit_ready(mult_funct_ready),
    .funct3_mul(funct3_mul),

    .rob_in_mul(rob_out_mul_reg_file),
    .rob_out_mul(rob_out_mul),
    .mul_flag(mul_flag),

    .mul_reg_out(mul_rvfi_out),
    .rob_flush(rob_flush) // in
    );

    funct_unit_div_rem funct_unit_div_rem_inst(
    .inst_clk(clk),
    .inst_rst_n(rst),
    .inst_start(valid_div),
    .inst_a(rs1_v_div),
    .inst_b(rs2_v_div),
    .pd_div_in(pd_div),
    .rd_div_in(rd_div),
    .complete_inst(div_rem_ready),
    .pd_div_out(pd_div_out),
    .rd_div_out(rd_div_out),
    .div_out(div_funct_out),
    .funct_unit_ready(div_funct_ready),
    .funct3_div(funct3_div),

    .rob_in_div(rob_out_div_reg_file),
    .rob_out_div(rob_out_div),
    .div_flag(div_flag),

    .div_reg_out(div_rvfi_out),
    .rob_flush(rob_flush) // in

    );

    //ASSIGN VALUES TO SEND TO CDB
    assign  funct_unit_out_alu.pd = pd_alu_out;
    assign  funct_unit_out_alu.rd = rd_alu_out;
    assign  funct_unit_out_alu.ready_commit = alu_ready;
    assign  funct_unit_out_alu.funct_unit_out = alu_funct_out;
    assign  funct_unit_out_alu.rob_idx = rob_out_alu;
    assign  funct_unit_out_alu.rvfi_data = alu_rvfi_out;


    assign  funct_unit_out_mul.pd = pd_mul_out;
    assign  funct_unit_out_mul.rd = rd_mul_out;
    assign  funct_unit_out_mul.ready_commit = mult_ready;
    assign  funct_unit_out_mul.funct_unit_out = mult_funct_out;
    assign  funct_unit_out_mul.rob_idx = rob_out_mul;
    assign  funct_unit_out_mul.rvfi_data = mul_rvfi_out;
    
    //ADD REMAINDER LOGIC
    assign  funct_unit_out_div.pd = pd_div_out;
    assign  funct_unit_out_div.rd = rd_div_out;
    assign  funct_unit_out_div.ready_commit = div_rem_ready;
    assign  funct_unit_out_div.funct_unit_out = div_funct_out;
    assign  funct_unit_out_div.rob_idx = rob_out_div;
    assign  funct_unit_out_div.rvfi_data = div_rvfi_out;


    funct_cdb_adapter cdb_inst
    (
    .funct_unit_out_alu(funct_unit_out_alu),
    .funct_unit_out_mul(funct_unit_out_mul),  
    .funct_unit_out_div(funct_unit_out_div),
    .funct_unit_out_ls(funct_unit_out_ls),
    .funct_unit_out_control(funct_unit_out_control),

    .cdb_out_entry(cdb_out_internal),

    .cdb_ready_alu(),
    .cdb_ready_mul(),
    .cdb_ready_div(),
    .cdb_ready_ls(cdb_ready_ls),
    .cdb_ready_control(cdb_ready_control),

    .mul_flag(mul_flag),
    .div_flag(div_flag),
    .alu_flag(alu_flag),
    .ls_flag(ls_flag),
    .control_flag(control_flag)
    );
    
    assign cdb_out = cdb_out_internal;



// -------------- LOAD/STORE ----------------- //

    res_stations res_station_ls(
        .clk(clk),
        .rst(rst),
        // reservation station <-> adapter
        .res_station_in(res_station_in),        // in
        .res_station_full(res_store_full),      // out
        .funct_unit_key(load_store),            // in
        .funct_unit_ready(ls_funct_ready),      // in

        // reservation station <-> physical register/functional unit

        .ps1_out(rs1_s_ls),                              // out
        .ps2_out(rs2_s_ls),                              // out
        .rs1_out(rs1_arch_ls),                           // out
        .rs2_out(rs2_arch_ls),                           // out
        .imm_out(ls_imm_in),                             // out
        .ps2_type(ps2_type_ls),                          // out
        .valid_read_flag(valid_read_ls),                 // out

        .funct3_out(funct3_ls),                          // out
        .funct7_out(),                                   // out
        .imm_reg_mux_out(imm_reg_mux_ls),                // out
        .pd_out(),                                       // out
        .rd_out(),                                       // out
        .valid_out(valid_ls),                            // out
        .rob_idx_out(rob_idx_ls),                        // out
        .pc_out(),  // out
        .rob_flush(rob_flush), // in

        //reservation station <-> CDB
        .pd_cdb(cdb_out_internal.pd),                    // in
        .ready_commit_cdb(cdb_out_internal.ready_commit) // in
    );

    funct_unit_ls funct_unit_ls_inst(
    .clk(clk),
    .rst(rst),

    .funct3_ls(funct3_ls),              // in
    .imm_reg_mux(imm_reg_mux_ls),       // in                 
    .valid_ls(valid_ls),                // in
    .rob_at_head(rob_at_head),          // in
    
    //funct_unit_ls <-> regfile
    .rs1_v_ls(rs1_v_ls),                // in
    .rs2_v_ls(rs2_v_ls),                // in
    .store_imm_val(ls_imm_in),

    .ls_flag(ls_flag),                  //in

    .funct_unit_ready(ls_funct_ready),  // out

    .rob_ls_in(rob_out_ls_reg_file),    // in

    .res_station_in(res_station_in),

    .ls_queue_empty_out(ls_queue_empty),
    .ls_queue_full_out(ls_queue_full),
    .load_queue_empty_out(load_queue_empty),
    .load_queue_full_out(load_queue_full),

    .funct_unit_out_load(funct_unit_out_ls),
    .store_out(store_out),   
    .rob_flush(rob_flush), // in   


    //load/store execution
    .mem_addr_ls(mem_addr_ls),              //out
    .read_mask_ls(read_mask_ls),            //out
    .write_mask_ls(write_mask_ls),          //out
    .load_read_data(load_read_data),        //in
    .store_write_data(store_write_data),    //out
    .data_mem_resp(data_mem_resp),           //in

    .cache_state(cache_state),

    .head_counter_ls(head_counter_ls)       //in
    );

// -------------- END LOAD/STORE ----------------- //


// -------------- CONTROL INSTRUCTIONS ----------------- //

    res_stations res_station_control(
        .clk(clk),
        .rst(rst),
        // reservation station <-> adapter
        .res_station_in(res_station_in),        // in
        .res_station_full(res_control_full),      // out
        .funct_unit_key(control),            // in
        .funct_unit_ready(control_funct_ready),      // in

        // reservation station <-> physical register/functional unit
        .ps1_out(rs1_s_control),                              // out
        .ps2_out(rs2_s_control),                              // out
        .rs1_out(rs1_arch_control),                           // out
        .rs2_out(rs2_arch_control),                           // out
        .imm_out(control_imm_in),                             // out
        .ps2_type(ps2_type_control),                          // out
        .valid_read_flag(valid_read_control),                 // out

        .funct3_out(funct3_control),                          // out
        .funct7_out(),                                        // out
        .imm_reg_mux_out(imm_reg_mux_control),                // out
        .pd_out(pd_control),                                  // out
        .rd_out(rd_control),                                  // out
        .valid_out(valid_control),                            // out
        .rob_idx_out(rob_idx_control),                        // out
        .pc_out(pc_control),                                  // out
        .rob_flush(rob_flush), // in

        //reservation station <-> CDB
        .pd_cdb(cdb_out_internal.pd),                    // in
        .ready_commit_cdb(cdb_out_internal.ready_commit) // in
    );


    funct_unit_control funct_unit_control_inst(
        .clk(clk),
        .rst(rst),

        .funct3_control(funct3_control),              // in
        .imm_reg_mux(imm_reg_mux_control),       // in                 
        .valid_control(valid_control),                // in
        
        //funct_unit_control <-> regfile
        .rs1_v_control(rs1_v_control),                // in
        .rs2_v_control(rs2_v_control),                // in
        .control_imm_val(control_imm_in),

        .control_flag(control_flag),                  //in

        .funct_unit_ready(control_funct_ready),  // out

        .rob_control_in(rob_out_control_reg_file),    // in

        .res_station_in(res_station_in),
        .rob_flush(rob_flush), // in   

        .control_queue_empty_out(),
        .control_queue_full_out(control_queue_full),

        .funct_unit_out_control(funct_unit_out_control),
        .control_out(control_out),    
        .pc_in(pc_control),
        .rob_commit(rob_commit),
        .rob_commit_idx(rob_commit_idx),

        .branch_write(branch_write),
        .updated_val(updated_val),
        
        .rob_idx_branch(rob_idx_branch),
        .prediction_val_control(prediction_val_control),

        .pht_write_idx(pht_write_idx),
        .pht_write_idx_rob(pht_write_idx_rob)
    );


endmodule : res_station_adapter
