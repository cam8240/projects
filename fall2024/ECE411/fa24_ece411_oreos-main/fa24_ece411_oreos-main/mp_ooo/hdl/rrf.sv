module rrf 
import rv32i_types::*;
import params::*;
(
    input   logic                                      clk,
    input   logic                                      rst,

    // rrat <-> rob
    input   rrf_entry_t                                rrf_entry,

    // rrat <-> free_list
    output  logic                                      enqueue,
    output  logic   [$clog2(NUM_PHYS_REG) - 1:0]       pd_free,
    output  logic   [$clog2(NUM_PHYS_REG) - 1:0]       rrf_regs_out[32]
);


logic [$clog2(NUM_PHYS_REG) - 1:0] rrf_regs[32];

assign rrf_regs_out = rrf_regs;

always_ff @(posedge clk) begin
     if (rst) begin
        for (int i = 0; i < 32; i++) begin
            rrf_regs[i] <= unsigned'(($clog2(NUM_PHYS_REG))'(i));
        end

    end else begin
        if (rrf_entry.regf_wb) begin
            rrf_regs[rrf_entry.rd] <= rrf_entry.pd;
        end
    end
end

always_comb begin
    enqueue = rrf_entry.regf_wb;
    pd_free = rrf_regs[rrf_entry.rd];
end

endmodule
