package params;
    localparam BURST_SIZE = 64;

    // INSTRUCTION QUEUE PARAMETERS
    localparam QUEUE_DEPTH = 8;
    localparam QUEUE_WIDTH = 32;

    // PHYSICAL REGISTERS
    localparam NUM_PHYS_REG = 64;
    localparam BITS_PHYS_REG = $clog2(NUM_PHYS_REG) - 1;
    
    //ROB DEPTH
    localparam ROB_DEPTH = 16;
    localparam BITS_ROB_DEPTH = $clog2(ROB_DEPTH) - 1;
    
    localparam RESERVATION_STATION_SIZE = 8;
    localparam NUM_RESERVATION_STATIONS = 1;
    localparam NUM_FUNCT_UNITS = 3;

    localparam LOG_ROB_DEPTH = $clog2(ROB_DEPTH);

    // PARAMS FOR MULT AND DIV IPs
    localparam INST_A_WIDTH = 32;
    localparam INST_B_WIDTH = 32;
    localparam INST_TC_MODE = 0;
    localparam INST_NUM_CYCLES = 5;
    localparam INST_DIV_NUM_CYCLES = 9;
    localparam INST_RST_MODE = 0;
    localparam INST_INPUT_MODE = 1;
    localparam INST_OUTPUT_MODE = 1;
    localparam INST_EARLY_START = 0;
    
    //QUEUE DEPTHS
    localparam LS_QUEUE_DEPTH = 4;
    localparam LOG_QUEUE_DEPTH = $clog2(LS_QUEUE_DEPTH);  //-1 done inside control_queue.sv
    localparam LOG_FREE_LIST_DEPTH = $clog2(NUM_PHYS_REG - 32);
    localparam LOG_FREE_LIST_WIDTH = $clog2(NUM_PHYS_REG);

    //BRANCH PREDICTOR
    localparam GLOBAL_HISTORY_LEN = 4;
    localparam PC_IDX_LEN = 4;
    localparam PATTERN_HISTORY_LEN = GLOBAL_HISTORY_LEN + PC_IDX_LEN;
endpackage

package rv32i_types;
import params::*;

    typedef struct packed {
        logic           valid;
        logic [63:0]    order;
        logic [31:0]    inst;
        logic [4:0]     rs1_addr;
        logic [4:0]     rs2_addr;
        logic [31:0]    rs1_rdata;
        logic [31:0]    rs2_rdata;
        logic [4:0]     rd_addr;
        logic [31:0]    rd_wdata;
        // logic frd_addr;
        // logic frd_wdata;
        logic [31:0]    pc_rdata;
        logic [31:0]    pc_wdata;
        logic [31:0]    mem_addr;
        logic [3:0]     mem_rmask;
        logic [3:0]     mem_wmask;
        logic [31:0]    mem_rdata;
        logic [31:0]    mem_wdata;
    } rvfi_signals_t;

    typedef struct packed {
        logic [31:0] rs1_rdata;
        logic [31:0] rs2_rdata;
        logic [31:0] rd_wdata;
        logic [31:0] pc_wdata;

        //LOAD STORE VALUES
        logic [31:0] mem_addr;
        logic [3:0]  mem_rmask;
        logic [3:0]  mem_wmask;
        logic [31:0] mem_rdata;
        logic [31:0] mem_wdata;
    } register_t;

    typedef struct packed {
        logic [31:0] cpu_addr;
        logic [3:0]  cpu_rmask;
        logic [3:0]  cpu_wmask;
        logic [31:0] cpu_wdata;

        logic [22:0] cpu_addr_tag;
        logic [3:0]  cpu_addr_set;
        logic [2:0]  cpu_addr_block;
    } cpu_signals_t;

    // typedef enum logic { 
    //     cpu_to_cache = 1'b0,
    //     mem_to_cache = 1'b1
    // } mask_mux_t;

    // typedef enum logic { 
    //     cpu_to_cache_offset = 1'b0,
    //     mem_to_cache_block = 1'b1
    // } wdata_mux_t;

    typedef enum logic [2:0] {
        alu = 3'b000,
        mult = 3'b001,
        divide_rem = 3'b010,
        control = 3'b011,
        load_store = 3'b100
    } funct_unit_t;


    typedef enum logic { 
        update_cache_cpu = 1'b0,
        update_cache_mem = 1'b1
    } cache_signals_mux_t;

     typedef enum logic [2:0] { 
        imm_entry = 3'b000,
        reg_entry = 3'b001,
        lui_entry = 3'b010,
        store_entry = 3'b011,
        auipc_entry = 3'b100,
        jal_entry = 3'b101,
        jalr_entry = 3'b110,
        branch_entry = 3'b111
     } imm_reg_mux_t;

    typedef struct packed {
        logic               valid;
        logic   [31:0]      inst;
        logic   [6:0]       opcode;
        logic   [6:0]       funct7;
        logic   [2:0]       funct3;
        funct_unit_t        inst_type;
        logic   [31:0]      inst_imm;
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;
        logic   [4:0]       rd_s;
        imm_reg_mux_t       imm_reg_mux;
    } inst_breakdown_t;

    typedef struct packed{
        logic   [31:0]      inst;
        logic   [31:0]      inst_pc;
        logic   [PATTERN_HISTORY_LEN - 1:0]      branch_pht_idx;
        logic   [1:0]       branch_pht_prediction;
    } inst_queue_t;

    //RAT STRUCT
    typedef struct packed {
        logic                           valid;
        logic   [BITS_PHYS_REG:0]       pd;  
    } rat_entry_t;

    //RESERVATION STATION STRUCT
    typedef struct packed {
        logic                           valid;
        funct_unit_t                    funct_unit;
        logic                           ps1_valid;
        logic   [BITS_PHYS_REG:0]       ps1;
        logic                           ps2_valid;
        logic   [31:0]                  ps2;
        logic   [BITS_PHYS_REG:0]       pd;
        logic   [4:0]                   rd_s;
        logic   [BITS_ROB_DEPTH:0]      rob_idx;
        imm_reg_mux_t                   imm_reg_mux;
        logic   [6:0]                   opcode;
        logic   [2:0]                   funct3;
        logic   [6:0]                   funct7;
        logic   [4:0]                   rs1_s;
        logic   [4:0]                   rs2_s;
        logic   [31:0]                  pc;
        register_t                      rvfi_data;
    } res_station_entry_t;

    typedef enum logic { 
        empty = 1'b0,
        filled = 1'b1
     } res_station_status_t;

    typedef enum logic [2:0] {WAIT, REQUEST_PREFETCH, BURSTING, PREFETCH_BURSTING, WRITING, DONE} state_t;


    typedef struct packed {
        res_station_status_t  status;
        res_station_entry_t   res_station_entry;
    } res_station_t;

    //ROB ENTRY STRUCT
    typedef struct packed {
        //logic   [2:0]   rob_idx;
        logic                                  commit;
        logic   [BITS_PHYS_REG:0]              pd;
        logic   [4:0]                          rd;
        logic                                  br_en;
        logic   [1:0]                          prediction_val;
        logic   [PATTERN_HISTORY_LEN - 1:0]    pht_idx;
        rvfi_signals_t                         rvfi_signals;
    } rob_entry_t;

    //FUNCTIONAL UNITS STRUCT
    typedef struct packed {
        logic   [BITS_PHYS_REG:0]    pd;
        logic   [4:0]                rd;
        logic                        ready_commit;
        logic   [31:0]               funct_unit_out;
        logic   [BITS_ROB_DEPTH:0]   rob_idx;
        register_t                   rvfi_data;
    } funct_unit_out_t;


    // typedef struct packed {
        
    //     logic   [BITS_PHYS_REG:0]   pd;
    //     logic   [4:0]   rd;
    //     logic           ready_commit;
    //     // logic   [31:0]  funct_unit_out;
    //     logic   [2:0]   rob_idx;

    //     logic   [3:0]   write_mask;
    //     logic   [3:0]   read_mask;
    //     logic   [31:0]  mem_addr;
    //     logic   [31:0]  mem_wdata;
        
    //     register_t      rvfi_data;

    // } load_store_funct_t;

    typedef struct packed {
        logic   [BITS_PHYS_REG:0]    pd;
        logic   [4:0]                rd;
        logic                        ready_commit;
        logic   [31:0]               data;
        logic   [BITS_ROB_DEPTH:0]   rob_idx;
        register_t                   rvfi_data_out;
    } cdb_out_t;

    typedef struct packed {
        //logic   [2:0]   rob_idx;
        logic   [BITS_PHYS_REG:0]   pd;
        logic   [4:0]               rd;
        logic                       regf_wb;
    } rrf_entry_t;


    //ls_queue struct
    typedef struct packed {
        logic                        valid;
        logic                        addr_valid;
        logic   [BITS_ROB_DEPTH:0]   rob_idx;
        logic   [3:0]                wmask;
        logic   [3:0]                rmask;
        logic   [31:0]               mem_addr;
        logic   [31:0]               mem_wdata;
        imm_reg_mux_t                mem_op_type;
        logic   [4:0]                rd;
        logic   [BITS_PHYS_REG:0]    pd;
        logic   [2:0]                funct3;
        logic   [31:0]               rs1_v;
        logic   [31:0]               rs2_v;
        logic   [31:0]               pc;
    } mem_op_t;

    typedef struct packed {
        logic                        addr_valid;
        logic   [BITS_ROB_DEPTH:0]   rob_idx;
        logic   [3:0]                wmask;
        logic   [3:0]                rmask;
        logic   [31:0]               mem_addr;
        logic   [31:0]               mem_wdata;
        logic   [31:0]               rs1_v;
        logic   [31:0]               rs2_v;
    } mem_update_t;

    //control_queue struct
    typedef struct packed {
        logic                        valid;
        logic                        pc_valid;
        logic   [BITS_ROB_DEPTH:0]   rob_idx;
        logic   [31:0]               pc_in;
        logic   [31:0]               pc_new;
        logic                        br_en;
        imm_reg_mux_t                mem_op_type;
        logic   [4:0]                rd;
        logic   [BITS_PHYS_REG:0]    pd;
        logic   [2:0]                funct3;
        logic   [31:0]               rs1_v;
        logic   [31:0]               rs2_v;
    } mem_op_control_t;

        //control_queue struct
    typedef struct packed {
        logic                        valid;
        logic                        pc_valid;
        logic                        commit;
        logic   [BITS_ROB_DEPTH:0]   rob_idx;
        logic   [31:0]               pc_in;
        logic   [31:0]               pc_new;
        logic                        br_en;
        imm_reg_mux_t                mem_op_type;
        logic   [4:0]                rd;
        logic   [BITS_PHYS_REG:0]    pd;
        logic   [2:0]                funct3;
        logic   [31:0]               rs1_v;
        logic   [31:0]               rs2_v;
    } mem_op_funct_out_t;

    //control_queue struct
    typedef struct packed {
        logic                        valid;
        logic                        pc_valid;
        logic   [BITS_ROB_DEPTH:0]   rob_idx;
        logic   [31:0]               pc_new;
        logic                        br_en;
        logic   [31:0]               rs1_v;
        logic   [31:0]               rs2_v;
    } mem_update_control_t;

    typedef enum  logic { INSTRUCTION, DATA } cache_state_t;



    typedef enum logic [6:0] {
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
    } arith_f3_t;

    typedef enum logic [2:0] {
        alu_op_add     = 3'b000,
        alu_op_sll     = 3'b001,
        alu_op_sra     = 3'b010,
        alu_op_sub     = 3'b011,
        alu_op_xor     = 3'b100,
        alu_op_srl     = 3'b101,
        alu_op_or      = 3'b110,
        alu_op_and     = 3'b111
    } alu_ops;

    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;

    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;


   typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;

    typedef enum logic [6:0] {
        base           = 7'b0000000,
        variant        = 7'b0100000,
        extension      = 7'b0000001  // NEW!addr_valid
    } funct7_t;

    
    typedef union packed {
        logic [31:0] word;

        struct packed {
            logic [11:0] i_imm;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } i_type;

        struct packed {
            logic [6:0]  funct7;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } r_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } j_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } u_type;

    } instr_t;


    typedef struct packed {
        logic   [31:0] addr;
        logic   [23:0] tag;
        logic   [3:0]  index;
        logic   [4:0]  offset;
        logic   [3:0]  ufp_rmask; 
        logic   [3:0]  ufp_wmask;
        logic   [31:0] ufp_wdata;
        logic          write_flag;  
        logic          write_flag_ufp;
        logic   [31:0] next_addr;
        logic   [23:0] next_tag;
        logic   [3:0]  next_index;
        logic   [4:0]  next_offset;
        logic   [3:0]  next_ufp_rmask; 
        logic   [3:0]  next_ufp_wmask;
        logic   [31:0] next_ufp_wdata;
        logic              dirty_flag;
    } stage_reg_t;

endpackage
