module funct_unit_div_rem 
import rv32i_types::*;
import params::*;
(
    input   logic                                  inst_clk,
    input   logic                                  inst_rst_n,
    input   logic                                  inst_start,
    input   logic     [INST_A_WIDTH-1 : 0]         inst_a,
    input   logic     [INST_B_WIDTH-1 : 0]         inst_b,
    input   logic     [$clog2(NUM_PHYS_REG)-1:0]   pd_div_in,
    input   logic     [4:0]                        rd_div_in, 
    
    output  logic   [$clog2(NUM_PHYS_REG)-1:0]     pd_div_out,
    output  logic   [4:0]                          rd_div_out, 
    output  logic                                  complete_inst,
    output  logic   [31:0]                         div_out,
    output  logic                                  funct_unit_ready,


    input   logic   [BITS_ROB_DEPTH:0]             rob_in_div,
    output  logic   [BITS_ROB_DEPTH:0]             rob_out_div,
    input   logic   [2:0]                          funct3_div,
    input   logic                                  div_flag,

    output  register_t                             div_reg_out,
    input   logic                                  rob_flush      

);

logic                               inst_done_reg;
logic   [BITS_PHYS_REG:0]           hold_pd, hold_pd_next;
logic   [4:0]                       hold_rd, hold_rd_next;
logic                               inst_done, divide_by_0_inst;
logic   [31:0]                      quotient_inst, remainder_inst;

logic   [31:0]                      unsigned_a, unsigned_b;
logic                               result_sign, result_sign_reg;

logic   [31:0]                      rs1_reg, rs1_reg_next, rs2_reg, rs2_reg_next;
logic   [2:0]                       funct3_div_reg, funct3_div_reg_next;

logic [INST_A_WIDTH-1 : 0] sign_inst_a;
logic [INST_B_WIDTH-1 : 0] sign_inst_b;


always_ff @ (posedge inst_clk) begin
    if(inst_rst_n || rob_flush) begin
        hold_pd <= 'x;
        hold_rd <= 'x;
    end
    else begin
        hold_pd <= hold_pd_next;
        hold_rd <= hold_rd_next;
    end
end

always_comb begin
    if(inst_start) begin
        hold_pd_next = pd_div_in;
        hold_rd_next = rd_div_in;
    end
    else begin
        hold_pd_next = hold_pd;
        hold_rd_next = hold_rd;
    end
end

always_comb begin
    pd_div_out = hold_pd;
    rd_div_out = hold_rd;
end

always_ff @(posedge inst_clk) begin
    if(inst_rst_n || (div_flag) || rob_flush) begin
        funct_unit_ready <= 1'b1;
    end
    else if(inst_start) begin
        funct_unit_ready <= 1'b0;
    end
    else funct_unit_ready <= funct_unit_ready;
end

logic [3:0] counter;
logic hold_flag;
logic [31:0] inst_a_reg, inst_b_reg;

always_ff @(posedge inst_clk) begin
    if (inst_rst_n || rob_flush) begin
        hold_flag <= 1'b0;
        counter <= 4'b0000;
        result_sign_reg <= 1'b0;
        inst_a_reg <= '0;
        inst_b_reg <= '0;
        rs1_reg <= '0;
        rs2_reg <= '0;
        funct3_div_reg <= '0;
    end 
    else if (inst_start) begin
        hold_flag <= 1'b1;
        counter <= 4'b0000;
        rob_out_div <= rob_in_div;
        result_sign_reg <= result_sign;
        inst_a_reg <= inst_a;
        inst_b_reg <= inst_b;

        rs1_reg <= rs1_reg_next;
        rs2_reg <= rs2_reg_next;

        funct3_div_reg <= funct3_div_reg_next;
    end 
    else if (hold_flag) begin
        if (counter < 4'b1000) begin
            counter <= counter + 1'b1;
            rob_out_div <= rob_out_div;
            result_sign_reg <= result_sign_reg;
            inst_a_reg <= inst_a_reg;
            inst_b_reg <= inst_b_reg;

            rs1_reg <= rs1_reg;
            rs2_reg <= rs2_reg;

            funct3_div_reg <= funct3_div_reg;
        end 
        else begin
            hold_flag <= 1'b0;
            counter <= 4'b0000;
        end
    end 
end


logic hold_flag_reg;
always_ff @(posedge inst_clk) begin
    if (inst_rst_n || rob_flush) begin
        hold_flag_reg <= '0;
    end else begin
        hold_flag_reg <= hold_flag;
    end
end

assign unsigned_a   = inst_a[31] ? -inst_a : inst_a;
assign unsigned_b   = inst_b[31] ? -inst_b : inst_b;
assign result_sign  = inst_a[31] ^ inst_b[31];

assign rs1_reg_next = inst_a;
assign rs2_reg_next = inst_b;

assign funct3_div_reg_next = funct3_div;

always_comb begin
    div_reg_out = '0;
    if(div_flag) begin
        div_reg_out.rs1_rdata = rs1_reg;
        div_reg_out.rs2_rdata = rs2_reg;
        div_reg_out.rd_wdata  = div_out;
    end
end

always_comb begin
    case (funct3_div_reg)
            3'b100: begin // signed / signed
                if (divide_by_0_inst) begin
                    div_out = '1;
                end else if (signed'(inst_a_reg) == -(1 << 31) && signed'(inst_b_reg) == -1) begin
                    div_out = 32'h80000000;
                end else begin
                    div_out = result_sign_reg ? (~quotient_inst + 1) : quotient_inst;
                end
            end
            3'b101: begin // unsigned / unsigned
                if (divide_by_0_inst) begin
                    div_out = '1;
                end else begin
                    div_out = quotient_inst;
                end
            end
            3'b110: begin // signed % signed
                if (divide_by_0_inst) begin
                    div_out = inst_a_reg;
                end else if (signed'(inst_a_reg) == -(1 << 31) && signed'(inst_b_reg) == -1) begin
                    div_out = '0;
                end else begin
                    div_out = inst_a_reg[31] ? (~remainder_inst + 1) : remainder_inst;
                end
            end
            3'b111: begin // unsigned % unsigned
                if (divide_by_0_inst) begin
                    div_out = inst_a_reg;
                end else begin
                    div_out = remainder_inst;
                end
            end
            default begin
                div_out = 'x;
            end
    endcase
end

logic [31:0] a_op, b_op;
always_comb begin
    if ((funct3_div == 3'b101) || (funct3_div == 3'b111)) begin
        a_op = inst_a;
        b_op = inst_b;
    end else begin
        a_op = unsigned_a;
        b_op = unsigned_b;
    end
end

DW_div_seq #(INST_A_WIDTH, INST_B_WIDTH, INST_TC_MODE, INST_DIV_NUM_CYCLES,
INST_RST_MODE, INST_INPUT_MODE, INST_OUTPUT_MODE,
INST_EARLY_START)
U1 (
    .clk(inst_clk),
    .rst_n(~inst_rst_n),
    .hold(~hold_flag),
    .start(inst_start),
    .a(a_op),
    .b(b_op),
    .complete(inst_done),
    .divide_by_0(divide_by_0_inst),
    .quotient(quotient_inst),
    .remainder(remainder_inst) 
    );

    logic reg_hold_flag;
    always_ff @(posedge inst_clk) begin
        if (inst_rst_n || rob_flush) begin
            reg_hold_flag <= '0;
        end else begin
            reg_hold_flag <= hold_flag;
        end
    end

    
    always_ff @(posedge inst_clk) begin
        if (inst_rst_n || rob_flush) begin
            inst_done_reg <= '0;
        end else if (div_flag) begin
            inst_done_reg <= '0;
        end else if (inst_done && reg_hold_flag) begin
            inst_done_reg <= inst_done;
        end else begin
            inst_done_reg <= inst_done_reg;
        end
    end

assign complete_inst = inst_done_reg;

endmodule
