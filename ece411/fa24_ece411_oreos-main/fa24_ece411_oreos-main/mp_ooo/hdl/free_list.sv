module free_list 
import rv32i_types::*;
import params::*;
(
    input   logic                                   clk,
    input   logic                                   rst,

    // free_list <-> dispatch
    input   logic                                   dequeue_free_list,
    input   imm_reg_mux_t                           inst_type,
    input   logic   [BITS_ROB_DEPTH:0]              curr_rob_idx,
    output  logic   [BITS_PHYS_REG:0]               avail_phys_reg,
    output  logic                                   free_list_empty,

    // rrf <-> free_list
    input   logic                                   enqueue_phys_reg,
    input  logic   [BITS_PHYS_REG:0]                freed_phys_reg,
    input   logic                                   rob_flush,
    input   logic  [BITS_ROB_DEPTH:0]               rob_idx_flush,
    input   logic   [BITS_PHYS_REG:0]   rrf_regs_in[32],
    input   rrf_entry_t                 rrf_data_flush 
);

    logic [31:0]                        increment;
    logic [LOG_FREE_LIST_DEPTH:0]       extended_counter;
    logic [LOG_FREE_LIST_DEPTH:0]       free_list_idx;
    logic [LOG_FREE_LIST_DEPTH:0]       invert_flag;
    
    logic is_full_flag;

    assign increment = {31'b0,1'b1};

    logic   [BITS_PHYS_REG:0]   reg_val;

    logic  [BITS_ROB_DEPTH:0]   local1;
    logic                       local2;

    logic  [BITS_ROB_DEPTH:0]   local3;

    imm_reg_mux_t       local4;

    rrf_entry_t         local_rrf_entry;

    assign local_rrf_entry = rrf_data_flush;


    assign local4 = inst_type;

    assign local2 = rob_flush;
    assign local1 = rob_idx_flush;

    assign local3 = curr_rob_idx;

    // localparam LOG_FREE_LIST_DEPTH = $clog2(NUM_PHYS_REG - 32);
    // localparam LOG_FREE_LIST_WIDTH = $clog2(NUM_PHYS_REG);

    logic free_regs[NUM_PHYS_REG];

    // logic [LOG_FREE_LIST_WIDTH-1:0] free_regs_flush[NUM_PHYS_REG - 32];

    //logic [LOG_FREE_LIST_WIDTH-1:0] free_regs_saved[ROB_DEPTH][NUM_PHYS_REG - 32];

    // logic [LOG_FREE_LIST_DEPTH:0] head_counter;
    // logic [LOG_FREE_LIST_DEPTH:0] tail_counter;

    //logic [LOG_FREE_LIST_DEPTH:0] head_counter_saved[ROB_DEPTH];

    // assign is_full_flag = (head_counter[LOG_FREE_LIST_DEPTH-1:0] == tail_counter[LOG_FREE_LIST_DEPTH-1:0]) && (head_counter[LOG_FREE_LIST_DEPTH] == tail_counter[LOG_FREE_LIST_DEPTH]);
    // assign free_list_empty = (head_counter[LOG_FREE_LIST_DEPTH-1:0] == tail_counter[LOG_FREE_LIST_DEPTH-1:0]) && (head_counter[LOG_FREE_LIST_DEPTH] != tail_counter[LOG_FREE_LIST_DEPTH]);

  
    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         for (int i = 0; i < ROB_DEPTH; i++) begin
    //             for (int j = 0; j < NUM_PHYS_REG - 32; j++) begin
    //                 free_regs_saved[i][j] <= '0;
    //             end
    //             head_counter_saved[i] <= '0;
    //         end
    //     end else if ((inst_type == branch_entry) || (inst_type == jal_entry) || (inst_type == jalr_entry)) begin
    //         free_regs_saved[curr_rob_idx] <= free_regs;
    //         head_counter_saved[curr_rob_idx] <= head_counter;
    //     end else begin
    //         free_regs_saved <= free_regs_saved;
    //         head_counter_saved <= head_counter_saved;
    //     end
    // end

    //USE
    //unsigned'((LOG_FREE_LIST_WIDTH)'(i));

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < NUM_PHYS_REG; i++) begin
                if (i < 32) begin
                    free_regs[i] <= '0;
                end else begin
                    free_regs[i] <= '1;
                end
            end
            // head_counter <= '0;
            // tail_counter <= '0;
        end 
       else begin
            if (rob_flush && !enqueue_phys_reg) begin
                
                for (int i = 0; i < NUM_PHYS_REG; i++) begin
                    free_regs[i] <= '1;
                end

                for (int i = 0; i < 32; i++) begin
                    free_regs[rrf_regs_in[i]] <= '0;
                end

                // tail_counter[LOG_FREE_LIST_DEPTH:0] <= '0;
                // head_counter[LOG_FREE_LIST_DEPTH:0] <= '0;
                // //free_regs <= free_regs_saved[rob_idx_flush];
                // free_regs <= free_regs_flush;
            end
            else begin
                if (enqueue_phys_reg && !is_full_flag) begin
                    // free_regs[tail_counter[LOG_FREE_LIST_DEPTH-1:0]] <= freed_phys_reg;
                    // if(tail_counter[LOG_FREE_LIST_DEPTH-1:0] == '1) begin
                    //     tail_counter[LOG_FREE_LIST_DEPTH-1:0] <= '0;
                    //     tail_counter[LOG_FREE_LIST_DEPTH] <= ~tail_counter[LOG_FREE_LIST_DEPTH];
                    // end else begin
                    //     tail_counter[LOG_FREE_LIST_DEPTH-1:0] <= tail_counter[LOG_FREE_LIST_DEPTH-1:0] + increment[LOG_FREE_LIST_DEPTH-1:0];
                    // end
                    free_regs[freed_phys_reg] <= '1;
                end 
                
                if (dequeue_free_list && !free_list_empty) begin
                    // free_regs[head_counter[LOG_FREE_LIST_DEPTH-1:0]] <= '0;
                    // head_counter[LOG_FREE_LIST_DEPTH:0] <= free_list_idx;
                    for (int i = 0; i < NUM_PHYS_REG; i++) begin
                        if (free_regs[i]) begin
                            //avail_phys_reg <= unsigned'((LOG_FREE_LIST_WIDTH)'(i))
                            free_regs[i] <= '0;
                            break;
                        end
                    end
                    
                end
           end
        end
    end

    logic   [5:0] current;
    logic match_found;
    always_comb begin
        // free_list_idx = {{~tail_counter[LOG_FREE_LIST_DEPTH]},tail_counter[LOG_FREE_LIST_DEPTH-1:0]};
        // extended_counter = {{1'b0},head_counter[LOG_FREE_LIST_DEPTH-1:0]};
        // for(int i = 1; i < 32; i++) begin
        //     if (free_regs[unsigned'(5'((extended_counter + unsigned'(($clog2(NUM_PHYS_REG))'(i))) % 32))] != '0) begin
        //         free_list_idx[LOG_FREE_LIST_DEPTH-1:0] = unsigned'(5'((extended_counter + unsigned'(($clog2(NUM_PHYS_REG))'(i))) % 32));
        //         invert_flag = extended_counter + unsigned'(($clog2(NUM_PHYS_REG))'(i));
        //         if(invert_flag > ($clog2(NUM_PHYS_REG))'(31)) begin
        //             free_list_idx[LOG_FREE_LIST_DEPTH] = ~head_counter[LOG_FREE_LIST_DEPTH];
        //         end else begin
        //             free_list_idx[LOG_FREE_LIST_DEPTH] = head_counter[LOG_FREE_LIST_DEPTH];
        //         end
        //         break;
        //     end
        // end

        free_list_empty = '1;

        for (int i = 0; i < NUM_PHYS_REG; i++) begin
            if (free_regs[i]) begin
                free_list_empty = '0;
                break;
            end
        end

        is_full_flag = '0;
        

        // current = '0;
        // match_found = '0;
        // for (int i = 0; i < 32; i++) begin
        //         free_regs_flush[i] = '0;
        // end

        //if (rob_flush) begin
        // for (int i = 0; i < NUM_PHYS_REG; i++) begin
        //     match_found = '0;
        //     for (int j = 0; j < 32; j++) begin
        //         if (unsigned'((LOG_FREE_LIST_WIDTH)'(i)) == rrf_regs_in[j]) begin
        //             match_found = '1;
        //             break;
        //         end

        //     end
             
        //      if ((!match_found) && (((unsigned'((LOG_FREE_LIST_WIDTH)'(i)) != rrf_data_flush.pd) && rrf_data_flush.regf_wb) || !rrf_data_flush.regf_wb)) begin
        //             free_regs_flush[current] = unsigned'((LOG_FREE_LIST_WIDTH)'(i));
        //             current = current + 6'h1; 

        //      end
        // end
        // //end

    end


    //Combinational Read
    always_comb begin
        //for loop
        avail_phys_reg = '0;
        for (int i = 0; i < NUM_PHYS_REG; i++) begin
            if (free_regs[i]) begin
                avail_phys_reg = unsigned'((LOG_FREE_LIST_WIDTH)'(i));
                break;
            end
        end
    end

endmodule
