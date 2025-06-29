module load_store_queue 
import rv32i_types::*; 
import params::*;
(
    input   logic               clk,
    input   logic               rst,


    // ls_funct_unit <-> Queue
    input   logic           enqueue_flag,
    input   mem_op_t        mem_entry,
    input   mem_update_t    mem_update,
    input   imm_reg_mux_t   imm_reg_mux,
    input   logic  [31:0]          load_address,
    input   logic  [31:0]          load_pc,
    input   logic  [BITS_ROB_DEPTH : 0] load_rob_idx,
    input   logic  [2:0]          load_funct3,
    output  logic   [31:0]          store_val,
    output  logic                        store_found,
    output  logic                        store_possible,   
    output  logic                   store_addr_ready,   
    output  logic                   store_not_aligned,    
    output  logic               is_full_flag,
    input   logic               dequeue_flag,     //dequeue when cache resp
    output  mem_op_t         mem_execute,
    output  logic               is_empty_flag,
    input   logic               rob_flush,
    input   logic [LOG_ROB_DEPTH:0] head_counter_rob, //FROM ROB
    output  logic [LS_QUEUE_DEPTH-1:0] num_store_possible
);

    logic [31:0] increment;

    logic [31:0] temp_pc;
    assign temp_pc = load_pc;

    //logic [LOG_ROB_DEPTH:0] head_counter_ls_temp;

    //assign head_counter_ls_temp = head_counter_ls;

    assign increment = {31'b0,1'b1};

    localparam LOG_QUEUE_DEPTH = $clog2(LS_QUEUE_DEPTH);

    mem_op_t queue_data[LS_QUEUE_DEPTH];

    mem_op_t deqeue_data;

    mem_op_t check_ls_forward;

    logic [LOG_QUEUE_DEPTH:0] head_counter;
    logic [LOG_QUEUE_DEPTH:0] tail_counter;

    logic [LOG_QUEUE_DEPTH - 1:0] extended_counter;

    logic [31:0] store_curr_address;

    logic  [BITS_ROB_DEPTH:0]    load_dist, store_dist;

       logic [LOG_QUEUE_DEPTH - 1:0] extended_counter_idx;  

    assign is_full_flag = (head_counter[LOG_QUEUE_DEPTH-1:0] == tail_counter[LOG_QUEUE_DEPTH-1:0]) && (head_counter[LOG_QUEUE_DEPTH] != tail_counter[LOG_QUEUE_DEPTH]);
    assign is_empty_flag = (head_counter[LOG_QUEUE_DEPTH-1:0] == tail_counter[LOG_QUEUE_DEPTH-1:0]) && (head_counter[LOG_QUEUE_DEPTH] == tail_counter[LOG_QUEUE_DEPTH]);

    always_comb begin
        store_val = '0;
        store_found = 1'b0;
        store_possible = 1'b0;
        store_not_aligned = 1'b0;
        store_addr_ready = 1'b0;
        store_curr_address = '0;
        extended_counter = {tail_counter[LOG_QUEUE_DEPTH-1:0]};
        
        // check_ls_forward = queue_data[unsigned'((LOG_QUEUE_DEPTH - 1)'((extended_counter + unsigned'(LOG_QUEUE_DEPTH'(i))) % QUEUE_DEPTH))];

        check_ls_forward = '0;
        
        if(head_counter_rob[BITS_ROB_DEPTH:0] > load_rob_idx) begin
            load_dist = unsigned'((LOG_ROB_DEPTH)'(ROB_DEPTH)) - (head_counter_rob[BITS_ROB_DEPTH:0] - load_rob_idx);
        end
        else if (head_counter_rob[BITS_ROB_DEPTH:0] < load_rob_idx) begin
            load_dist = load_rob_idx - head_counter_rob[BITS_ROB_DEPTH:0];
        end
        else begin
            load_dist = '0;
        end

        num_store_possible = '0;

        for (int i = 0; i < LS_QUEUE_DEPTH; i++) begin

            if(signed'((extended_counter - unsigned'(LOG_QUEUE_DEPTH'(i)))) < signed'((LOG_QUEUE_DEPTH)'(0))) begin
                extended_counter_idx = unsigned'((LOG_QUEUE_DEPTH)'(8 + signed'((extended_counter - unsigned'((LOG_QUEUE_DEPTH)'(i))))));
            end
            else begin
                extended_counter_idx = (unsigned'((LOG_QUEUE_DEPTH)'(extended_counter - unsigned'((LOG_QUEUE_DEPTH)'(i)))));
            end

            check_ls_forward = queue_data[extended_counter_idx];
            
            store_curr_address = {queue_data[extended_counter_idx].mem_addr[31:2],{2'b00}};

            if((head_counter_rob[BITS_ROB_DEPTH:0] > check_ls_forward.rob_idx) && check_ls_forward.valid) begin
                store_dist = unsigned'((LOG_ROB_DEPTH)'(ROB_DEPTH)) - (head_counter_rob[BITS_ROB_DEPTH:0] - check_ls_forward.rob_idx);
            end
            else if ((head_counter_rob[BITS_ROB_DEPTH:0] < check_ls_forward.rob_idx) && check_ls_forward.valid) begin
                store_dist = check_ls_forward.rob_idx - head_counter_rob[BITS_ROB_DEPTH:0];
            end
            else begin
                store_dist = '0;
            end
            

            if ((store_dist < load_dist)&& (check_ls_forward.valid) && (load_address != 0)) begin
                if (load_funct3 == check_ls_forward.funct3 ) begin
                    store_possible = 1'b1;
                    num_store_possible = num_store_possible + 1'b1;
                    if (check_ls_forward.addr_valid) begin
                        store_addr_ready = 1'b1;
                        if ((load_address == store_curr_address)) begin
                            store_val = check_ls_forward.mem_wdata;
                            store_found = 1'b1;
                        end
                    end
                end else begin
                    store_possible = 1'b1;
                    num_store_possible = num_store_possible + 1'b1;
                    if (check_ls_forward.addr_valid) begin
                        store_addr_ready = 1'b1;
                     if ((load_address == store_curr_address)) begin
                            store_not_aligned = 1'b1;
                        end
                    end
                end

                if ((!store_addr_ready) || (store_addr_ready && store_found) || store_not_aligned) begin
                    break;
                end
            end   
        end
    end
    always_comb begin
        mem_execute = queue_data[head_counter[LOG_QUEUE_DEPTH-1:0]];

        if(dequeue_flag) begin
            if((queue_data[(head_counter[LOG_QUEUE_DEPTH-1:0] + unsigned'((LOG_QUEUE_DEPTH-1)'(1))) % LS_QUEUE_DEPTH].valid)) begin
                mem_execute = queue_data[(head_counter[LOG_QUEUE_DEPTH-1:0] + unsigned'((LOG_QUEUE_DEPTH-1)'(1))) % LS_QUEUE_DEPTH];
            end
            else begin
                mem_execute.valid = 1'b0;
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if (rst || rob_flush) begin
            deqeue_data <= '0;
            for (int i = 0; i < LS_QUEUE_DEPTH; i++) begin
                queue_data[i].valid <= '0;
                queue_data[i].addr_valid <= '0;
                queue_data[i].mem_op_type <= imm_entry;
                queue_data[i].wmask <= '0;
                queue_data[i].rmask <= '0;
                queue_data[i].mem_addr <= '0;
                queue_data[i].mem_wdata <= '0;
                queue_data[i].rd <= '0;
                queue_data[i].pd <= '0;
            end
            head_counter <= '0;
            tail_counter <= '0;
        end else begin
            for (int i = 0; i < LS_QUEUE_DEPTH; i++) begin
                if ((queue_data[i].addr_valid == '0) && (queue_data[i].rob_idx == mem_update.rob_idx) && (queue_data[i].valid == '1) && (mem_update.addr_valid == '1) && (imm_reg_mux == store_entry)) begin
                    queue_data[i].addr_valid <= mem_update.addr_valid;
                    queue_data[i].wmask <= mem_update.wmask;
                    queue_data[i].rmask <= mem_update.rmask;
                    queue_data[i].mem_addr <= mem_update.mem_addr;
                    queue_data[i].mem_wdata <= mem_update.mem_wdata;
                    queue_data[i].rs1_v <= mem_update.rs1_v;
                    queue_data[i].rs2_v <= mem_update.rs2_v;
                end
            end

            if (enqueue_flag && !is_full_flag) begin
                queue_data[tail_counter[LOG_QUEUE_DEPTH-1:0]] <= mem_entry;
                if(tail_counter[LOG_QUEUE_DEPTH-1:0] == '1) begin
                    tail_counter[LOG_QUEUE_DEPTH-1:0] <= '0;
                    tail_counter[LOG_QUEUE_DEPTH] <= ~tail_counter[LOG_QUEUE_DEPTH];
                end else begin
                    tail_counter[LOG_QUEUE_DEPTH-1:0] <= tail_counter[LOG_QUEUE_DEPTH-1:0] + increment[LOG_QUEUE_DEPTH-1:0];
                end
            end 
            
            if (dequeue_flag && !is_empty_flag) begin
                deqeue_data <= queue_data[head_counter[LOG_QUEUE_DEPTH-1:0]];
                queue_data[head_counter[LOG_QUEUE_DEPTH-1:0]] <= '0;
                if(head_counter[LOG_QUEUE_DEPTH-1:0] == '1) begin
                    head_counter[LOG_QUEUE_DEPTH-1:0] <= '0;
                    head_counter[LOG_QUEUE_DEPTH] <= ~head_counter[LOG_QUEUE_DEPTH];
                end else begin
                    head_counter[LOG_QUEUE_DEPTH-1:0] <= head_counter[LOG_QUEUE_DEPTH-1:0] + increment[LOG_QUEUE_DEPTH-1:0];
                end
            end
        end
    end



endmodule : load_store_queue

