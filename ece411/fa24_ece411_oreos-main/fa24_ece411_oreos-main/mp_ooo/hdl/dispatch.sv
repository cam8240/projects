module dispatch 
import rv32i_types::*;
import params::*;
(

    //dispatch <-> decode
    input   inst_breakdown_t                inst_decode,
    output  logic                           stall_dequeue,

    // dispatch <-> free list
    input   logic    [BITS_PHYS_REG:0]      avail_phys_reg,
    input   logic                           free_list_empty,
    output  logic                           dequeue_free_list,
    output  imm_reg_mux_t                   inst_type,

    // dispatch <-> RAT
    input    logic                          ps1_valid, ps2_valid,
    input    logic   [BITS_PHYS_REG:0]      ps1, ps2,
    output   logic   [4:0]                  rd, rs1, rs2,
    output   logic   [BITS_PHYS_REG:0]      pd,
    output   logic                          regf_we,

    //dispatch <-> reservation station
    input    logic                          res_station_full,
    output   res_station_entry_t            res_station_entry_out,

    //dispatch <-> ROB
    input     logic  [BITS_ROB_DEPTH:0]     rob_idx,
    input     logic                         rob_full,
    output    logic                         rob_enqueue,
    output    rob_entry_t                   rob_entry_out,
    input     rvfi_signals_t                rvfi_signals_start,

    input     logic                         ls_queue_full,
    input     logic                         load_queue_full,
    input     logic                         control_queue_full,
    input     logic  [31:0]                 inst_pc,
    input     logic                         rob_flush,
    
    input     logic  [1:0]                  prediction_val,
    input     logic  [PATTERN_HISTORY_LEN - 1:0]                 pht_fetch_idx,
    output    logic  [PATTERN_HISTORY_LEN - 1:0]                 pht_fetch_idx_out

);

        logic                   inst_in_valid;
        res_station_entry_t     res_station_entry;
        rob_entry_t             rob_entry;

        logic   stall_dispatch;

        assign inst_in_valid = inst_decode.valid;

        assign pht_fetch_idx_out = pht_fetch_idx;

        always_comb begin
            stall_dispatch = 1'b0;
            if(rob_full || res_station_full || free_list_empty || ls_queue_full || load_queue_full || control_queue_full) begin
                stall_dispatch = 1'b1;
            end
        end

        always_comb begin

            //outputs to RAT
            rd = '0;
            rs1 = '0;
            rs2 = '0;
            pd = '0;
            regf_we = 1'b0;

            //outputs to reservation station
            res_station_entry = '0;

            //outputs to ROB
            rob_entry.commit = '0;
            rob_entry.pd =  '0;
            rob_entry.rd =  '0;
            rob_entry.br_en = '0;
            rob_entry.prediction_val = prediction_val;
            rob_entry.pht_idx = pht_fetch_idx;

            rob_enqueue = 1'b0;

            dequeue_free_list = 1'b0;
            rob_entry.rvfi_signals = rvfi_signals_start;

            inst_type = imm_entry;

            if(inst_in_valid && !stall_dispatch) begin

                inst_type = inst_decode.imm_reg_mux;

                rd = inst_decode.rd_s;
                if((inst_decode.imm_reg_mux == store_entry) || (inst_decode.imm_reg_mux == branch_entry)) begin
                    rd = '0;
                end

                rs1 = inst_decode.rs1_s;
                rs2 = inst_decode.rs2_s;
                
                pd = avail_phys_reg;

                if((inst_decode.imm_reg_mux == store_entry) || (inst_decode.imm_reg_mux == branch_entry)) begin
                    pd = '0;
                end

                dequeue_free_list = 1'b1;
                regf_we = 1'b1;
                //don't want to update RAT or dequeue from free list on a store
                if((inst_decode.imm_reg_mux == store_entry) || (inst_decode.imm_reg_mux == branch_entry)) begin
                    regf_we = 1'b0;
                    dequeue_free_list = 1'b0;
                end

                if(rd == '0) begin
                    regf_we = 1'b0;
                    dequeue_free_list = 1'b0;
                    pd = '0;
                end

                rob_entry.commit = '0;
                rob_entry.pd =  pd;

                rob_entry.rd =  inst_decode.rd_s;
                if((inst_decode.imm_reg_mux == store_entry) || (inst_decode.imm_reg_mux == branch_entry)) begin
                    rob_entry.rd = '0;
                end
                
                rob_enqueue = 1'b1;
                if (rob_flush) begin
                    rob_enqueue = 1'b0;
                end

                rob_entry.rvfi_signals.inst = inst_decode.inst;
                rob_entry.rvfi_signals.rs1_addr = inst_decode.rs1_s;
                rob_entry.rvfi_signals.rs2_addr = inst_decode.rs2_s;

                rob_entry.rvfi_signals.rd_addr = inst_decode.rd_s;
                if((inst_decode.imm_reg_mux == store_entry) || (inst_decode.imm_reg_mux == branch_entry)) begin
                    rob_entry.rvfi_signals.rd_addr = '0;
                end
        
                res_station_entry.valid = 1'b1;
                res_station_entry.funct_unit = inst_decode.inst_type;
                
                res_station_entry.ps1_valid = ((inst_decode.imm_reg_mux == lui_entry) || (inst_decode.imm_reg_mux == auipc_entry) 
                || (inst_decode.imm_reg_mux == jal_entry)) ? '1 : ps1_valid;
                res_station_entry.ps1 = ps1;

                res_station_entry.ps2_valid = ((inst_decode.imm_reg_mux == imm_entry) || (inst_decode.imm_reg_mux == lui_entry)
                 || (inst_decode.imm_reg_mux == auipc_entry) || (inst_decode.imm_reg_mux == jal_entry) || (inst_decode.imm_reg_mux == jalr_entry)) ? '1 : ps2_valid;
                

                if((inst_decode.imm_reg_mux != store_entry) && (inst_decode.imm_reg_mux != branch_entry)) begin
                    res_station_entry.ps2 = ((inst_decode.imm_reg_mux == lui_entry) || (inst_decode.imm_reg_mux == imm_entry)
                     || (inst_decode.imm_reg_mux == auipc_entry) || (inst_decode.imm_reg_mux == jal_entry) || (inst_decode.imm_reg_mux == jalr_entry) ) ? inst_decode.inst_imm : {{31 - $clog2(BITS_PHYS_REG){1'b0}}, ps2};
                end
                //PHYS REG VALUE OF PS2 STORED IN MSBs of PS2 ENTRY FOR STORES
                else begin
                    res_station_entry.ps2 = {{ps2},inst_decode.inst_imm[31 - $clog2(NUM_PHYS_REG):0]};  
                end
                
                res_station_entry.pd  = pd;
                res_station_entry.rd_s = inst_decode.rd_s;
                
                if((inst_decode.imm_reg_mux == store_entry) || (inst_decode.imm_reg_mux == branch_entry)) begin
                    res_station_entry.pd = '0;
                    res_station_entry.rd_s = '0;
                end

                res_station_entry.rs1_s = inst_decode.rs1_s;
                res_station_entry.rs2_s = inst_decode.rs2_s;

                res_station_entry.rob_idx = rob_idx;
                res_station_entry.imm_reg_mux = inst_decode.imm_reg_mux;
                res_station_entry.opcode = inst_decode.opcode;
                res_station_entry.funct3 = inst_decode.funct3;
                res_station_entry.funct7 = inst_decode.funct7;
                res_station_entry.pc = inst_pc;
            end
        end

        assign res_station_entry_out = res_station_entry;
        assign rob_entry_out = rob_entry;
        assign stall_dequeue = stall_dispatch;


endmodule
