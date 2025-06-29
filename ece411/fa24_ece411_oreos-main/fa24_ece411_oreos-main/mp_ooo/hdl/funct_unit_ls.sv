module funct_unit_ls 
import rv32i_types::*;
import params::*;
(
    input   logic                                 clk,
    input   logic                                 rst,

    // Regfile <-> funct_unit_ls
    input   logic           [2:0]                 funct3_ls,
    input   imm_reg_mux_t                         imm_reg_mux, 
    input   logic                                 valid_ls,
    
    input   logic           [31:0]                rs1_v_ls, rs2_v_ls,
    input   logic           [31:0]                store_imm_val,
    input   logic                                 ls_flag,

    output  logic                                 funct_unit_ready,

    input  logic            [BITS_ROB_DEPTH:0]    rob_ls_in,

    input  logic            [BITS_ROB_DEPTH:0]    rob_at_head,

    input  res_station_entry_t                    res_station_in,
    


    //LOAD AND STORES
    output logic            [31:0]                mem_addr_ls,     
    output logic            [3:0]                 read_mask_ls,    
    output logic            [3:0]                 write_mask_ls,   
    input  logic            [31:0]                load_read_data, 
    output logic            [31:0]                store_write_data,
    input  logic                                  data_mem_resp,       

    output funct_unit_out_t                       funct_unit_out_load,
    output cdb_out_t                              store_out,      

    output logic                                  ls_queue_full_out,
    output logic                                  ls_queue_empty_out,
    output logic                                  load_queue_empty_out,
    output logic                                  load_queue_full_out,
    input  logic                                  rob_flush,

    input  cache_state_t                          cache_state,

    input  logic            [LOG_ROB_DEPTH:0]     head_counter_ls
);


    logic           write_flag, write_flag_next;
    logic           store_request, store_request_next, load_request, load_request_next;
    logic   [3:0]   write_mask_flag, write_mask_flag_next;

    logic               load_ready_commit_flag, store_ready_commit_flag;

    register_t          rvfi_signals_next, rvfi_signals, rvfi_signals_next_load, rvfi_signals_load;

    mem_op_t            mem_op_out, mem_op_out_load, mem_op_reg, mem_op_reg_load, mem_op_in, mem_op_funct_out, mem_op_funct_out_load;
    mem_update_t        mem_update;

    logic   [31:0]  ls_rs1_reg, ls_rs1_reg_next;
    logic   [31:0]  ls_rs2_reg, ls_rs2_reg_next;

    logic            [31:0]                load_data;

    logic               ls_queue_full;
    logic               ls_queue_empty;     


    logic               load_queue_full;
    logic               load_queue_empty;  

    logic   [31:0]      load_read_data_temp;

    logic               squash_mem_flush, squash_mem_flush_next;

    logic   [31:0]                  load_address;
    logic   [31:0]                  load_pc;
    logic   [2:0]                   load_funct3;
    logic   [BITS_ROB_DEPTH : 0]    load_rob_idx;
    logic   [31:0]                  store_val;
    logic                           store_found;
    logic                           store_possible;
    logic                           store_addr_ready;
    logic                           store_not_aligned;
    logic                           load_delay;

    logic               load_in_progress;
    logic               store_in_progress;

    logic               store_found_reg;
    logic    [31:0]     load_read_data_reg;
    logic    [31:0]     load_read_data_temp_reg;
    logic    [LS_QUEUE_DEPTH-1:0] num_store_possible;

    logic               ready_status[2];

    assign ls_queue_full_out = ls_queue_full;
    assign ls_queue_empty_out = ls_queue_empty;

    assign load_queue_full_out = load_queue_full;
    assign load_queue_empty_out = load_queue_empty;


//============= ADDR =============================//
    always_comb begin
        if(rst || (!ls_queue_empty) || (!load_queue_empty)) begin
            funct_unit_ready = 1'b1;
        end
        else begin
            funct_unit_ready = 1'b0;
        end
    end
        
    always_comb begin

        mem_op_in.valid = '0;
        mem_op_in.addr_valid = '0;
        mem_op_in.rob_idx  = res_station_in.rob_idx;

        mem_op_in.pc = res_station_in.pc;


        if((res_station_in.valid) && (res_station_in.funct_unit == load_store)) begin
            mem_op_in.valid = 1'b1;
        end

        unique case (res_station_in.imm_reg_mux)
            //LOAD CASE
            imm_entry : begin
                 mem_op_in.rd = res_station_in.rd_s;
                 mem_op_in.pd = res_station_in.pd;
            //STORE CASE
            end
            store_entry : begin
                mem_op_in.rd = '0;
                mem_op_in.pd = '0;
            end
            default: begin
                mem_op_in.rd = '0;
                mem_op_in.pd = '0;
            end
        endcase


        mem_op_in.mem_op_type = res_station_in.imm_reg_mux;
        mem_op_in.mem_addr = '0;
        mem_op_in.rmask = '0;
        mem_op_in.wmask = '0;
        mem_op_in.mem_wdata = '0;
        
        //register data values of rs1 and rs2
        // mem_op_in.rs1_v = rs1_v_ls;
        // mem_op_in.rs2_v = rs2_v_ls;

        mem_op_in.rs1_v = '0;
        mem_op_in.rs2_v = '0;

        mem_op_in.funct3 = res_station_in.funct3;


        //UPDATE LOGIC
        mem_update = '0;

        if(valid_ls) begin
            mem_update.addr_valid = 1'b1;
        end

        mem_update.rob_idx = rob_ls_in;
        mem_update.rs1_v = rs1_v_ls;
        mem_update.rs2_v = rs2_v_ls;

        unique case (imm_reg_mux)

            //LOAD CASE
            imm_entry : begin
                mem_update.mem_addr = rs1_v_ls + rs2_v_ls;
                mem_update.rmask = '0;
                unique case(funct3_ls)
                    load_f3_lb, load_f3_lbu: mem_update.rmask = 4'b0001 << mem_update.mem_addr[1:0];
                    load_f3_lh, load_f3_lhu: mem_update.rmask = 4'b0011 << mem_update.mem_addr[1:0];
                    load_f3_lw             : mem_update.rmask = 4'b1111;
                    default : ;
                endcase
            end

            //STORE CASE
            store_entry : begin
                mem_update.mem_addr = rs1_v_ls + store_imm_val;
                mem_update.wmask = '0;

                unique case (funct3_ls) //rs1_v + s_imm 
                    store_f3_sb: mem_update.wmask = 4'b0001 << mem_update.mem_addr[1:0];
                    store_f3_sh: mem_update.wmask = 4'b0011 << mem_update.mem_addr[1:0];
                    store_f3_sw: mem_update.wmask = 4'b1111;
                    default    : mem_update.wmask = '0;
                endcase
                
                unique case (funct3_ls)
                    store_f3_sb: mem_update.mem_wdata[8 *mem_update.mem_addr[1:0] +: 8 ] = rs2_v_ls[7 :0];
                    store_f3_sh: mem_update.mem_wdata[16*mem_update.mem_addr[1]   +: 16] = rs2_v_ls[15:0];
                    store_f3_sw: mem_update.mem_wdata = rs2_v_ls;
                    default    : mem_update.mem_wdata = '0;
                endcase
            end

            default : ;
        endcase

    end

// ================== END ADDR ================//


//================== LS QUEUE AND MEMORY REQUEST ==================//

    load_store_queue ls_queue_inst
    (
        .clk(clk),
        .rst(rst),

        // ls_funct_unit <-> Queue
        .enqueue_flag(mem_op_in.valid && (mem_op_in.mem_op_type == store_entry)),
        .mem_entry(mem_op_in),
        .mem_update(mem_update),
        .imm_reg_mux(imm_reg_mux),
        .load_address(load_address),
        .load_pc(load_pc),
        .load_funct3(load_funct3),
        .store_val(store_val),
        .store_found(store_found),
        .store_possible(store_possible),
        .store_addr_ready(store_addr_ready),
        .store_not_aligned(store_not_aligned),
        .is_full_flag(ls_queue_full),
        .dequeue_flag(data_mem_resp && !squash_mem_flush && store_request),     //dequeue when cache resp
        .mem_execute(mem_op_out),
        .is_empty_flag(ls_queue_empty),
        .rob_flush(rob_flush),
        .head_counter_rob(head_counter_ls),
        .load_rob_idx(load_rob_idx),
        .num_store_possible(num_store_possible)

    );

    load_queue load_queue_inst
    (
        .clk(clk),
        .rst(rst),

        // ls_funct_unit <-> Queue
        .enqueue_flag(mem_op_in.valid && (mem_op_in.mem_op_type == imm_entry)),
        .mem_entry(mem_op_in),
        .mem_update(mem_update),
        .imm_reg_mux(imm_reg_mux),
        .is_full_flag(load_queue_full),
        .dequeue_flag(load_delay || store_found_reg),     //dequeue when cache resp
        .mem_execute(mem_op_out_load),
        .is_empty_flag(load_queue_empty),
        .rob_flush(rob_flush)
    );

    always_ff @ (posedge clk)begin
        if(rst || rob_flush) begin
            load_delay <= '0;
        end else if ((data_mem_resp && !squash_mem_flush && load_request)) begin
            load_delay <= '1;
        end else begin
            load_delay <= '0;
        end
    end

    always_ff @ (posedge clk)begin
        if(rst || rob_flush) begin
            write_flag <= '0;
            write_mask_flag <= '0;
            load_request <= '0;
            store_request <= '0;
        end
        else begin
            write_flag <= write_flag_next;
            write_mask_flag <= write_mask_flag_next;
            load_request <= load_request_next;
            store_request <= store_request_next;
        end
    end

    always_comb begin
        write_flag_next = 1'b0;
        write_mask_flag_next = '0;
        if(read_mask_ls == '0 && write_mask_ls != '0) begin
            write_flag_next = 1'b0;
            write_mask_flag_next = write_mask_ls;
        end
        else if(write_mask_flag != '0 && data_mem_resp) begin
            write_flag_next = 1'b1;
            write_mask_flag_next = '0;
        end
        else if(write_flag == 1'b1) begin
            write_flag_next = 1'b0;
        end

        if(read_mask_ls == '0 && write_mask_ls != '0) begin
            store_request_next = '1;
        end else if (store_request && data_mem_resp) begin 
            store_request_next = '0;
        end else begin
            store_request_next = '0;
        end

        if(read_mask_ls != '0 && write_mask_ls == '0) begin
            load_request_next = '1;
        end else if (load_request && data_mem_resp) begin 
            load_request_next = '0;
        end else begin
            load_request_next = '0;
        end

    end

    assign ready_status[0] = (mem_op_out.valid && mem_op_out.addr_valid);
    assign ready_status[1] = (mem_op_out_load.valid && mem_op_out_load.addr_valid);

    always_ff @ (posedge clk) begin
        if(rst) begin
            store_found_reg <= '0;
            load_read_data_reg <= '0;
            load_read_data_temp_reg <= '0;
        end
        else if (store_found) begin
            store_found_reg <= '1;
            load_read_data_reg <= load_data;
            load_read_data_temp_reg <= load_read_data_temp;
        end
        // else if(!store_found && store_found_reg) begin
        //     store_found_reg <= '0;
        // end
        else begin
            store_found_reg <= '0;
            load_read_data_reg <= '0;
            load_read_data_temp_reg <= '0;
        end
    end

    always_comb begin
        mem_addr_ls = 'x;
        read_mask_ls = '0;
        write_mask_ls = '0;
        store_write_data = 'x;

        load_in_progress = '0;
        store_in_progress = '0;

        load_address = '0;
        load_pc = '0;
        load_funct3 = '0;
        load_rob_idx = '0;

        for (int i = 0; i < 2; i++) begin
            if ((ready_status[i]) && (i == 0) && (!load_request || data_mem_resp) && (!write_flag) && (cache_state == DATA) && (mem_op_out.rob_idx == rob_at_head)) begin
            
                mem_addr_ls = {mem_op_out.mem_addr[31:2],{2'b00}};
                store_write_data = mem_op_out.mem_wdata;
                write_mask_ls = mem_op_out.wmask;
                store_in_progress = '1;
                break;
            end

            if ((ready_status[i]) && (i == 1) && (!store_request || data_mem_resp) && (!write_flag) && (cache_state == DATA)) begin
                load_address = {mem_op_out_load.mem_addr[31:2],{2'b00}};
                load_pc = mem_op_out_load.pc;
                load_funct3 = mem_op_out_load.funct3;
                load_rob_idx = mem_op_out_load.rob_idx;
                if (((!store_found && store_possible && store_addr_ready && !store_not_aligned && (num_store_possible == 1)) || (!store_possible) || (!store_not_aligned && !store_possible)) && !(load_request && data_mem_resp)) begin
                    mem_addr_ls = {mem_op_out_load.mem_addr[31:2],{2'b00}};
                    load_in_progress = '1;
                    read_mask_ls = mem_op_out_load.rmask;
                end
                break;
            end
        end

        // if(mem_op_out.valid && mem_op_out.addr_valid && !write_flag && cache_state == DATA) begin
        //     mem_addr_ls = {mem_op_out.mem_addr[31:2],{2'b00}};
            
        //     if(mem_op_out.mem_op_type == imm_entry) begin
        //         read_mask_ls = mem_op_out.rmask;
        //     end

        //     if((mem_op_out.mem_op_type == store_entry) && (mem_op_out.rob_idx == rob_at_head)) begin
        //         store_write_data = mem_op_out.mem_wdata;
        //         write_mask_ls = mem_op_out.wmask;
        //     end
        // end
    end


    always_ff @(posedge clk) begin
        if(rst || (ls_flag && !mem_op_out.valid && !mem_op_out.addr_valid) || rob_flush) begin
            mem_op_reg <= '0;
            rvfi_signals <= '0;
        end 
        else if(mem_op_out.valid && mem_op_out.addr_valid) begin
            mem_op_reg <= mem_op_out;
        end
        else begin
            mem_op_reg <= mem_op_reg;
        end

        if(rst || (ls_flag && !mem_op_out_load.valid && !mem_op_out_load.addr_valid) || rob_flush) begin
            mem_op_reg_load <= '0;
            rvfi_signals_load <= '0;
        end 
        else if(mem_op_out_load.valid && mem_op_out_load.addr_valid) begin
            mem_op_reg_load <= mem_op_out_load;
        end
        else begin
            mem_op_reg_load <= mem_op_reg_load;
        end

        if (rst || (ls_flag && !mem_op_reg.valid && !mem_op_reg.addr_valid)) begin
            mem_op_funct_out <= '0;
            rvfi_signals <= '0;
        end
        else if(mem_op_reg.valid && mem_op_reg.addr_valid) begin
            rvfi_signals <= rvfi_signals_next;
            mem_op_funct_out <= mem_op_reg;
        end else begin
            rvfi_signals <= rvfi_signals;
            mem_op_funct_out <= mem_op_funct_out;
        end

        if (rst || (ls_flag && !mem_op_reg_load.valid && !mem_op_reg_load.addr_valid)) begin
            mem_op_funct_out_load <= '0;
            rvfi_signals_load <= '0;
        end
        else if(mem_op_reg_load.valid && mem_op_reg_load.addr_valid) begin
            rvfi_signals_load <= rvfi_signals_next_load;
            mem_op_funct_out_load <= mem_op_reg_load;
        end else begin
            rvfi_signals_load <= rvfi_signals_load;
            mem_op_funct_out_load <= mem_op_funct_out_load;
        end
    end

    logic [2:0]   funct3_load;
    logic [31:0]  mem_addr_load_temp;
    always_comb begin
        load_read_data_temp = 'x;
        load_data = '0;
        funct3_load = '0;
        mem_addr_load_temp = 'x;
        if ((data_mem_resp && load_request) || store_found) begin
            load_data = load_read_data;
            funct3_load = mem_op_reg_load.funct3;
            mem_addr_load_temp = mem_op_reg_load.mem_addr;
            if (store_found) begin
                load_data = store_val;
                funct3_load = mem_op_out_load.funct3;
                mem_addr_load_temp = mem_op_out_load.mem_addr;
            end
            unique case (funct3_load)
                    load_f3_lb : load_read_data_temp = {{24{load_data[7 +8 *mem_addr_load_temp[1:0]]}}, load_data[8 *mem_addr_load_temp[1:0] +: 8 ]};
                    load_f3_lbu: load_read_data_temp = {{24{1'b0}}                          , load_data[8 *mem_addr_load_temp[1:0] +: 8 ]};
                    load_f3_lh : load_read_data_temp = {{16{load_data[15+16*mem_addr_load_temp[1]  ]}}, load_data[16*mem_addr_load_temp[1]   +: 16]};
                    load_f3_lhu: load_read_data_temp = {{16{1'b0}}                          , load_data[16*mem_addr_load_temp[1]   +: 16]};
                    load_f3_lw : load_read_data_temp = load_data;
                    default    : load_read_data_temp = 'x;
            endcase
        end
    end

    always_comb begin
        if(rst || (squash_mem_flush && data_mem_resp)) begin
            squash_mem_flush_next = '0;
        end
        else if((read_mask_ls != '0 || write_mask_ls != '0) && rob_flush) begin
            squash_mem_flush_next = 1'b1;
        end
        else begin
            squash_mem_flush_next = squash_mem_flush;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            squash_mem_flush <= '0;
        end
        else begin
            squash_mem_flush <= squash_mem_flush_next;
        end
    end


    always_ff@(posedge clk) begin
        if (rst || rob_flush) begin
            load_ready_commit_flag <= 1'b0;
            //store_ready_commit_flag <= 1'b0;
        end
        else if(load_request && (data_mem_resp && !squash_mem_flush) || store_found_reg) begin
            load_ready_commit_flag <= 1'b1;
            //store_ready_commit_flag <= 1'b0;
        end else begin
            load_ready_commit_flag <= 1'b0;
        end

        if (rst || rob_flush) begin
            store_ready_commit_flag <= 1'b0;
        end
        else if(store_request && (data_mem_resp && !squash_mem_flush)) begin
            store_ready_commit_flag <= 1'b1;
            //load_ready_commit_flag <= 1'b0;
        end else begin
            //load_ready_commit_flag <= 1'b0;
            store_ready_commit_flag <= 1'b0;
        end
    end


    //ASSIGNING RVFI SIGNALS
    always_comb begin
        rvfi_signals_next.rs1_rdata = mem_op_reg.rs1_v;
        rvfi_signals_next.rs2_rdata = mem_op_reg.rs2_v;
        rvfi_signals_next.rd_wdata  = '0;
        rvfi_signals_next.mem_addr  = mem_op_reg.mem_addr;
        rvfi_signals_next.mem_rmask = mem_op_reg.rmask;
        rvfi_signals_next.mem_wmask = mem_op_reg.wmask;
        rvfi_signals_next.mem_rdata = '0;
        rvfi_signals_next.mem_wdata = '0;
        rvfi_signals_next.pc_wdata = '0;

        rvfi_signals_next_load.rs1_rdata = mem_op_reg_load.rs1_v;
        rvfi_signals_next_load.rs2_rdata = mem_op_reg_load.rs2_v;
        rvfi_signals_next_load.rd_wdata  = '0;
        rvfi_signals_next_load.mem_addr  = mem_op_reg_load.mem_addr;
        rvfi_signals_next_load.mem_rmask = mem_op_reg_load.rmask;
        rvfi_signals_next_load.mem_wmask = mem_op_reg_load.wmask;
        rvfi_signals_next_load.mem_rdata = '0;
        rvfi_signals_next_load.mem_wdata = '0;
        rvfi_signals_next_load.pc_wdata = '0;

        if(data_mem_resp || store_found_reg) begin
            // rvfi_signals_next.rs1_rdata = mem_op_out.rs1_v;
            // rvfi_signals_next.rs2_rdata = mem_op_out.rs2_v;

            if (load_request || store_found_reg) begin
                rvfi_signals_next_load.rd_wdata  = load_read_data_temp;
                //rvfi_signals_next.mem_rdata = load_read_data_temp;
                rvfi_signals_next_load.mem_rdata = load_data;
                if(store_found_reg) begin
                    rvfi_signals_next_load.rd_wdata  = load_read_data_temp_reg;
                    rvfi_signals_next_load.mem_rdata = load_read_data_reg;
                end                  
            end

            //rvfi_signals_next.mem_addr  = mem_op_out.mem_addr;


            // rvfi_signals_next.mem_rmask = mem_op_out.rmask;
            // rvfi_signals_next.mem_wmask = mem_op_out.wmask;

            rvfi_signals_next.mem_wdata = mem_op_reg.mem_wdata;
            rvfi_signals_next_load.mem_wdata = mem_op_reg_load.mem_wdata;
        end


    end

    //FUNCT UNIT OUTS FOR LOADS AND STORES
    assign  funct_unit_out_load.pd = mem_op_funct_out_load.pd;
    assign  funct_unit_out_load.rd = mem_op_funct_out_load.rd;
    assign  funct_unit_out_load.ready_commit = load_ready_commit_flag;
    assign  funct_unit_out_load.funct_unit_out = rvfi_signals_load.rd_wdata;
    assign  funct_unit_out_load.rob_idx = mem_op_funct_out_load.rob_idx;
    assign  funct_unit_out_load.rvfi_data = rvfi_signals_load;


    assign  store_out.pd = mem_op_funct_out.pd;
    assign  store_out.rd = mem_op_funct_out.rd;
    assign  store_out.ready_commit = store_ready_commit_flag;
    assign  store_out.data = '0;
    assign  store_out.rob_idx = mem_op_funct_out.rob_idx;
    assign  store_out.rvfi_data_out = rvfi_signals;


endmodule
