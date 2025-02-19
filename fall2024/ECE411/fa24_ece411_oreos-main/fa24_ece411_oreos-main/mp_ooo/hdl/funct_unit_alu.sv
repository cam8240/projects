module funct_unit_alu 
import rv32i_types::*;
import params::*;
(
    input   logic                       clk,
    input   logic                       rst,
    //Regfile <-> funct_unit_alu
    input   logic   [2:0]               funct3_alu,
    input   logic   [6:0]               funct7_alu,
    input   imm_reg_mux_t               imm_reg_mux, 
    input   logic   [BITS_PHYS_REG:0]   pd_alu_in,
    input   logic   [4:0]               rd_alu_in,
    input   logic                       valid_alu,
    
    input  logic   [31:0]               rs1_v_alu, rs2_v_alu,

    input  logic                        alu_flag,

    output   logic   [31:0]             alu_funct_out,
    output   logic   [BITS_PHYS_REG:0]  pd_alu_out,
    output   logic   [4:0]              rd_alu_out,
    
    output   logic                      ready_commit,
    output   logic                      funct_unit_ready,

    input logic      [BITS_ROB_DEPTH:0] rob_alu_in,
    output logic     [BITS_ROB_DEPTH:0] rob_alu_out,

    output   register_t                 alu_reg_out,
    input    logic                      rob_flush
);

    logic signed   [31:0] as;
    logic signed   [31:0] bs;
    logic unsigned [31:0] au;
    logic unsigned [31:0] bu; 

    logic          [31:0] aluout;


    logic           br_en;
    logic   [2:0]   cmpop;
    logic   [2:0]   aluop;

    funct_unit_out_t    alu_funct_out_data, alu_funct_out_data_next;

    logic           ready_commit_flag;

    logic   [31:0]  alu_rs1_reg, alu_rs1_reg_next;
    logic   [31:0]  alu_rs2_reg, alu_rs2_reg_next;


    always_comb begin
        au = rs1_v_alu;
        bu = rs2_v_alu;
        as = signed'(rs1_v_alu);
        bs = signed'(rs2_v_alu);
        unique case (imm_reg_mux)
            imm_entry: begin
            
                unique case (funct3_alu)     
                    arith_f3_slt: begin
                            cmpop = branch_f3_blt;
                            aluop = '0;
                    end
                    
                    arith_f3_sltu: begin
                            cmpop = branch_f3_bltu;
                            aluop = '0;
                    end

                    arith_f3_sr: begin
                        if (funct7_alu[5]) begin
                            aluop = alu_op_sra;
                        end else begin
                            aluop = alu_op_srl;
                        end
                        cmpop = '0;
                    end
                    default: begin
                        aluop = funct3_alu;
                        cmpop = '0;
                    end
                endcase
            end
            reg_entry: begin

                unique case (funct3_alu)
                    arith_f3_slt: begin
                        cmpop = branch_f3_blt;
                        aluop = '0;
                    end
                    
                    arith_f3_sltu: begin
                        cmpop = branch_f3_bltu;
                        aluop = '0;
                    end

                    arith_f3_sr: begin
                        if (funct7_alu[5]) begin
                            aluop = alu_op_sra;
                        end else begin
                            aluop = alu_op_srl;
                        end
                        cmpop = '0;
                    end
                    arith_f3_add: begin
                        if (funct7_alu[5]) begin
                            aluop = alu_op_sub;
                        end else begin
                            aluop = alu_op_add;
                        end
                        cmpop = '0;
                    end
                    default: begin
                        aluop = funct3_alu;
                        cmpop = '0;
                    end
                endcase
            end
            lui_entry: begin
                aluop = '0;
                cmpop = '0;
                au = '0;
            end
            default: begin
                aluop = '0;
                cmpop = '0;
            end
        endcase
    end


    always_comb begin
        unique case (aluop)
                alu_op_add: aluout = au +   bu;
                alu_op_sll: aluout = au <<  bu[4:0];
                alu_op_sra: aluout = unsigned'(as >>> bu[4:0]);
                alu_op_sub: aluout = au -   bu;
                alu_op_xor: aluout = au ^   bu;
                alu_op_srl: aluout = au >>  bu[4:0];
                alu_op_or : aluout = au |   bu;
                alu_op_and: aluout = au &   bu;
                default   : aluout = 'x;
        endcase
    end

        
    always_comb begin
        unique case (cmpop)
                    branch_f3_blt : br_en = (as <  bs);
                    branch_f3_bltu: br_en = (au <  bu);
                    default       : br_en = 1'bx;
        endcase
    end

    always_comb begin
        alu_funct_out_data_next.funct_unit_out = aluout;
        if (imm_reg_mux != lui_entry) begin
        unique case (funct3_alu)     
            arith_f3_slt: begin
                alu_funct_out_data_next.funct_unit_out = {31'd0, br_en};
            end
            arith_f3_sltu: begin
                alu_funct_out_data_next.funct_unit_out = {31'd0, br_en};
            end
            default: begin
                alu_funct_out_data_next.funct_unit_out = aluout;
            end
        endcase
        end
    end

    always_comb begin
        alu_funct_out_data_next.ready_commit = '0;
        alu_funct_out_data_next.rob_idx = '0;
        alu_funct_out_data_next.rd = rd_alu_in;
        alu_funct_out_data_next.pd = pd_alu_in;
        alu_funct_out_data_next.rvfi_data = '0;

        alu_rs1_reg_next = rs1_v_alu;
        alu_rs2_reg_next = rs2_v_alu;

    end

    //assign all output values
    always_ff @(posedge clk) begin
        if(rst || rob_flush) begin
            alu_funct_out_data <= '0;
            alu_rs1_reg <= '0;
            alu_rs2_reg <= '0;
            rob_alu_out <= '0;
        end
        else if(valid_alu) begin
            alu_funct_out_data <= alu_funct_out_data_next;
            alu_rs1_reg <= alu_rs1_reg_next;
            alu_rs2_reg <= alu_rs2_reg_next;
            rob_alu_out <= rob_alu_in;
        end
        else begin
            alu_funct_out_data <= alu_funct_out_data;
            alu_rs1_reg <= alu_rs1_reg;
            alu_rs2_reg <= alu_rs2_reg;
            rob_alu_out <= rob_alu_out;
        end
    end

    assign alu_funct_out = alu_funct_out_data.funct_unit_out;
    assign pd_alu_out = alu_funct_out_data.pd;
    assign rd_alu_out = alu_funct_out_data.rd;

    always_comb begin
        alu_reg_out.rs1_rdata = alu_rs1_reg;
        alu_reg_out.rs2_rdata = alu_rs2_reg;
        alu_reg_out.rd_wdata = alu_funct_out_data.funct_unit_out;

        alu_reg_out.mem_addr = '0;
        alu_reg_out.mem_rmask = '0;
        alu_reg_out.mem_wmask = '0;
        alu_reg_out.mem_rdata = '0;
        alu_reg_out.mem_wdata = '0;
        alu_reg_out.pc_wdata = '0;
    end

   
    always_ff @(posedge clk) begin
        if(rst || (alu_flag) || rob_flush) begin
            funct_unit_ready <= 1'b1;
            ready_commit_flag <= 1'b0;
        end
        else if(valid_alu) begin
            funct_unit_ready <= 1'b0;
            ready_commit_flag <= 1'b1;
        end
        else begin
            funct_unit_ready <= funct_unit_ready;
            ready_commit_flag <= ready_commit_flag;
        end
    end

    assign ready_commit = ready_commit_flag;

endmodule : funct_unit_alu

