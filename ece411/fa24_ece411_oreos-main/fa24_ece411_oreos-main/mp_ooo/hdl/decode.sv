module decode
import rv32i_types::*;
import params::*;
(
    input   logic               clk,
    input   logic               rst,

    // queue <-> decode
    input   logic               is_empty_flag,
    input   logic   [31:0]      dequeue_rdata,
    output  logic               dequeue,

    // decode <-> dispatch
    input   logic               stall_dequeue,
    output  inst_breakdown_t    inst_data_out,

    input   logic   [31:0]      inst_pc,
    output  logic   [31:0]      inst_pc_out,

    input   logic               rob_flush
);

            logic   [2:0]   funct3;
            logic   [6:0]   funct7;
            logic   [6:0]   opcode;

            logic   [4:0]   rs1_s;
            logic   [4:0]   rs2_s;
            logic   [4:0]   rd_s;

            logic   [2:0]   funct_unit;
            logic           dequeue_flag;
            logic   [31:0]  inst_imm;
            imm_reg_mux_t   imm_reg_mux;

            logic   [31:0]  i_imm; 
            logic   [31:0]  s_imm; 
            logic   [31:0]  u_imm; 
            logic   [31:0]  b_imm; 
            logic   [31:0]  j_imm;


            inst_breakdown_t inst_data;
            funct_unit_t     dequeue_funct_unit;

            logic   valid_inst, valid_inst_next;

            logic   valid_op;

            assign inst_pc_out = inst_pc; // one cycle delay for inst to dequeue
            

            always_comb begin
                if (!is_empty_flag && !stall_dequeue && !rob_flush) begin
                    dequeue_flag = 1'b1;
                end
                else begin
                    dequeue_flag = 1'b0;
                end
            end
            
            always_ff @(posedge clk) begin
                if(rst || rob_flush) begin
                    valid_inst <= '0;
                end
                else begin
                    valid_inst <= valid_inst_next;
                end
            end

            always_comb begin
                if(dequeue_flag) begin
                    valid_inst_next = 1'b1;
                end
                
                else if(valid_inst && stall_dequeue) begin
                    valid_inst_next = 1'b1;
                end
                else begin
                    valid_inst_next = 1'b0;
                end
            end
            

        //assign inst info
        assign funct3 = dequeue_rdata[14:12];
        assign funct7 = dequeue_rdata[31:25];
        assign opcode = dequeue_rdata[6:0];

        //assign imm values
        assign i_imm  = {{21{dequeue_rdata[31]}}, dequeue_rdata[30:20]};
        assign s_imm  = {{21{dequeue_rdata[31]}}, dequeue_rdata[30:25], dequeue_rdata[11:7]};
        assign u_imm  = {dequeue_rdata[31:12], 12'h000};
        assign b_imm  = {{20{dequeue_rdata[31]}}, dequeue_rdata[7], dequeue_rdata[30:25], dequeue_rdata[11:8], 1'b0};
        assign j_imm  = {{12{dequeue_rdata[31]}}, dequeue_rdata[19:12], dequeue_rdata[20], dequeue_rdata[30:21], 1'b0};

    always_comb begin
        dequeue_funct_unit = alu;
        inst_imm = '0;
        imm_reg_mux = imm_entry;

        rs1_s  = dequeue_rdata[19:15];
        rs2_s  = dequeue_rdata[24:20];
        rd_s   = dequeue_rdata[11:7];

        unique case (opcode)
            op_b_reg: begin 
                dequeue_funct_unit = alu;
                unique case(funct7)
                    7'b0000000: dequeue_funct_unit = alu;
                    7'b0000001: begin
                        if((funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010) || (funct3 == 3'b011)) begin
                            dequeue_funct_unit = mult;
                        end
                        else if ((funct3 == 3'b100) || (funct3 == 3'b101) || (funct3 == 3'b110) || (funct3 == 3'b111)) begin
                            dequeue_funct_unit = divide_rem;
                        end
                    end
                    7'b0100000: dequeue_funct_unit = alu;
                    default : ;
                endcase
                imm_reg_mux = reg_entry;

            end
            
            op_b_imm: begin
                dequeue_funct_unit = alu;
                inst_imm = i_imm;
                rs2_s = '0;
            end
            
            op_b_lui: begin 
                dequeue_funct_unit = alu;
                imm_reg_mux = lui_entry;
                inst_imm = u_imm;
                rs1_s = '0;
                rs2_s = '0;
            end

            op_b_load: begin
                dequeue_funct_unit = load_store;
                imm_reg_mux = imm_entry;
                inst_imm = i_imm;
                rs2_s = '0;
            end
            
            op_b_store: begin
                dequeue_funct_unit = load_store;
                imm_reg_mux = store_entry;
                inst_imm = s_imm;
                rd_s = '0;
            end

            op_b_auipc: begin
                dequeue_funct_unit = control;
                imm_reg_mux = auipc_entry;
                inst_imm = u_imm;
                rs1_s = '0;
                rs2_s = '0;
            end

            op_b_jal: begin
                dequeue_funct_unit = control;
                imm_reg_mux = jal_entry;
                inst_imm = j_imm;
                rs1_s = '0;
                rs2_s = '0;
            end

            op_b_jalr: begin
                dequeue_funct_unit = control;
                imm_reg_mux = jalr_entry;
                inst_imm = i_imm;
                rs2_s = '0;
            end

            op_b_br: begin
                dequeue_funct_unit = control;
                imm_reg_mux = branch_entry;
                inst_imm = b_imm;
                rd_s = '0;
            end

            default: ;
        endcase
    end

    always_comb begin 
        valid_op = 1'b0;
        if ((opcode == op_b_lui) || (opcode == op_b_reg) || (opcode == op_b_imm) || (opcode == op_b_load) || (opcode == op_b_store)
        || (opcode == op_b_auipc) || (opcode == op_b_jal) || (opcode == op_b_jalr) || (opcode == op_b_br)) begin
            valid_op = 1'b1;
        end

        inst_data.valid = (valid_inst && valid_op) ? 1'b1 : 1'b0;
        inst_data.inst = dequeue_rdata;
        inst_data.opcode = opcode;
        inst_data.funct7 = funct7;
        inst_data.funct3 = funct3;
        inst_data.inst_type = dequeue_funct_unit;
        inst_data.inst_imm = inst_imm;
        inst_data.rs1_s = rs1_s;
        inst_data.rs2_s = rs2_s;
        inst_data.rd_s = rd_s;
        inst_data.imm_reg_mux = imm_reg_mux;   
    end

    always_comb begin
        dequeue = dequeue_flag;     //out to inst queue
        inst_data_out = inst_data;  //out to dispatch
    end

endmodule
