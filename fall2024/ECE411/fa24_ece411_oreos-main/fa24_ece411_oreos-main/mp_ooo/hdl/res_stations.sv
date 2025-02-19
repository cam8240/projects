module res_stations
import rv32i_types::*;
import params::*;
(
    input   logic                                       clk,
    input   logic                                       rst,

    // reservation station <-> adapter
    input   res_station_entry_t                         res_station_in,
    output  logic                                       res_station_full,
    input   funct_unit_t                                funct_unit_key,
    input   logic                                       funct_unit_ready,

    output   logic   [2:0]                              funct3_out,
    output   logic   [6:0]                              funct7_out,
    output   imm_reg_mux_t                              imm_reg_mux_out,
    output   logic   [$clog2(NUM_PHYS_REG) - 1:0]       pd_out,
    output   logic   [4:0]                              rd_out,
    output   logic                                      valid_out,

    // reservation station <-> physical register/functional unit
    output  logic    [$clog2(NUM_PHYS_REG) - 1:0]       ps1_out,
    output  logic    [$clog2(NUM_PHYS_REG) - 1:0]       ps2_out,
    output  logic    [31:0]                             imm_out,
    output  imm_reg_mux_t                               ps2_type,
    output  logic                                       valid_read_flag,
    output  logic    [$clog2(ROB_DEPTH) - 1:0]          rob_idx_out,
    output  logic    [4:0]                              rs1_out,
    output  logic    [4:0]                              rs2_out,
    output  logic    [31:0]                             pc_out,

    //reservation station <-> CDB
    input   logic    [$clog2(NUM_PHYS_REG) - 1:0]       pd_cdb,
    input   logic                                       ready_commit_cdb,
    input   logic                                       rob_flush
);


    res_station_t  res_station[RESERVATION_STATION_SIZE];
    logic          remove_entry_flag_next[RESERVATION_STATION_SIZE];
    logic          remove_entry_flag[RESERVATION_STATION_SIZE];

    res_station_entry_t res_station_new;

    always_comb begin
        res_station_new = res_station_in;
        if (ready_commit_cdb) begin
            if (pd_cdb !=  res_station_in.ps1) begin
                res_station_new.ps1_valid = res_station_in.ps1_valid; 
            end else begin 
                res_station_new.ps1_valid = '1;
            end

            if ({ {(31 - BITS_PHYS_REG){1'b0}}, pd_cdb } !=  res_station_in.ps2) begin
                res_station_new.ps2_valid = res_station_in.ps2_valid; 
            end else begin
                res_station_new.ps2_valid = '1;
            end
        end else begin
            res_station_new.ps1_valid = res_station_in.ps1_valid; 
            res_station_new.ps2_valid = res_station_in.ps2_valid; 
        end

    end


    // WRITE TO EMPTY RESERVATION STATION ENTRY
    always_ff @(posedge clk) begin
        // CLEAR RESERVATION STATIONS IF EMPTY
        if(rst || rob_flush) begin
            remove_entry_flag <= '{default: '0};
            for(int i = 0; i < RESERVATION_STATION_SIZE; i++) begin
                res_station[i].status <= empty;
                res_station[i].res_station_entry <= '0;
            end
        end
        
        else begin
            remove_entry_flag <= remove_entry_flag_next;
            //UPDATING RESERVATION STATION
            for(int i = 0; i < RESERVATION_STATION_SIZE; i++) begin
                //fill reservation station if empty
                if(res_station[i].status == empty && res_station_new.valid && res_station_new.funct_unit == funct_unit_key) begin
                    res_station[i].status <= filled;
                    res_station[i].res_station_entry <= res_station_new;
                    break;
                end
            end
            for(int i = 0; i < RESERVATION_STATION_SIZE; i++) begin
                if(remove_entry_flag_next[i] == 1'b1) begin
                    res_station[i].status <= empty;
                    break;
                end
            end
            for(int i = 0; i < RESERVATION_STATION_SIZE; i++) begin
                //update physical register 1
                if(res_station[i].status == filled && res_station[i].res_station_entry.ps1_valid == 1'b0 && 
                    res_station[i].res_station_entry.ps1 == pd_cdb && ready_commit_cdb) begin
                        res_station[i].res_station_entry.ps1_valid <= 1'b1;
                end

                //update physical register 2
                if(res_station[i].status == filled && res_station[i].res_station_entry.ps2_valid == 1'b0 && 
                    (((res_station[i].res_station_entry.ps2[$clog2(NUM_PHYS_REG) - 1:0] == pd_cdb) &&  !((res_station[i].res_station_entry.imm_reg_mux == store_entry) || (res_station[i].res_station_entry.imm_reg_mux == branch_entry))) || 
                    ((pd_cdb ==  res_station[i].res_station_entry.ps2[31:(31 - BITS_PHYS_REG)]) && ((res_station[i].res_station_entry.imm_reg_mux == store_entry) || (res_station[i].res_station_entry.imm_reg_mux == branch_entry)))) && 
                    ready_commit_cdb) begin
                        res_station[i].res_station_entry.ps2_valid <= 1'b1;
                end
            end
        end
    end

    //CHECK IF RESERVATION STATION IS FULL
    always_comb begin
        res_station_full = 1'b1;
        for(int i = 0; i < RESERVATION_STATION_SIZE; i++) begin
            if(res_station[i].status == empty) begin
                res_station_full = 1'b0;
                break;
            end
        end
    end

    //SEND VALID RESERVATION STATION ENTRY TO FUNCTIONAL UNIT
    always_comb begin
        remove_entry_flag_next = '{default: '0};
        valid_read_flag = '0;
        ps1_out = '0;
        ps2_out = '0;
        imm_out = '0;
        ps2_type = reg_entry;
        funct3_out = '0;
        funct7_out = '0;
        imm_reg_mux_out = reg_entry;
        pd_out = '0;
        rd_out = '0;
        valid_out = '0;
        rob_idx_out = '0;
        rs1_out = '0;
        rs2_out = '0;
        pc_out = '0;
        for(int i = 0; i < RESERVATION_STATION_SIZE; i++) begin
            
            if(res_station[i].status == filled && res_station[i].res_station_entry.valid && res_station[i].res_station_entry.ps1_valid 
            && res_station[i].res_station_entry.ps2_valid && funct_unit_ready) begin

                ps1_out = res_station[i].res_station_entry.ps1;
                ps2_out = res_station[i].res_station_entry.ps2[5:0];

                rs1_out = res_station[i].res_station_entry.rs1_s;
                rs2_out = res_station[i].res_station_entry.rs2_s;

                //PS2 LOCATED IN MSBs for STORES
                if((res_station[i].res_station_entry.imm_reg_mux == store_entry) || (res_station[i].res_station_entry.imm_reg_mux == branch_entry)) begin
                    ps2_out = res_station[i].res_station_entry.ps2[31:26];
                end

                imm_out = res_station[i].res_station_entry.ps2;
                
                //CONVERT BACK TO S_IMM TYPE FOR STORES
                if((res_station[i].res_station_entry.imm_reg_mux == store_entry) || (res_station[i].res_station_entry.imm_reg_mux == branch_entry)) begin
                    imm_out = { {($clog2(NUM_PHYS_REG)){res_station[i].res_station_entry.ps2[31 - ($clog2(NUM_PHYS_REG))]  }}, res_station[i].res_station_entry.ps2[31 - ($clog2(NUM_PHYS_REG)):0]};
                end

                ps2_type = res_station[i].res_station_entry.imm_reg_mux;
                remove_entry_flag_next[i] = 1'b1;
                valid_read_flag = 1'b1;

                funct3_out = res_station[i].res_station_entry.funct3;
                funct7_out= res_station[i].res_station_entry.funct7;
                imm_reg_mux_out = res_station[i].res_station_entry.imm_reg_mux;

                pd_out = res_station[i].res_station_entry.pd;
                rd_out = res_station[i].res_station_entry.rd_s;

                if((res_station[i].res_station_entry.imm_reg_mux == store_entry) || (res_station[i].res_station_entry.imm_reg_mux == branch_entry)) begin
                    pd_out = '0;
                    rd_out = '0;
                end
                
                valid_out = res_station[i].res_station_entry.valid;
                rob_idx_out = res_station[i].res_station_entry.rob_idx;
                pc_out = res_station[i].res_station_entry.pc;
                break;
            end
        end
    end
    

endmodule : res_stations
