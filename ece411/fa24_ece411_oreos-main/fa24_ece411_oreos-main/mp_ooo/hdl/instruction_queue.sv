module instruction_queue 
import rv32i_types::*; 
import params::*;
(
    input   logic                                    clk,
    input   logic                                    rst,


    // Fetch <-> Queue
    input   logic                                    enqueue_flag,
    input   logic   [31:0]                           enqueue_wdata,
    input   logic   [31:0]                           enqueue_pc,
    input   logic   [PATTERN_HISTORY_LEN - 1:0]      enqueue_pht_idx,
    input   logic   [1:0]                            enqueue_pht_prediction,
    output  logic                                    is_full_flag,

    // Decode <-> Queue
    input   logic                                    dequeue_flag,
    output  logic   [31:0]                           dequeue_rdata,
    output  logic   [PATTERN_HISTORY_LEN - 1:0]      dequeue_pht_idx,
    output  logic   [1:0]                            dequeue_pht_prediction,

    output  logic   [31:0]                           dequeue_pc,
    output  logic                                    is_empty_flag,
    input   logic                                    rob_flush

);

    logic [31:0] increment;

    assign increment = {31'b0,1'b1};

    localparam LOG_QUEUE_DEPTH = $clog2(QUEUE_DEPTH);

    inst_queue_t queue_data[QUEUE_DEPTH];

    logic [LOG_QUEUE_DEPTH:0] head_counter;
    logic [LOG_QUEUE_DEPTH:0] tail_counter;

    assign is_full_flag = (head_counter[LOG_QUEUE_DEPTH-1:0] == tail_counter[LOG_QUEUE_DEPTH-1:0]) && (head_counter[LOG_QUEUE_DEPTH] != tail_counter[LOG_QUEUE_DEPTH]);
    assign is_empty_flag = (head_counter[LOG_QUEUE_DEPTH-1:0] == tail_counter[LOG_QUEUE_DEPTH-1:0]) && (head_counter[LOG_QUEUE_DEPTH] == tail_counter[LOG_QUEUE_DEPTH]);

    assign dequeue_pc = queue_data[head_counter[LOG_QUEUE_DEPTH-1:0]].inst_pc;

    always_ff @(posedge clk) begin
        if (rst || rob_flush) begin
            for (int i = 0; i < QUEUE_DEPTH; i++) begin
                queue_data[i] <= '0;
            end
            dequeue_rdata <= '0;
            head_counter <= '0;
            tail_counter <= '0;
        end else begin
            if (enqueue_flag && !is_full_flag) begin
                queue_data[tail_counter[LOG_QUEUE_DEPTH-1:0]].inst <= enqueue_wdata;
                queue_data[tail_counter[LOG_QUEUE_DEPTH-1:0]].inst_pc <= enqueue_pc;
                queue_data[tail_counter[LOG_QUEUE_DEPTH-1:0]].branch_pht_prediction <= enqueue_pht_prediction;
                queue_data[tail_counter[LOG_QUEUE_DEPTH-1:0]].branch_pht_idx <= enqueue_pht_idx;
                if(tail_counter[LOG_QUEUE_DEPTH-1:0] == '1) begin
                    tail_counter[LOG_QUEUE_DEPTH-1:0] <= '0;
                    tail_counter[LOG_QUEUE_DEPTH] <= ~tail_counter[LOG_QUEUE_DEPTH];
                end else begin
                    tail_counter[LOG_QUEUE_DEPTH-1:0] <= tail_counter[LOG_QUEUE_DEPTH-1:0] + increment[LOG_QUEUE_DEPTH-1:0];
                end
            end 
            
            if (dequeue_flag && !is_empty_flag) begin
                dequeue_rdata <= queue_data[head_counter[LOG_QUEUE_DEPTH-1:0]].inst;
                dequeue_pht_idx <= queue_data[head_counter[LOG_QUEUE_DEPTH-1:0]].branch_pht_idx;
                dequeue_pht_prediction <= queue_data[head_counter[LOG_QUEUE_DEPTH-1:0]].branch_pht_prediction;
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


endmodule : instruction_queue

