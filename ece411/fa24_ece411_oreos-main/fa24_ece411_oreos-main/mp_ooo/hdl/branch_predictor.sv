module branch_predictor 
import rv32i_types::*; 
import params::*;
(
    input   logic                               clk,
    input   logic                               rst,

    // cpu <-> branch_predictor
    input   logic  [31:0]                       pc_in,
    input   logic  [31:0]                       instruction_data,

    output  logic  [31:0]                       pc_branch_out,
    output  logic  [1:0]                        prediction_val,
    output  logic  [PATTERN_HISTORY_LEN - 1:0]  fetch_idx_out,
    output  logic                               read_flag,
    output  logic  [31:0]                       instruction_data_out,


    // control <-> branch_predictor
    input   logic                               branch_write, // Active low
    input   logic  [1:0]                        updated_val,
    input   logic  [PATTERN_HISTORY_LEN - 1:0]  control_idx,
    input   logic                               stall_rob_flush
);

    //logic   [11:0]  control_idx;
    logic   [GLOBAL_HISTORY_LEN - 1:0]   ghr;
    logic   [31:0]  b_imm;
    logic   [31:0]  b_imm_saved;
    logic   [1:0]   prediction_val_sram;
    logic test;

    logic csb, web;
    logic dout, din;  

    logic csb_br;

    logic read_flag_next;

    logic is_branch;

    logic   [PATTERN_HISTORY_LEN - 1:0]      fetch_idx;
    logic   [31:0]                           instruction_data_saved;

    //assign test = (prediction_val == prediction_val) && 1;

    assign b_imm  = {{20{instruction_data[31]}}, instruction_data[7], instruction_data[30:25], instruction_data[11:8], 1'b0};

    
    assign is_branch = (instruction_data[6:0] == op_b_br);

    always_comb begin
        read_flag_next = '1;  

        if (is_branch && read_flag && !stall_rob_flush) begin
            read_flag_next = '0;  
        end else if (is_branch && !read_flag) begin
            read_flag_next = '1;
        end else begin
            read_flag_next = '1;  
        end
    
    end 

    always_comb begin
        instruction_data_out = instruction_data;
        if (read_flag) begin
            instruction_data_out = instruction_data;
        end else begin
            instruction_data_out = instruction_data_saved;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            read_flag <= '1;
            b_imm_saved <= '0;
            fetch_idx_out <= '0;
            instruction_data_saved <= '0;
        end else begin
            read_flag <= read_flag_next;
            b_imm_saved <= b_imm;
            fetch_idx_out <= fetch_idx;
            instruction_data_saved <= instruction_data;
        end
    end



    always_ff @(posedge clk) begin
        if (rst) begin
            ghr <= '0;
        end else if (!branch_write) begin
            ghr[GLOBAL_HISTORY_LEN - 1:1] <= ghr[GLOBAL_HISTORY_LEN - 2:0];
            ghr[0] <= updated_val[1];
        end else begin
            ghr <= ghr;
        end
    end

    valid_array_branch valid_array_branch_table (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       ('0),
            .web0       (branch_write),
            .addr0      (control_idx),
            .din0       ('1),
            .dout0      (dout),
            .read_addr0 (fetch_idx)
        );

    mp_ooo_branch_table branch_table (
            // Read
            .clk0       (clk),
            .csb0       (csb_br),
            .web0       ('1),
            .addr0      (fetch_idx),
            .din0       ('0),
            .dout0      (prediction_val_sram),

            // Write
            .clk1       (clk),
            .csb1       ('0),
            .web1       (branch_write),
            .addr1      (control_idx),
            .din1       (updated_val),
            .dout1      ()
        );


    always_comb begin
        fetch_idx = '0;
        pc_branch_out = pc_in +'d4;
        prediction_val = 2'b01;
        csb_br = '1;
        if (read_flag) begin
            if (is_branch & !stall_rob_flush) begin
                csb_br = '0;
                fetch_idx = {ghr, pc_in[PC_IDX_LEN + 1:2]};
                pc_branch_out = pc_in;
            end
        end else begin
            if (prediction_val_sram[1] && dout) begin
                prediction_val = prediction_val_sram;
                pc_branch_out = pc_in + b_imm_saved;
            end else begin
                if (dout) begin
                    prediction_val = prediction_val_sram;
                end
                pc_branch_out = pc_in + 'd4;
            end
        end
    end

    //assign control_idx = {ghr, pc_control[5:2]};

endmodule : branch_predictor
