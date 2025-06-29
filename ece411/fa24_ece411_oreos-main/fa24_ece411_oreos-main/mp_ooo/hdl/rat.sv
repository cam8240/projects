module rat 
import rv32i_types::*;
import params::*;
(
    input   logic                       clk,
    input   logic                       rst,

    // rat <-> dispatch
    input   logic   [4:0]               rd, rs1, rs2,
    input   logic   [BITS_PHYS_REG:0]   pd,
    input   logic                       regf_we,

    // rat <-> free_list
    output  logic                       ps1_valid, ps2_valid,
    output  logic   [BITS_PHYS_REG:0]   ps1, ps2,

    input   cdb_out_t                   cdb_update_rat,
    input   logic   [BITS_PHYS_REG:0]   rrf_regs_in[32],
    input   logic                       rob_flush,
    input   rrf_entry_t                 rrf_data_flush
);


rat_entry_t rat_regs[32];

always_ff @(posedge clk) begin
     if (rst) begin
        for (int i = 0; i < 32; i++) begin
            rat_regs[i].valid <= '1;
            rat_regs[i].pd <= unsigned'(($clog2(NUM_PHYS_REG))'(i));
        end
    end else begin
        if (rob_flush) begin
            for (int i = 0; i < 32; i++) begin
                rat_regs[i].valid <= '1;
                rat_regs[i].pd <= rrf_regs_in[i];
                if (rrf_data_flush.regf_wb && unsigned'(5'(i)) == rrf_data_flush.rd) begin
                    rat_regs[i].pd <= rrf_data_flush.pd;
                end
            end
        end else begin
            if ((cdb_update_rat.ready_commit) && (cdb_update_rat.pd == rat_regs[cdb_update_rat.rd].pd) && ~(cdb_update_rat.rd == rd && regf_we)) begin
                rat_regs[cdb_update_rat.rd].valid <= 1'b1;
            end
            if (regf_we) begin
                rat_regs[rd].valid <= '0;
                rat_regs[rd].pd <= pd;
            end
        end
    end
end

always_comb begin
    ps1 = rat_regs[rs1].pd;
    ps2 = rat_regs[rs2].pd;
    ps1_valid = rat_regs[rs1].valid;
    ps2_valid = rat_regs[rs2].valid;

    if (((cdb_update_rat.rd == rs1) && (cdb_update_rat.ready_commit) && (cdb_update_rat.pd == rat_regs[cdb_update_rat.rd].pd) && ~(cdb_update_rat.rd == rd && regf_we))) begin
        ps1 = rat_regs[cdb_update_rat.rd].pd;
        ps1_valid = '1;
    end 

    if (((cdb_update_rat.rd == rs2) && (cdb_update_rat.ready_commit) && (cdb_update_rat.pd == rat_regs[cdb_update_rat.rd].pd) && ~(cdb_update_rat.rd == rd && regf_we)) )begin
        ps2 = rat_regs[cdb_update_rat.rd].pd;
        ps2_valid = '1;
    end
end

endmodule : rat

