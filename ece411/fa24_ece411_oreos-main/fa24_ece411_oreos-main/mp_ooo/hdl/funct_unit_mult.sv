module funct_unit_mult 
import rv32i_types::*;
import params::*;
(
    input   logic                                 inst_clk,
    input   logic                                 inst_rst_n,
    input   logic                                 inst_start,
    input   logic   [31:0]                        inst_a,
    input   logic   [31:0]                        inst_b,
    input   logic   [$clog2(NUM_PHYS_REG)-1:0]    pd_mul_in,
    input   logic   [4:0]                         rd_mul_in,
    
    output  logic   [$clog2(NUM_PHYS_REG)-1:0]    pd_mul_out,
    output  logic   [4:0]                         rd_mul_out, 
    output  logic                                 complete_inst,
    output  logic   [31:0]                        product_inst,
    output  logic                                 funct_unit_ready,

    input   logic   [BITS_ROB_DEPTH:0]            rob_in_mul,
    output  logic   [BITS_ROB_DEPTH:0]            rob_out_mul,
    input   logic   [2:0]                         funct3_mul,
    input   logic                                 mul_flag,

    output  register_t                            mul_reg_out,
    input   logic                                 rob_flush                            
);

logic   [$clog2(NUM_PHYS_REG)-1:0]  hold_pd, hold_pd_next;
logic   [4:0]                       hold_rd, hold_rd_next;
logic                               inst_done;
logic   [2:0]                       counter;
logic                               hold_flag;

logic   [31:0]                      unsigned_a, unsigned_b;
logic                               result_sign, result_sign_reg, sign_a, sign_a_reg;

logic   [31:0]                      rs1_reg, rs1_reg_next, rs2_reg, rs2_reg_next;

logic   [2:0]                       funct3_mul_reg, funct3_mul_reg_next;

logic                               inst_done_reg;

logic [63:0]                        product_out;


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
        hold_pd_next = pd_mul_in;
        hold_rd_next = rd_mul_in;
    end
    else begin
        hold_pd_next = hold_pd;
        hold_rd_next = hold_rd;
    end
end

always_comb begin
    pd_mul_out = hold_pd;
    rd_mul_out = hold_rd;

end

always_ff @(posedge inst_clk) begin
    if(inst_rst_n || (mul_flag) || rob_flush) begin
        funct_unit_ready <= 1'b1;
    end
    else if(inst_start) begin
        funct_unit_ready <= 1'b0;
    end
    else funct_unit_ready <= funct_unit_ready;
end


assign unsigned_a = inst_a[31] ? -inst_a : inst_a;
assign unsigned_b = (inst_b[31] && (funct3_mul == 3'b000 || funct3_mul == 3'b001)) ? -inst_b : inst_b;
assign result_sign = (funct3_mul == 3'b011) ? inst_a[31] : inst_a[31] ^ inst_b[31];
assign sign_a = inst_a[31];


assign rs1_reg_next = inst_a;
assign rs2_reg_next = inst_b;

assign funct3_mul_reg_next = funct3_mul;

always_ff @(posedge inst_clk) begin
    if (inst_rst_n || rob_flush) begin
        hold_flag <= 1'b0;
        counter <= 3'b000;
        result_sign_reg <= 1'b0;
        sign_a_reg <= 1'b0;

        rs1_reg <= '0;
        rs2_reg <= '0;

        funct3_mul_reg <= '0;
    end 
    else if (inst_start) begin
        hold_flag <= 1'b1;
        counter <= 3'b000;
        rob_out_mul <= rob_in_mul;
        result_sign_reg <= result_sign;
        sign_a_reg <= sign_a;

        rs1_reg <= rs1_reg_next;
        rs2_reg <= rs2_reg_next;

        funct3_mul_reg <= funct3_mul_reg_next;

    end 
    else if (hold_flag) begin
        if (counter < 3'b100) begin
            counter <= counter + 1'b1;
            rob_out_mul <= rob_out_mul;
            result_sign_reg <= result_sign_reg;
            sign_a_reg <= sign_a_reg;

            rs1_reg <= rs1_reg;
            rs2_reg <= rs2_reg;

            funct3_mul_reg <= funct3_mul_reg;

        end 
        else begin
            hold_flag <= 1'b0;
            counter <= 3'b000;
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

logic [63:0] product_top;
always_comb begin
    product_top = 'x;
    product_inst = 'x;
    case (funct3_mul_reg)
            3'b000: begin // signed x signed low
                product_top = result_sign_reg ? ~product_out + 1 : product_out;
                product_inst = product_top [31:0];
            end
            3'b001: begin // signed x signed up
                product_top = result_sign_reg ? ~product_out + 1 : product_out;
                product_inst = product_top [63:32];
            end
            3'b011: begin // unsigned x unsigned up
                product_inst = product_out[63:32];
            end
            3'b010: begin // signed x unsigned up
                product_top = sign_a_reg ? ~product_out + 1 : product_out;
                product_inst = product_top [63:32];
            end
            default begin
                product_top = 'x;
                product_inst = 'x;
            end
    endcase
end

always_comb begin
    mul_reg_out = '0;

    if(mul_flag) begin
        mul_reg_out.rs1_rdata = rs1_reg;
        mul_reg_out.rs2_rdata = rs2_reg;
        mul_reg_out.rd_wdata = product_inst;
    end
end

logic [31:0] a_op, b_op;
always_comb begin
    if ((funct3_mul == 3'b011)) begin
        a_op = inst_a;
        b_op = inst_b;
    end else begin
        a_op = unsigned_a;
        b_op = unsigned_b;
    end
end

// Instance of DW_mult_seq
DW_mult_seq #(INST_A_WIDTH,
    INST_B_WIDTH,
    INST_TC_MODE,
    INST_NUM_CYCLES,
    INST_RST_MODE,
    INST_INPUT_MODE,
    INST_OUTPUT_MODE,
    INST_EARLY_START)
    U1 (
        .clk(inst_clk),
        .rst_n(~inst_rst_n),
        .hold(~hold_flag),
        .start(inst_start),
        .a(a_op),
        .b(b_op),
        .complete(inst_done),
        .product(product_out) 
        );

        logic reg_hold_flag;
        always_ff @(posedge inst_clk) begin
            if (inst_rst_n || rob_flush) begin
                reg_hold_flag <= '0;
            end else begin
                reg_hold_flag <= hold_flag;
            end
        end


        // logic inst_done_reg;
        always_ff @(posedge inst_clk) begin
            if (inst_rst_n || rob_flush) begin
                inst_done_reg <= '0;
            end else if (mul_flag) begin
                inst_done_reg <= '0;
            end else if (inst_done && reg_hold_flag) begin
                inst_done_reg <= inst_done;
            end else begin
                inst_done_reg <= inst_done_reg;
            end
        end

assign complete_inst = inst_done_reg;

endmodule
