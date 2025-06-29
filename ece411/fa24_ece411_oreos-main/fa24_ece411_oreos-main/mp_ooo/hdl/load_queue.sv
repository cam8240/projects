module load_queue 
import rv32i_types::*; 
import params::*;
(
    input   logic               clk,
    input   logic               rst,


    // ls_funct_unit <-> Queue
    input   logic               enqueue_flag,
    input   mem_op_t         mem_entry,
    input   mem_update_t    mem_update,
    input   imm_reg_mux_t   imm_reg_mux,
    output  logic               is_full_flag,
    input   logic               dequeue_flag,     //dequeue when cache resp
    output  mem_op_t         mem_execute,
    output  logic               is_empty_flag,
    input   logic               rob_flush
);

    logic [31:0] increment;

    assign increment = {31'b0,1'b1};

    localparam LOG_QUEUE_DEPTH = $clog2(LS_QUEUE_DEPTH);

    mem_op_t queue_data[LS_QUEUE_DEPTH];

    mem_op_t deqeue_data;

    logic [LOG_QUEUE_DEPTH:0] head_counter;
    logic [LOG_QUEUE_DEPTH:0] tail_counter;

    assign is_full_flag = (head_counter[LOG_QUEUE_DEPTH-1:0] == tail_counter[LOG_QUEUE_DEPTH-1:0]) && (head_counter[LOG_QUEUE_DEPTH] != tail_counter[LOG_QUEUE_DEPTH]);
    assign is_empty_flag = (head_counter[LOG_QUEUE_DEPTH-1:0] == tail_counter[LOG_QUEUE_DEPTH-1:0]) && (head_counter[LOG_QUEUE_DEPTH] == tail_counter[LOG_QUEUE_DEPTH]);

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
                if ((queue_data[i].addr_valid == '0) && (queue_data[i].rob_idx == mem_update.rob_idx) && (queue_data[i].valid == '1) && (mem_update.addr_valid == '1) && (imm_reg_mux == imm_entry)) begin
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



endmodule :load_queue

