module regfile
import rv32i_types::*;
import params::*;
(
    input   logic                                  clk,
    input   logic                                  rst,

    // CDB
    input   logic                                  regf_we,
    input   logic   [31:0]                         rd_v,
    input   logic   [$clog2(NUM_PHYS_REG) - 1:0]   pd_s,
    input   logic   [4:0]                          rd_s,

    // reservation station <-> functional unit
    input   logic   [$clog2(NUM_PHYS_REG) - 1:0]   rs1_s_alu, rs2_s_alu,
    output  logic   [31:0]                         rs1_v_alu, rs2_v_alu,
    input   logic   [4:0]                          rs1_arch_alu, rs2_arch_alu,

    input   logic   [$clog2(NUM_PHYS_REG) - 1:0]   rs1_s_mul, rs2_s_mul,
    output  logic   [31:0]                         rs1_v_mul, rs2_v_mul,
    input   logic   [4:0]                          rs1_arch_mul, rs2_arch_mul,

    input   logic   [$clog2(NUM_PHYS_REG) - 1:0]   rs1_s_div, rs2_s_div,
    output  logic   [31:0]                         rs1_v_div, rs2_v_div,
    input   logic   [4:0]                          rs1_arch_div, rs2_arch_div,

    input   logic   [$clog2(NUM_PHYS_REG) - 1:0]   rs1_s_ls, rs2_s_ls,
    output  logic   [31:0]                         rs1_v_ls, rs2_v_ls,
    input   logic   [4:0]                          rs1_arch_ls, rs2_arch_ls,

    input   logic   [$clog2(NUM_PHYS_REG) - 1:0]   rs1_s_control, rs2_s_control,
    output  logic   [31:0]                         rs1_v_control, rs2_v_control,
    input   logic   [4:0]                          rs1_arch_control, rs2_arch_control,
    

    input   logic   [$clog2(ROB_DEPTH) - 1:0]      rob_idx_alu, rob_idx_mul, rob_idx_div, rob_idx_ls, rob_idx_control,

    output logic    [$clog2(ROB_DEPTH) - 1:0]      valid_rob_out_alu,
    output logic    [$clog2(ROB_DEPTH) - 1:0]      valid_rob_out_mul,
    output logic    [$clog2(ROB_DEPTH) - 1:0]      valid_rob_out_div,
    output logic    [$clog2(ROB_DEPTH) - 1:0]      valid_rob_out_ls,
    output logic    [$clog2(ROB_DEPTH) - 1:0]      valid_rob_out_control,

    input   logic   [31:0]                         alu_imm_in, mul_imm_in, div_imm_in, ls_imm_in, control_imm_in,

    input   imm_reg_mux_t                          ps2_type_alu,
    input   imm_reg_mux_t                          ps2_type_mul,
    input   imm_reg_mux_t                          ps2_type_div,
    input   imm_reg_mux_t                          ps2_type_ls,
    input   imm_reg_mux_t                          ps2_type_control,
    
    input   logic                                  valid_read_alu,
    input   logic                                  valid_read_mul,
    input   logic                                  valid_read_div,
    input   logic                                  valid_read_ls,
    input   logic                                  valid_read_control
);

    logic   [31:0]  data [NUM_PHYS_REG];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < NUM_PHYS_REG; i++) begin
                data[i] <= '0;
            end
        end else if (regf_we && (rd_s != '0)) begin
            data[pd_s] <= rd_v;
        end else if (regf_we && (rd_s == '0)) begin
            data[pd_s] <= '0;
        end
    end

    always_comb begin
        valid_rob_out_alu = 'x;
        valid_rob_out_div = 'x;
        valid_rob_out_mul = 'x;
        valid_rob_out_ls = 'x;
        valid_rob_out_control = 'x;

        if(valid_read_alu) begin
            valid_rob_out_alu = rob_idx_alu;
        end
        if(valid_read_div) begin
            valid_rob_out_div = rob_idx_div;
        end
        if(valid_read_mul) begin
            valid_rob_out_mul = rob_idx_mul;
        end
        if(valid_read_ls) begin
            valid_rob_out_ls = rob_idx_ls;
        end
        if(valid_read_control) begin
            valid_rob_out_control = rob_idx_control;
        end
    end

    //ALU
    always_comb begin
        rs1_v_alu = '0;
        rs2_v_alu = '0;
        if (valid_read_alu) begin
            if(regf_we && (pd_s == rs1_s_alu) && (rd_s!='0) && (rs1_arch_alu != '0)) begin
                rs1_v_alu = rd_v;
            end 
            else if (rs1_arch_alu == '0) begin
                rs1_v_alu = '0;
            end
            else begin
                rs1_v_alu = data[rs1_s_alu];
            end
            if((ps2_type_alu == lui_entry) || (ps2_type_alu == imm_entry)) begin
                rs2_v_alu = alu_imm_in;
            end else begin
                if(regf_we && (pd_s == rs2_s_alu) && (rd_s!='0) && (rs2_arch_alu != '0)) begin
                    rs2_v_alu = rd_v;
                end
                else if (rs2_arch_alu == '0) begin
                    rs2_v_alu = '0;
                end
                else begin
                    rs2_v_alu = data[rs2_s_alu];
                end
            end
        end
    end

    //MUL
    always_comb begin
        rs1_v_mul = '0;
        rs2_v_mul = '0;
        if (valid_read_mul) begin
            if(regf_we && (pd_s == rs1_s_mul) && (rd_s!='0) && (rs1_arch_mul != '0)) begin
                rs1_v_mul = rd_v;
            end
            else if (rs1_arch_mul == '0) begin
                rs1_v_mul = '0;
            end
            else begin
                rs1_v_mul = data[rs1_s_mul];
            end
            if(ps2_type_mul == imm_entry) begin
                rs2_v_mul = mul_imm_in;
            end else begin
                if(regf_we && (pd_s == rs2_s_mul) && (rd_s!='0) && (rs2_arch_mul != '0)) begin
                    rs2_v_mul = rd_v;
                end
                else if (rs2_arch_mul == '0) begin
                    rs2_v_mul = '0;
                end
                else begin
                    rs2_v_mul = data[rs2_s_mul];
                end
            end
        end
    end

    //DIV
    always_comb begin
        rs1_v_div = '0;
        rs2_v_div = '0;
        if (valid_read_div) begin
            if(regf_we && (pd_s == rs1_s_div) && (rd_s!='0) && (rs1_arch_div != '0)) begin
                rs1_v_div = rd_v;
            end
            else if (rs1_arch_div == '0) begin
                rs1_v_div = '0;
            end
            else begin
                rs1_v_div = data[rs1_s_div];
            end
            if(ps2_type_div == imm_entry) begin
                rs2_v_div = div_imm_in;
            end else begin
                if(regf_we && (pd_s == rs2_s_div) && (rd_s!='0) && (rs2_arch_div != '0)) begin
                    rs2_v_div = rd_v;
                end
                else if (rs2_arch_div == '0) begin
                    rs2_v_div = '0;
                end
                else begin
                    rs2_v_div = data[rs2_s_div];
                end
            end
        end
    end


    //LOADS AND STORES
    always_comb begin
        rs1_v_ls = '0;
        rs2_v_ls = '0;
        if (valid_read_ls) begin
            if(regf_we && (pd_s == rs1_s_ls) && (rd_s!='0) && (rs1_arch_ls != '0)) begin
                rs1_v_ls = rd_v;
            end
            else if (rs1_arch_ls == '0) begin
                rs1_v_ls = '0;
            end
            else begin
                rs1_v_ls = data[rs1_s_ls];
            end

            //LOAD CASE
            if(ps2_type_ls == imm_entry) begin
                rs2_v_ls = ls_imm_in;
            end 
            //STORE CASE
            else begin
                if(regf_we && (pd_s == rs2_s_ls) && (rd_s!='0) && (rs2_arch_ls != '0)) begin
                    rs2_v_ls = rd_v;
                end
                else if (rs2_arch_ls == '0) begin
                    rs2_v_ls = '0;
                end
                else begin
                    rs2_v_ls = data[rs2_s_ls];
                end
            end
        end
    end

    //CONTROL
    always_comb begin
        rs1_v_control = '0;
        rs2_v_control = '0;
        if (valid_read_control) begin
            if(regf_we && (pd_s == rs1_s_control) && (rd_s!='0) && (rs1_arch_control != '0)) begin
                rs1_v_control = rd_v;
            end 
            else if (rs1_arch_control == '0) begin
                rs1_v_control = '0;
            end
            else begin
                rs1_v_control = data[rs1_s_control];
            end
            if((ps2_type_control == auipc_entry) || (ps2_type_control == jal_entry) || (ps2_type_control == jalr_entry)) begin
                rs2_v_control = control_imm_in;
            end else begin
                if(regf_we && (pd_s == rs2_s_control) && (rd_s!='0) && (rs2_arch_control != '0)) begin
                    rs2_v_control = rd_v;
                end
                else if (rs2_arch_control == '0) begin
                    rs2_v_control = '0;
                end
                else begin
                    rs2_v_control = data[rs2_s_control];
                end
            end
        end
    end


endmodule : regfile
