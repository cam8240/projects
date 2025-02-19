module funct_unit_control 
import rv32i_types::*;
import params::*;
(
    input   logic                                  clk,
    input   logic                                  rst,

    // Regfile <-> funct_unit_control
    input   logic           [2:0]                  funct3_control,
    input   imm_reg_mux_t                          imm_reg_mux, 
    input   logic                                  valid_control,
    
    input   logic           [31:0]                 rs1_v_control, rs2_v_control,
    input   logic           [31:0]                 control_imm_val,
    input   logic                                  control_flag,

    output   logic                                 funct_unit_ready,

    input  logic            [BITS_ROB_DEPTH:0]     rob_control_in,

    input   res_station_entry_t                    res_station_in,
    
    output  funct_unit_out_t                       funct_unit_out_control,
    output  cdb_out_t                              control_out,      
    input   logic           [31:0]                 pc_in,

    output  logic                                  control_queue_full_out,
    output  logic                                  control_queue_empty_out,

    input  logic                                   rob_commit, 
    input  logic            [BITS_ROB_DEPTH:0]     rob_commit_idx,
    input  logic                                   rob_flush,

    // Branch predictor
    output logic                                   branch_write,
    output logic          [1:0]                    updated_val,

    output logic          [BITS_ROB_DEPTH:0]       rob_idx_branch,
    input  logic          [1:0]                    prediction_val_control,

    output logic          [PATTERN_HISTORY_LEN - 1:0]                   pht_write_idx,
    input  logic          [PATTERN_HISTORY_LEN - 1:0]                   pht_write_idx_rob


);
    logic signed   [31:0] as;
    logic signed   [31:0] bs;
    logic unsigned [31:0] au;
    logic unsigned [31:0] bu; 

    logic               branch_ready_commit_flag;
    logic               jump_ready_commit_flag;

    register_t          rvfi_signals_next, rvfi_signals, rvfi_signals2;

    mem_op_control_t    mem_op_out, mem_op_reg, mem_op_in;
    mem_op_funct_out_t  mem_op_funct_out, mem_op_funct_out2;
    mem_update_control_t        mem_update;

    logic   [31:0]  control_rs1_reg, control_rs1_reg_next;
    logic   [31:0]  control_rs2_reg, control_rs2_reg_next;

    logic      control_queue_full;
    logic      control_queue_empty;   
    logic      control_dequeue_flag;  

    logic local1;
    logic  [BITS_ROB_DEPTH:0] local2;

    assign local1 = rob_commit;
    assign local2 = rob_commit_idx;

    assign control_queue_full_out = control_queue_full;
    assign control_queue_empty_out = control_queue_empty;

    assign rob_idx_branch = rob_control_in;


//============= ADDR =============================//
    always_comb begin
        if(rst || (!control_queue_empty)) begin
            funct_unit_ready = 1'b1;
        end
        else begin
            funct_unit_ready = 1'b0;
        end
    end
        
    always_comb begin

        mem_op_in.valid = '0;
        mem_op_in.pc_valid = '0;
        mem_op_in.rob_idx  = res_station_in.rob_idx;
        mem_op_in.pc_in = res_station_in.pc;
        mem_op_in.pc_new = '0;
        mem_op_in.br_en = '0;


        if((res_station_in.valid) && (res_station_in.funct_unit == control)) begin
            mem_op_in.valid = 1'b1;
        end

        unique case (res_station_in.imm_reg_mux)
            auipc_entry : begin
                mem_op_in.rd = res_station_in.rd_s;
                mem_op_in.pd = res_station_in.pd;
            end
            jal_entry : begin
                mem_op_in.rd = res_station_in.rd_s;
                mem_op_in.pd = res_station_in.pd;
            end
            jalr_entry : begin
                mem_op_in.rd = res_station_in.rd_s;
                mem_op_in.pd = res_station_in.pd;
            end
            branch_entry : begin
                mem_op_in.rd = '0;
                mem_op_in.pd = '0;
            end
            default: begin
                mem_op_in.rd = '0;
                mem_op_in.pd = '0;
            end
        endcase


        mem_op_in.mem_op_type = res_station_in.imm_reg_mux;

        mem_op_in.rs1_v = '0;
        mem_op_in.rs2_v = '0;

        mem_op_in.funct3 = res_station_in.funct3;


        //UPDATE LOGIC
        mem_update = '0;

        if(valid_control) begin
            mem_update.pc_valid = 1'b1;
        end

        mem_update.rob_idx = rob_control_in;
        mem_update.rs1_v = rs1_v_control;
        mem_update.rs2_v = rs2_v_control;

        branch_write = '1;
        updated_val = '0;

        au = rs1_v_control;
        bu = rs2_v_control;
        as = signed'(rs1_v_control);
        bs = signed'(rs2_v_control);

        pht_write_idx = '0;
        unique case (imm_reg_mux)
            auipc_entry : begin
               mem_update.pc_new = pc_in + control_imm_val;
            end

            jal_entry : begin
                mem_update.pc_new = pc_in + control_imm_val;
            end

            jalr_entry : begin
                unique case(funct3_control)
                    3'b000: mem_update.pc_new = (rs1_v_control + control_imm_val) & 32'hfffffffe;
                    default : mem_update.pc_new = rs1_v_control & 32'hfffffffe;
                endcase
            end

            branch_entry : begin
                branch_write = '0;
                pht_write_idx = pht_write_idx_rob;
                mem_update.pc_new = pc_in + control_imm_val;
                unique case (funct3_control)
                    branch_f3_beq : mem_update.br_en = (au == bu);
                    branch_f3_bne : mem_update.br_en = (au != bu);
                    branch_f3_blt : mem_update.br_en = (as <  bs);
                    branch_f3_bge : mem_update.br_en = (as >= bs);
                    branch_f3_bltu: mem_update.br_en = (au <  bu);
                    branch_f3_bgeu: mem_update.br_en = (au >= bu); 
                    default       : mem_update.br_en = 1'bx;
                endcase
                unique case (prediction_val_control)
                    2'b00 : begin
                        if (mem_update.br_en) begin
                            updated_val = 2'b01;
                        end else begin
                            updated_val = 2'b00;
                        end
                    end
                    2'b01 : begin
                        if (mem_update.br_en) begin
                            updated_val = 2'b10;
                        end else begin
                            updated_val = 2'b00;
                        end
                    end
                    2'b10 : begin
                        if (mem_update.br_en) begin
                            updated_val = 2'b11;
                        end else begin
                            updated_val = 2'b01;
                        end
                    end
                    2'b11 : begin
                        if (mem_update.br_en) begin
                            updated_val = 2'b11;
                        end else begin
                            updated_val = 2'b10;
                        end
                    end
                    default : updated_val = prediction_val_control;
                endcase
            end
            default : ;
        endcase
    end

// ================== END ADDR ================//



//================== CONTROL QUEUE AND MEMORY REQUEST ==================//

    logic flag, flag_next, flag_reg;
    always_comb begin
        control_dequeue_flag = 1'b0;
        flag_next = flag_reg;

        if(mem_op_out.valid == 1'b1 && mem_op_out.pc_valid == 1'b1) begin
            // if(rob_commit && (rob_commit_idx == mem_op_out.rob_idx)) begin
            //     control_dequeue_flag = 1'b1;
            // end else begin
            //     control_dequeue_flag = 1'b0;
            // end 

            control_dequeue_flag = 1'b1;

            if (((mem_op_out.mem_op_type == auipc_entry) || (mem_op_out.mem_op_type == jal_entry) || (mem_op_out.mem_op_type == jalr_entry))) begin
                if ((!flag_reg || control_flag)) begin
                    control_dequeue_flag = 1'b1;
                    flag_next = '1;
                end else begin
                    control_dequeue_flag = 1'b0;
                    flag_next = '0;
                    if (((mem_op_reg.mem_op_type == auipc_entry) || (mem_op_reg.mem_op_type == jal_entry) || (mem_op_reg.mem_op_type == jalr_entry))) begin
                        flag_next = '1;
                    end

                end
            end
            
        end 
        if (control_flag) begin
            flag_next = '0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            flag_reg <= '0;
        end else begin
            flag_reg <= flag_next;
        end
    end

    control_queue control_queue_inst
    (
        .clk(clk),
        .rst(rst),

        // control_funct_unit <-> Queue
        .enqueue_flag(mem_op_in.valid), // in
        .mem_entry(mem_op_in), // in
        .mem_update(mem_update), // in
        .is_full_flag(control_queue_full), // out
        .dequeue_flag(control_dequeue_flag), // in
        .mem_execute(mem_op_out), // out
        .is_empty_flag(control_queue_empty), // out
        .rob_flush(rob_flush) // in
    );

    always_ff @(posedge clk) begin
        if(rst || (control_flag && (!mem_op_out.valid || !mem_op_out.pc_valid)) || rob_flush) begin
            mem_op_reg <= '0;
            rvfi_signals <= '0;
        end 
        else if(mem_op_out.valid && mem_op_out.pc_valid) begin
            if (mem_op_out.mem_op_type == branch_entry) begin
                mem_op_reg <= mem_op_out;
            end else if (control_dequeue_flag && ((mem_op_out.mem_op_type == auipc_entry) || (mem_op_out.mem_op_type == jal_entry) || (mem_op_out.mem_op_type == jalr_entry))) begin
                mem_op_reg <= mem_op_out;

            end else begin
                if (((mem_op_reg.mem_op_type == auipc_entry) || (mem_op_reg.mem_op_type == jal_entry) || (mem_op_reg.mem_op_type == jalr_entry))
                && (mem_op_reg.valid && mem_op_reg.pc_valid)) begin

                        mem_op_reg <= '0;
                    end else begin
                        mem_op_reg <= mem_op_reg;
                end
            end
        end
        else begin
            if (((mem_op_reg.mem_op_type == auipc_entry) || (mem_op_reg.mem_op_type == jal_entry) || (mem_op_reg.mem_op_type == jalr_entry))
                && (mem_op_reg.valid && mem_op_reg.pc_valid)) begin
                    if ((!(((mem_op_funct_out2.mem_op_type == auipc_entry) || (mem_op_funct_out2.mem_op_type == jal_entry) || (mem_op_funct_out2.mem_op_type == jalr_entry))
                && mem_op_funct_out2.valid && mem_op_funct_out2.pc_valid))
                || ((((mem_op_funct_out2.mem_op_type == auipc_entry) || (mem_op_funct_out2.mem_op_type == jal_entry) || (mem_op_funct_out2.mem_op_type == jalr_entry))
                && mem_op_funct_out2.valid && mem_op_funct_out2.pc_valid) && control_flag)) begin
                        mem_op_reg <= '0;
                    end else begin
                        mem_op_reg <= mem_op_reg;
                    end
                end else begin
                    mem_op_reg <= mem_op_reg;
            end
        end
        if (rst || ((control_flag) && !mem_op_reg.valid && !mem_op_reg.pc_valid) || rob_flush) begin
            mem_op_funct_out <= '0;
            mem_op_funct_out2 <= '0;

            rvfi_signals <= '0;
            rvfi_signals2 <= '0;
        end
        else if(mem_op_reg.valid && mem_op_reg.pc_valid) begin

            if (mem_op_reg.mem_op_type == branch_entry) begin
                rvfi_signals <= rvfi_signals_next;

                mem_op_funct_out.pc_valid <= mem_op_reg.pc_valid;
                mem_op_funct_out.rob_idx <= mem_op_reg.rob_idx;

                mem_op_funct_out.pc_in <= mem_op_reg.pc_in;
                mem_op_funct_out.pc_new <= mem_op_reg.pc_new;

                mem_op_funct_out.br_en <= mem_op_reg.br_en;
                
                mem_op_funct_out.mem_op_type <= mem_op_reg.mem_op_type;
                mem_op_funct_out.rd <= mem_op_reg.rd;
                mem_op_funct_out.pd <= mem_op_reg.pd;
                mem_op_funct_out.funct3 <= mem_op_reg.funct3;

                mem_op_funct_out.rs1_v <= mem_op_reg.rs1_v;
                mem_op_funct_out.rs2_v <= mem_op_reg.rs2_v;

                if((mem_op_funct_out.rob_idx == mem_op_reg.rob_idx) && (mem_op_funct_out.pc_new == mem_op_reg.pc_new)
                && (mem_op_funct_out.pc_in == mem_op_reg.pc_in) && (mem_op_funct_out.rs1_v == mem_op_reg.rs1_v)
                && (mem_op_funct_out.rs2_v == mem_op_reg.rs2_v)) begin
                    mem_op_funct_out.valid <= '0;
                end
                else begin
                    mem_op_funct_out.valid <= '1;
                end

                mem_op_funct_out.commit <= 1'b1;

                rvfi_signals2 <= rvfi_signals2;
                mem_op_funct_out2 <= mem_op_funct_out2;

            end else if ((mem_op_reg.mem_op_type == auipc_entry) || (mem_op_reg.mem_op_type == jal_entry) || (mem_op_reg.mem_op_type == jalr_entry)) begin
                if ((!(((mem_op_funct_out2.mem_op_type == auipc_entry) || (mem_op_funct_out2.mem_op_type == jal_entry) || (mem_op_funct_out2.mem_op_type == jalr_entry))
                && mem_op_funct_out2.valid && mem_op_funct_out2.pc_valid))
                || ((((mem_op_funct_out2.mem_op_type == auipc_entry) || (mem_op_funct_out2.mem_op_type == jal_entry) || (mem_op_funct_out2.mem_op_type == jalr_entry))
                && mem_op_funct_out2.valid && mem_op_funct_out2.pc_valid) && control_flag)) begin

                    rvfi_signals2 <= rvfi_signals_next;
                    
                    mem_op_funct_out2.pc_valid <= mem_op_reg.pc_valid;
                    mem_op_funct_out2.rob_idx <= mem_op_reg.rob_idx;

                    mem_op_funct_out2.pc_in <= mem_op_reg.pc_in;
                    mem_op_funct_out2.pc_new <= mem_op_reg.pc_new;

                    mem_op_funct_out2.br_en <= mem_op_reg.br_en;
                    
                    mem_op_funct_out2.mem_op_type <= mem_op_reg.mem_op_type;
                    mem_op_funct_out2.rd <= mem_op_reg.rd;
                    mem_op_funct_out2.pd <= mem_op_reg.pd;
                    mem_op_funct_out2.funct3 <= mem_op_reg.funct3;

                    mem_op_funct_out2.rs1_v <= mem_op_reg.rs1_v;
                    mem_op_funct_out2.rs2_v <= mem_op_reg.rs2_v;


                    if((mem_op_funct_out2.rob_idx == mem_op_reg.rob_idx) && (mem_op_funct_out2.pc_new == mem_op_reg.pc_new)
                    && (mem_op_funct_out2.pc_in == mem_op_reg.pc_in) && (mem_op_funct_out2.rs1_v == mem_op_reg.rs1_v)
                    && (mem_op_funct_out2.rs2_v == mem_op_reg.rs2_v) && (control_flag)) begin
                        mem_op_funct_out2.valid <= '0;
                    end
                    else begin
                        mem_op_funct_out2.valid <= '1;
                    end

                    mem_op_funct_out2.commit <= 1'b1;
                end else begin
                    rvfi_signals2 <= rvfi_signals2;
                    mem_op_funct_out2 <= mem_op_funct_out2;
                end

                rvfi_signals <= '0;
                mem_op_funct_out <= '0;
            end else begin
                rvfi_signals <= '0;
                mem_op_funct_out <= '0;

                rvfi_signals2 <= rvfi_signals2;
                mem_op_funct_out2 <= mem_op_funct_out2;
            end
         

        end else begin
            rvfi_signals <= '0;
            mem_op_funct_out <= '0;

            rvfi_signals2 <= rvfi_signals2;
            mem_op_funct_out2 <= mem_op_funct_out2;
        end
    end


    always_ff@(posedge clk) begin
        if (rst || rob_flush) begin
            branch_ready_commit_flag <= 1'b0;
            jump_ready_commit_flag <= 1'b0;
        end
        else if(((mem_op_reg.mem_op_type == auipc_entry) || (mem_op_reg.mem_op_type == jal_entry) || (mem_op_reg.mem_op_type == jalr_entry)) && !control_flag) begin
            branch_ready_commit_flag <= 1'b0;
            jump_ready_commit_flag <= 1'b1;
        end
        else if(mem_op_reg.mem_op_type == branch_entry) begin
            branch_ready_commit_flag <= 1'b1;
            jump_ready_commit_flag <= 1'b0;
        end else begin
            branch_ready_commit_flag <= 1'b0;
            jump_ready_commit_flag <= 1'b0;
        end
    end


    //ASSIGNING RVFI SIGNALS
    always_comb begin
        rvfi_signals_next.rs1_rdata = mem_op_reg.rs1_v;
        rvfi_signals_next.rs2_rdata = mem_op_reg.rs2_v;

        if ((mem_op_reg.mem_op_type == jal_entry) || (mem_op_reg.mem_op_type == jalr_entry)) begin
            rvfi_signals_next.rd_wdata = mem_op_reg.pc_in + 'd4;
        end else if (mem_op_reg.mem_op_type == auipc_entry) begin
            rvfi_signals_next.rd_wdata = mem_op_reg.pc_new;
        end else begin
            rvfi_signals_next.rd_wdata = '0;
        end

        if (mem_op_reg.mem_op_type == auipc_entry) begin
            rvfi_signals_next.pc_wdata = mem_op_reg.pc_in + 'd4;
        end else if ((mem_op_reg.mem_op_type == jal_entry) || (mem_op_reg.mem_op_type == jalr_entry)) begin
            rvfi_signals_next.pc_wdata = mem_op_reg.pc_new;
        end else if (mem_op_reg.mem_op_type == branch_entry) begin
            if (mem_op_reg.br_en) begin
                rvfi_signals_next.pc_wdata = mem_op_reg.pc_new;
            end else begin
                rvfi_signals_next.pc_wdata = mem_op_reg.pc_in + 'd4;
            end
        end else begin
            rvfi_signals_next.pc_wdata = '0;
        end
        rvfi_signals_next.mem_addr  = '0;
        rvfi_signals_next.mem_rmask = '0;
        rvfi_signals_next.mem_wmask = '0;
        rvfi_signals_next.mem_rdata = '0;
        rvfi_signals_next.mem_wdata = '0;
    end

    assign  funct_unit_out_control.pd = mem_op_funct_out2.pd;
    assign  funct_unit_out_control.rd = mem_op_funct_out2.rd;
    assign  funct_unit_out_control.ready_commit = mem_op_funct_out2.commit && mem_op_funct_out2.valid;
    assign  funct_unit_out_control.funct_unit_out = rvfi_signals2.rd_wdata;
    assign  funct_unit_out_control.rob_idx = mem_op_funct_out2.rob_idx;
    assign  funct_unit_out_control.rvfi_data = rvfi_signals2;


    assign  control_out.pd = mem_op_funct_out.pd;
    assign  control_out.rd = mem_op_funct_out.rd;
    assign  control_out.ready_commit = mem_op_funct_out.commit && mem_op_funct_out.valid;
    assign  control_out.data = {31'd0, mem_op_funct_out.br_en};
    assign  control_out.rob_idx = mem_op_funct_out.rob_idx;
    assign  control_out.rvfi_data_out = rvfi_signals;


endmodule
