module cpu
import rv32i_types::*;
import params::*;
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid
);

    logic   [31:0]  pc_reg;
    logic   [31:0]  pc_next;

    logic   [31:0]  pc_dequeue_next;
    logic   [31:0]  pc_dequeue;
    logic   [31:0]  pc_dequeue_saved;
    logic   [31:0]  dequeue_inst_pc;

    logic   [31:0]  pc_dispatch;

    logic           i_cache_resp;
    logic   [31:0]  i_cache_rdata;
    logic   [31:0]  i_cache_rdata_saved;

    logic   [255:0] burst_line;
    logic           cacheline_resp;

    logic           dequeue_flag;
    logic           enqueue_flag;
    logic   [31:0]  dequeue_rdata;

    logic           stall_rob_flush;

    logic           cdb_ready_alu;
    logic           cdb_ready_mul;
    logic           cdb_ready_div;
    cdb_out_t       cdb_out;


    //temp variables for decode
    logic            dequeue_test_flag;
    inst_breakdown_t inst_info;
    logic            stall_from_dispatch;
    logic            dequeue_free_list;


    logic   [2:0]   rob_idx_cdb;
    logic   [63:0]  order_counter, order_counter_next;


    // Commented out due to test signals above
    logic           is_empty_flag;
    logic           is_full_flag;

    logic           dfp_read;
    logic   [31:0]  dfp_addr;
    logic   [255:0] dfp_wdata;
    logic           dfp_write;

    logic           inst_read, inst_write, data_read, data_write;
    logic   [31:0]  inst_addr, data_addr;
    logic   [255:0] inst_wdata, data_wdata;

    rvfi_signals_t  rvfi_signals_start;

    rvfi_signals_t  rvfi_signals_start_next;

    logic       rob_enqueue;


    //WIRES FOR MEMORY OPERATIONS
    logic   [31:0]  mem_addr_ls;
    logic   [3:0]   read_mask_ls;
    logic   [3:0]   write_mask_ls;
    logic   [31:0]  load_read_data;
    logic   [31:0]  store_write_data;
    logic           data_mem_resp;

    logic           ls_queue_empty;
    logic           ls_queue_full;
    logic           load_queue_empty;
    logic           load_queue_full;
    logic           control_queue_full;


    logic [BITS_ROB_DEPTH:0] rob_at_head;

    logic   hold_ls_enqueue;

    cdb_out_t store_cdb_entry;
    cdb_out_t control_cdb_entry;

    logic ls_enqueue;
    logic inst_cacheline_resp, data_cacheline_resp;

    logic                      rob_commit;
    logic   [BITS_ROB_DEPTH:0] rob_commit_idx;
    logic   [31:0]             rob_pc_wdata;
    logic                      rob_flush;
    logic   [3:0]              read_mask_flush;
    logic   [63:0]             rob_order;

    state_t inst_state;

    logic [BITS_PHYS_REG:0] rrf_regs_out[32];

    //WIRES FOR FREE LIST
    imm_reg_mux_t               free_list_inst_type;
    logic   [BITS_PHYS_REG:0]   avail_phys_reg;
    logic                       free_list_empty;
    logic                       enqueue_phys_reg;
    logic   [BITS_PHYS_REG:0]   freed_phys_reg;

    logic   regf_we_rat;
    logic   res_station_full;
    res_station_entry_t res_station_entry_out;

    logic [BITS_ROB_DEPTH:0] rob_idx;
    logic       rob_full;
    rob_entry_t rob_entry_out;

    logic   [4:0]   rd_rat, rs1_rat, rs2_rat;
    logic   [BITS_PHYS_REG:0]   pd_rat, ps1_rat, ps2_rat;

    logic           ps1_valid_rat, ps2_valid_rat;

    rrf_entry_t     rrf_entry_out;

    logic   [31:0]   pc_control;
    logic            branch_write;
    logic   [1:0]    prediction_val, prediction_val_next, prediction_val_out;

    assign prediction_val = 2'b01;

    logic   [1:0]    updated_val;
    logic   [31:0]   pc_branch_out;
    logic   [PATTERN_HISTORY_LEN - 1:0]   control_idx;

    logic   [BITS_ROB_DEPTH:0]   rob_idx_branch;
    logic   [1:0]    prediction_val_control;

    logic read_flag;

    logic   [PATTERN_HISTORY_LEN - 1:0]      pht_fetch_idx_in, pht_write_idx, pht_write_idx_rob, pht_fetch_index_dispatch;
    logic   [1:0]       pht_val_in;

    cache_state_t state, state_next;

    cacheline_adapter cacheline_adapter_inst(
        .clk(clk),
        .rst(rst),

        // burst mem -> cacheline adapter
        .bmem_ready(bmem_ready), // in
        .bmem_raddr(bmem_raddr), // in
        .bmem_rdata(bmem_rdata), // in
        .bmem_rvalid(bmem_rvalid), // in

        // cacheline adapter -> burst mem
        .bmem_addr(bmem_addr),   // out
        .bmem_read(bmem_read),   // out
        .bmem_write(bmem_write), // out
        .bmem_wdata(bmem_wdata), // out

        // i_cache -> cacheline adapter
        .i_cache_read(dfp_read), // in
        .i_cache_addr(dfp_addr), // in
        .i_cache_wdata(dfp_wdata), // in
        .i_cache_write(dfp_write), // in

        // cacheline adapter -> i_cache
        .burst_line(burst_line), // out
        .cacheline_resp(cacheline_resp), // out
        .state_out(inst_state), // out
        .cache_state(state) // in
    );

    cache cache_inst (
        .clk(clk),
        .rst(rst),

        // cpu side signals, ufp -> upward facing port
        .ufp_addr(pc_next), // in
        .ufp_rmask(read_mask_flush), // in
        .ufp_wmask('0), // in
        .ufp_rdata(i_cache_rdata), // out
        .ufp_wdata('0), // in
        .ufp_resp(i_cache_resp), // out

        // memory side signals, dfp -> downward facing port
        .dfp_addr(inst_addr), // out
        .dfp_read(inst_read), // out
        .dfp_write(inst_write), // out
        .dfp_rdata(burst_line), // in
        .dfp_wdata(inst_wdata), // out
        .dfp_resp(inst_cacheline_resp) // in
    );


    cache cache_data(
        .clk(clk),
        .rst(rst),

        // cpu side signals, ufp -> upward facing port
        .ufp_addr(mem_addr_ls), // in
        .ufp_rmask(read_mask_ls), // in
        .ufp_wmask(write_mask_ls), // in
        .ufp_rdata(load_read_data), // out
        .ufp_wdata(store_write_data), // in
        .ufp_resp(data_mem_resp), // out

        // memory side signals, dfp -> downward facing port
        .dfp_addr(data_addr), // out
        .dfp_read(data_read), // out
        .dfp_write(data_write), // out
        .dfp_rdata(burst_line), // in
        .dfp_wdata(data_wdata), // out
        .dfp_resp(data_cacheline_resp) // in
    );

//------------ INST AND DATA CACHE CONTROL ---------------//

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= INSTRUCTION;
        end
        else begin
            state <= state_next;
        end
    end

    always_ff @ (posedge clk) begin
        if(rst) begin
            hold_ls_enqueue <= '0;
        end
        else if(inst_state == WAIT) begin
            hold_ls_enqueue <= '0;
        end else if(ls_enqueue) begin
            hold_ls_enqueue <= '1;
        end else begin
            hold_ls_enqueue <= hold_ls_enqueue;
        end
    end

    always_comb begin
        state_next = state;
        inst_cacheline_resp = '0;
        data_cacheline_resp = '0;

        case(state)
            INSTRUCTION : begin
                dfp_read = inst_read;
                dfp_addr = inst_addr;
                dfp_wdata = inst_wdata;
                dfp_write =  inst_write;
                inst_cacheline_resp = cacheline_resp;
                if((ls_enqueue || hold_ls_enqueue) && (inst_state == WAIT)) begin
                    state_next = DATA;
                end
                else begin
                    state_next = INSTRUCTION;
                end
            end 
            DATA : begin
                dfp_read = data_read;
                dfp_addr = data_addr;
                dfp_wdata = data_wdata;
                dfp_write = data_write;
                data_cacheline_resp = cacheline_resp;
                if(ls_queue_empty && load_queue_empty && (inst_state == WAIT)) begin
                    state_next = INSTRUCTION;
                end
                else begin
                    state_next = DATA;
                end
            end
        endcase
    end

////////////////////////////////////////////////////////////

    logic   [PATTERN_HISTORY_LEN - 1:0]   dequeue_pht_idx;
    logic   [1:0]    dequeue_pht_val;
    logic   [31:0]      inst_br_out;

    instruction_queue instruction_queue_inst(
        .clk(clk),
        .rst(rst),

        // Fetch <-> Queue
        .enqueue_flag(enqueue_flag), // in
        .enqueue_wdata(inst_br_out), // in
        .enqueue_pc(pc_reg), // in
        .enqueue_pht_idx(pht_fetch_idx_in),   //in
        .enqueue_pht_prediction(pht_val_in),   //in
        .is_full_flag(is_full_flag), // out

        // Decode <-> Queue
        .dequeue_flag(dequeue_flag), // in
        .dequeue_rdata(dequeue_rdata), // out
        .dequeue_pc(dequeue_inst_pc), // out
        .dequeue_pht_idx(dequeue_pht_idx),     //out
        .dequeue_pht_prediction(dequeue_pht_val),  //out
        .is_empty_flag(is_empty_flag), // out
        .rob_flush(rob_flush) // in
    );


    branch_predictor branch_predictor_inst(
        .clk(clk),
        .rst(rst),

        // cpu <-> branch_predictor
        .pc_in(pc_reg), // in
        .instruction_data(i_cache_rdata), // in

        .pc_branch_out(pc_branch_out), // out
        .prediction_val(pht_val_in),   // out
        .fetch_idx_out(pht_fetch_idx_in),  // out
        .read_flag(read_flag), // out
        .instruction_data_out(inst_br_out),

        // control <-> branch_predictor
        .branch_write(branch_write), // in
        .updated_val(updated_val), // in
        .control_idx(pht_write_idx), //in
        .stall_rob_flush(stall_rob_flush)
    );

    always_comb begin
        read_mask_flush = 4'hf;
        if (i_cache_rdata[6:0] == op_b_br || !read_flag || state == DATA) begin
            read_mask_flush = '0;
        end
    end

    always_ff @ (posedge clk) begin
        if(rst) begin
            stall_rob_flush <= '0;
        end
        else if(rob_flush) begin
            stall_rob_flush <= '1;
        end
        else if(i_cache_resp && stall_rob_flush) begin
            stall_rob_flush <= '0;
        end
        else stall_rob_flush <= stall_rob_flush;
    end

//------------ PC ---------------//
 always_ff @ (posedge clk) begin
    if(rst) begin
        i_cache_rdata_saved <= '0;
    end else begin
        i_cache_rdata_saved <= i_cache_rdata;
    end
 end

    always_comb begin
        if (rst) begin
            enqueue_flag = 1'b0;
            pc_next = 32'h1eceb000;
        end
        else begin 
            if(rob_flush) begin
                enqueue_flag = 1'b0;
                pc_next = rob_pc_wdata;
            end else begin
                if(((i_cache_resp) || (!read_flag)) && !is_full_flag && !stall_rob_flush) begin
                    enqueue_flag = 1'b1;
                    if (read_flag && (i_cache_rdata[6:0] == op_b_br)) begin
                        enqueue_flag = 1'b0;
                    end
                    pc_next = pc_branch_out;
                end else begin
                    enqueue_flag = 1'b0;
                    pc_next = pc_reg;
                end
            end
        end

        if (rst) begin
            dequeue_flag = 1'b0;
            pc_dequeue_next = 32'h1eceb000;
            order_counter_next = '0;
        end
        else begin
            if(rob_flush) begin
                dequeue_flag = 1'b0;
                pc_dequeue_next = rob_pc_wdata;
                order_counter_next = rob_order + 1;
            end else begin
                if((!is_empty_flag && dequeue_test_flag)) begin
                    dequeue_flag = 1'b1;
                    pc_dequeue_next = dequeue_inst_pc;
                    // if (!read_flag) begin
                    //     pc_dequeue_next = dequeue_inst_pc;
                    // end
                    order_counter_next = order_counter + 1;
                end else begin
                    pc_dequeue_next = pc_dequeue;
                    dequeue_flag = 1'b0;
                    order_counter_next = order_counter;
                end
            end
        end
    end


    always_ff @(posedge clk) begin
        pc_reg <= pc_next;

        if(stall_from_dispatch && !rob_flush) begin
            pc_dequeue <= pc_dequeue;
            order_counter <= order_counter;
            rvfi_signals_start <= rvfi_signals_start;
            prediction_val_out <= prediction_val_out;
        end
        else begin
            pc_dequeue <= pc_dequeue_next;
            order_counter <= order_counter_next;
            rvfi_signals_start <= rvfi_signals_start_next;
            prediction_val_out <= prediction_val_next;
        end
    end

    always_comb begin
        rvfi_signals_start_next = '0;
        rvfi_signals_start_next.order = order_counter;
        rvfi_signals_start_next.pc_rdata = dequeue_inst_pc;
        rvfi_signals_start_next.pc_wdata = dequeue_inst_pc + 4;
        prediction_val_next = prediction_val;

    end

////////////////////////////////////////////////////////////


    decode decode_isnt(
        .clk(clk),
        .rst(rst),

        // queue <-> decode
        .is_empty_flag(is_empty_flag),       //in
        .dequeue_rdata(dequeue_rdata),       //in
        .dequeue(dequeue_test_flag),         //out

        // decode <-> dispatch
        .stall_dequeue(stall_from_dispatch),   //in
        .inst_data_out(inst_info),              //out
        .inst_pc(pc_dequeue),                    //in
        .inst_pc_out(pc_dispatch),              // out
        .rob_flush(rob_flush)                   // in
    );


    dispatch dispatch_inst
    (

        //dispatch <-> decode
        .inst_decode(inst_info),                //in
        .stall_dequeue(stall_from_dispatch),    //out

        // dispatch <-> free list
        .avail_phys_reg(avail_phys_reg),        //in
        .free_list_empty(free_list_empty),      //in
        .dequeue_free_list(dequeue_free_list),  //out
        .inst_type(free_list_inst_type),  //out

        // dispatch <-> RAT
        .ps1_valid(ps1_valid_rat), //in
        .ps2_valid(ps2_valid_rat),  //in
        .ps1(ps1_rat), //in
        .ps2(ps2_rat),  //in
        
        .rd(rd_rat), //out
        .rs1(rs1_rat), //out
        .rs2(rs2_rat),  //out
        .pd(pd_rat),    //out
        .regf_we(regf_we_rat),  //out

        //dispatch <-> reservation station
        .res_station_full(res_station_full),    //in
        .res_station_entry_out(res_station_entry_out),  //out

        //dispatch <-> ROB
        .rob_idx(rob_idx),  //in
        .rob_full(rob_full),    //in
        .rob_enqueue(rob_enqueue),  //out
        .rob_entry_out(rob_entry_out),   //out

        // RVFI
        .rvfi_signals_start(rvfi_signals_start), // in

        .ls_queue_full(ls_queue_full), // in
        .load_queue_full(load_queue_full), // in

        .control_queue_full(control_queue_full), // in
        .inst_pc(pc_dispatch), // in
        .rob_flush(rob_flush), // in
        .prediction_val(dequeue_pht_val), // in
        .pht_fetch_idx(dequeue_pht_idx),
        .pht_fetch_idx_out(pht_fetch_index_dispatch)
    );


    rat rat_inst
    (
        .clk(clk),
        .rst(rst),

        // rat <-> dispatch
        .rd(rd_rat),  //in
        .rs1(rs1_rat), //in
        .rs2(rs2_rat), //in
        .pd(pd_rat),  //in
        .regf_we(regf_we_rat), //in

        .ps1_valid(ps1_valid_rat),   //out
        .ps2_valid(ps2_valid_rat),   //out
        .ps2(ps2_rat),      //out
        .ps1(ps1_rat),     //out

        //ADD CDB INPUTS
        .cdb_update_rat(cdb_out), // in
        .rrf_regs_in(rrf_regs_out), // in
        .rob_flush(rob_flush), // in
        .rrf_data_flush(rrf_entry_out) // in
    );

    free_list free_list_inst
    (
        .clk(clk),
        .rst(rst),

        // free_list <-> dispatch
        .dequeue_free_list(dequeue_free_list),  //in
        .inst_type(free_list_inst_type),        //in
        .curr_rob_idx(rob_idx),
        .avail_phys_reg(avail_phys_reg),        //out
        .free_list_empty(free_list_empty),      //out

        // rrf <-> free_list
        .enqueue_phys_reg(enqueue_phys_reg),    //in
        .freed_phys_reg(freed_phys_reg),         //in
        .rob_flush(rob_flush),                   // in
        .rob_idx_flush(rob_commit_idx),
        .rrf_regs_in(rrf_regs_out), // in
        .rrf_data_flush(rrf_entry_out) // in
    );

   logic [LOG_ROB_DEPTH:0] head_counter_out;

    rob rob_inst
    (
        .clk(clk),
        .rst(rst),


        //ROB <-> dispatch
        .enqueue_rob(rob_enqueue),     //in
        .rob_entry(rob_entry_out),     //in
        .rob_full(rob_full),           //out
        .rob_idx(rob_idx),             //out

        //ROB <-> CDB

        //ROB <-> RRF
        .rrf_data(rrf_entry_out), // out
        
        //ROB <-> ls_funct_unit
        .rob_at_head(rob_at_head),      //out

        //CDB
        .ready_commit(cdb_out.ready_commit), // in
        .rob_idx_cdb(cdb_out.rob_idx), // in
        .rvfi_from_cdb(cdb_out.rvfi_data_out), // in
        .store_in(store_cdb_entry), // in
        .control_in(control_cdb_entry), // in
        .rob_commit(rob_commit), // out
        .rob_commit_idx(rob_commit_idx), // out
        .rob_pc_wdata(rob_pc_wdata), // out
        .rob_flush(rob_flush), // out
        .rob_order(rob_order), //out

        .rob_idx_branch(rob_idx_branch), // in
        .prediction_val_control(prediction_val_control), // out
        .pht_write_idx_rob(pht_write_idx_rob),

        .head_counter_out(head_counter_out) //out
                
    );

    rrf rrf_inst (
    .clk(clk),
    .rst(rst),

    // rrat <-> rob
    .rrf_entry(rrf_entry_out), // in
    // rrat <-> free_list
    .enqueue(enqueue_phys_reg), // out
    .pd_free(freed_phys_reg), // out
    .rrf_regs_out(rrf_regs_out) // out
    );


    res_station_adapter res_station_adapter_inst
    (
        .clk(clk),
        .rst(rst),

        .res_station_in(res_station_entry_out), // in
        .res_station_full(res_station_full), // out

        .cdb_out(cdb_out), // out

        //FOR LOAD/STORE OPERATIONS
        .mem_addr_ls(mem_addr_ls),                     //out
        .read_mask_ls(read_mask_ls),                   //out
        .write_mask_ls(write_mask_ls),                 //out
        .load_read_data(load_read_data),               //in
        .store_write_data(store_write_data),           //out
        .data_mem_resp(data_mem_resp),                 //in
        .rob_at_head(rob_at_head),                      //in
        .ls_queue_empty(ls_queue_empty), // out
        .ls_queue_full(ls_queue_full), // out
        .load_queue_empty(load_queue_empty), // out
        .load_queue_full(load_queue_full), // out

        .store_out(store_cdb_entry), // out
        .control_out(control_cdb_entry), // out
        .ls_enqueue(ls_enqueue),

        .control_queue_full(control_queue_full), // out
        .rob_commit(rob_commit), // in
        .rob_commit_idx(rob_commit_idx), // in
        .rob_flush(rob_flush), // in

        .cache_state(state), // in
        .pc_control_out(pc_control), // out
        .branch_write(branch_write), // out
        .updated_val(updated_val), // out

        .rob_idx_branch(rob_idx_branch), // out
        .prediction_val_control(prediction_val_control), // in

        .pht_write_idx(pht_write_idx),    //out
        .pht_write_idx_rob(pht_write_idx_rob),   //in

        .head_counter_ls(head_counter_out)  //in
    );


endmodule : cpu
