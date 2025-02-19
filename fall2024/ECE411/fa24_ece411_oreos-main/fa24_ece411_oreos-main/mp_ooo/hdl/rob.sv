module rob 
import rv32i_types::*;
import params::*;
(
    input   logic                                       clk,
    input   logic                                       rst,


    //ROB <-> dispatch
    input   logic                                       enqueue_rob,
    input   rob_entry_t                                 rob_entry,
    output  logic                                       rob_full,
    output  logic         [$clog2(ROB_DEPTH) - 1:0]     rob_idx,

    //ROB <-> load_store funct unit
    output  logic         [$clog2(ROB_DEPTH) - 1:0]     rob_at_head,
    //ROB <-> RRF (ADD THIS LATER)
    output  rrf_entry_t                                 rrf_data,
    
    //CDB
    input   logic                                       ready_commit,
    input   logic         [$clog2(ROB_DEPTH) - 1:0]     rob_idx_cdb,
    input   register_t                                  rvfi_from_cdb,

    input   cdb_out_t                                   store_in,
    input   cdb_out_t                                   control_in,

    output  logic                                       rob_commit,
    output  logic         [$clog2(ROB_DEPTH)-1:0]       rob_commit_idx,
    output  logic         [31:0]                        rob_pc_wdata,
    output  logic                                       rob_flush,
    output  logic         [63:0]                        rob_order,

    input   logic         [BITS_ROB_DEPTH:0]            rob_idx_branch,
    output  logic         [1:0]                         prediction_val_control,
    output  logic         [PATTERN_HISTORY_LEN - 1:0]   pht_write_idx_rob,

    output  logic         [LOG_ROB_DEPTH:0]             head_counter_out
);


    logic           monitor_valid;
    logic   [63:0]  monitor_order;
    logic   [31:0]  monitor_inst;
    logic   [4:0]   monitor_rs1_addr;
    logic   [4:0]   monitor_rs2_addr;
    logic   [31:0]  monitor_rs1_rdata;
    logic   [31:0]  monitor_rs2_rdata;
    logic           monitor_regf_we;
    logic   [4:0]   monitor_rd_addr;
    logic   [31:0]  monitor_rd_wdata;
    logic   [31:0]  monitor_pc_rdata;
    logic   [31:0]  monitor_pc_wdata;
    logic   [31:0]  monitor_mem_addr;
    logic   [3:0]   monitor_mem_rmask;
    logic   [3:0]   monitor_mem_wmask;
    logic   [31:0]  monitor_mem_rdata;
    logic   [31:0]  monitor_mem_wdata;

    logic   [31:0]  increment;

    assign increment = {31'b0,1'b1};

    // localparam LOG_ROB_DEPTH = $clog2(ROB_DEPTH);

    rob_entry_t rob_data[ROB_DEPTH];

    logic [LOG_ROB_DEPTH:0] head_counter;
    logic [LOG_ROB_DEPTH:0] tail_counter;

    assign head_counter_out = head_counter;
    
    always_comb begin
        if (rob_flush && (monitor_inst[6:0] != op_b_auipc)) begin
            rob_pc_wdata = monitor_pc_wdata;
        end else begin
            rob_pc_wdata = monitor_rd_wdata;
        end
    end

    assign rob_full = (head_counter[LOG_ROB_DEPTH-1:0] == tail_counter[LOG_ROB_DEPTH-1:0]) && (head_counter[LOG_ROB_DEPTH] != tail_counter[LOG_ROB_DEPTH]);
    always_comb begin
        rob_idx = '0;
        if(enqueue_rob && !rob_full) begin
            rob_idx = tail_counter[LOG_ROB_DEPTH-1:0];
        end
    end

    assign rob_commit = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].commit;
    assign rob_commit_idx = head_counter[LOG_ROB_DEPTH-1:0];

    assign rob_flush = (((rob_data[head_counter[LOG_ROB_DEPTH-1:0]].br_en != rob_data[head_counter[LOG_ROB_DEPTH-1:0]].prediction_val[1]) && (monitor_inst[6:0] == op_b_br))
     || (monitor_inst[6:0] == op_b_jal) || (monitor_inst[6:0] == op_b_jalr));

    assign rob_order = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.order;

    assign prediction_val_control = rob_data[rob_idx_branch].prediction_val;
    assign pht_write_idx_rob = rob_data[rob_idx_branch].pht_idx;
    
    always_ff @(posedge clk) begin
        if (rst || rob_flush) begin
            for (int i = 0; i < ROB_DEPTH; i++) begin
                rob_data[i] <= '0;
            end
            head_counter <= '0;
            tail_counter <= '0;
        end else begin
            if (enqueue_rob && !rob_full) begin
                rob_data[tail_counter[LOG_ROB_DEPTH-1:0]] <= rob_entry;
                if(tail_counter[LOG_ROB_DEPTH-1:0] == '1) begin
                    tail_counter[LOG_ROB_DEPTH-1:0] <= '0;
                    tail_counter[LOG_ROB_DEPTH] <= ~tail_counter[LOG_ROB_DEPTH];
                end else begin
                    tail_counter[LOG_ROB_DEPTH-1:0] <= tail_counter[LOG_ROB_DEPTH-1:0] + increment[LOG_ROB_DEPTH-1:0];
                end
            end 
            
            if (rob_data[head_counter[LOG_ROB_DEPTH-1:0]].commit == 1'b1) begin

                rob_data[head_counter[LOG_ROB_DEPTH-1:0]] <= '0;
                
                if(head_counter[LOG_ROB_DEPTH-1:0] == '1) begin
                    head_counter[LOG_ROB_DEPTH-1:0] <= '0;
                    head_counter[LOG_ROB_DEPTH] <= ~head_counter[LOG_ROB_DEPTH];
                end else begin
                    head_counter[LOG_ROB_DEPTH-1:0] <= head_counter[LOG_ROB_DEPTH-1:0] + increment[LOG_ROB_DEPTH-1:0];
                end
            end

            if (ready_commit) begin

                rob_data[rob_idx_cdb].commit <= 1'b1;
                rob_data[rob_idx_cdb].rvfi_signals.rs1_rdata <= rvfi_from_cdb.rs1_rdata;
                rob_data[rob_idx_cdb].rvfi_signals.rs2_rdata <= rvfi_from_cdb.rs2_rdata;
                rob_data[rob_idx_cdb].rvfi_signals.rd_wdata <= rvfi_from_cdb.rd_wdata;

                rob_data[rob_idx_cdb].rvfi_signals.mem_addr <= rvfi_from_cdb.mem_addr; 
                rob_data[rob_idx_cdb].rvfi_signals.mem_rmask <= rvfi_from_cdb.mem_rmask;
                rob_data[rob_idx_cdb].rvfi_signals.mem_wmask <= rvfi_from_cdb.mem_wmask;
                rob_data[rob_idx_cdb].rvfi_signals.mem_rdata <= rvfi_from_cdb.mem_rdata;
                rob_data[rob_idx_cdb].rvfi_signals.mem_wdata <= rvfi_from_cdb.mem_wdata;

                if ((rob_data[rob_idx_cdb].rvfi_signals.inst[6:0] == op_b_auipc) || (rob_data[rob_idx_cdb].rvfi_signals.inst[6:0] == op_b_jal) 
                || (rob_data[rob_idx_cdb].rvfi_signals.inst[6:0] == op_b_jalr)) begin
                    rob_data[rob_idx_cdb].rvfi_signals.pc_wdata <= rvfi_from_cdb.pc_wdata;
                end
            end 

            if (store_in.ready_commit) begin
                
                rob_data[store_in.rob_idx].commit <= 1'b1;
                rob_data[store_in.rob_idx].rvfi_signals.rs1_rdata <= store_in.rvfi_data_out.rs1_rdata;
                rob_data[store_in.rob_idx].rvfi_signals.rs2_rdata <= store_in.rvfi_data_out.rs2_rdata;
                rob_data[store_in.rob_idx].rvfi_signals.rd_wdata <= store_in.rvfi_data_out.rd_wdata;

                rob_data[store_in.rob_idx].rvfi_signals.mem_addr <= store_in.rvfi_data_out.mem_addr; 
                rob_data[store_in.rob_idx].rvfi_signals.mem_rmask <= store_in.rvfi_data_out.mem_rmask;
                rob_data[store_in.rob_idx].rvfi_signals.mem_wmask <= store_in.rvfi_data_out.mem_wmask;
                rob_data[store_in.rob_idx].rvfi_signals.mem_rdata <= store_in.rvfi_data_out.mem_rdata;
                rob_data[store_in.rob_idx].rvfi_signals.mem_wdata <= store_in.rvfi_data_out.mem_wdata;
            end 

            if (control_in.ready_commit) begin
                
                rob_data[control_in.rob_idx].commit <= 1'b1;
                rob_data[control_in.rob_idx].rvfi_signals.rs1_rdata <= control_in.rvfi_data_out.rs1_rdata;
                rob_data[control_in.rob_idx].rvfi_signals.rs2_rdata <= control_in.rvfi_data_out.rs2_rdata;
                rob_data[control_in.rob_idx].rvfi_signals.rd_wdata <= control_in.rvfi_data_out.rd_wdata;
                rob_data[control_in.rob_idx].br_en <= control_in.data[0];
                rob_data[control_in.rob_idx].rvfi_signals.mem_addr <= control_in.rvfi_data_out.mem_addr; 
                rob_data[control_in.rob_idx].rvfi_signals.mem_rmask <= control_in.rvfi_data_out.mem_rmask;
                rob_data[control_in.rob_idx].rvfi_signals.mem_wmask <= control_in.rvfi_data_out.mem_wmask;
                rob_data[control_in.rob_idx].rvfi_signals.mem_rdata <= control_in.rvfi_data_out.mem_rdata;
                rob_data[control_in.rob_idx].rvfi_signals.mem_wdata <= control_in.rvfi_data_out.mem_wdata;

                if(control_in.data[0]) begin
                    rob_data[control_in.rob_idx].rvfi_signals.pc_wdata <= control_in.rvfi_data_out.pc_wdata;
                end
                else begin
                    rob_data[control_in.rob_idx].rvfi_signals.pc_wdata <= rob_data[control_in.rob_idx].rvfi_signals.pc_rdata + 'd4;
                end
            end 
        end
    end



    assign rob_at_head = head_counter[LOG_ROB_DEPTH-1:0];

    always_comb begin
            rrf_data.pd = '0;  
            rrf_data.rd = '0;
            rrf_data.regf_wb = '0;

            monitor_valid     = '0;
            monitor_order     = '0;
            monitor_inst      = '0;
            monitor_rs1_addr  = '0;
            monitor_rs2_addr  = '0;
            monitor_rs1_rdata = '0;
            monitor_rs2_rdata = '0;
            monitor_rd_addr   = '0;
            monitor_rd_wdata  = '0;
            monitor_pc_rdata  = '0;
            monitor_pc_wdata  = '0;
            monitor_mem_addr  = '0;
            monitor_mem_rmask = '0;
            monitor_mem_wmask = '0;
            monitor_mem_rdata = '0;
            monitor_mem_wdata = '0;

        if (rob_data[head_counter[LOG_ROB_DEPTH-1:0]].commit == 1'b1) begin
            rrf_data.pd =  rob_data[head_counter[LOG_ROB_DEPTH-1:0]].pd;  
            rrf_data.rd =  rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rd;
            rrf_data.regf_wb = 1'b1;

            if(rrf_data.rd == '0) begin
                rrf_data.regf_wb = 1'b0;
            end


            monitor_valid     = 1'b1;
            monitor_order     = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.order;
            monitor_inst      = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.inst;
            monitor_rs1_addr  = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.rs1_addr;
            monitor_rs2_addr  = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.rs2_addr;
            monitor_rs1_rdata = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.rs1_rdata;
            monitor_rs2_rdata = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.rs2_rdata;
            monitor_rd_addr   = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.rd_addr;
            monitor_rd_wdata  = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.rd_wdata;
            monitor_pc_rdata  = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.pc_rdata;
            monitor_pc_wdata  = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.pc_wdata;
            monitor_mem_addr  = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.mem_addr;
            monitor_mem_rmask = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.mem_rmask;
            monitor_mem_wmask = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.mem_wmask;
            monitor_mem_rdata = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.mem_rdata;
            monitor_mem_wdata = rob_data[head_counter[LOG_ROB_DEPTH-1:0]].rvfi_signals.mem_wdata;
        end
    end



endmodule : rob
