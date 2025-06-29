module cacheline_adapter 
import rv32i_types::*; 
import params::*;
(
    input   logic               clk,
    input   logic               rst,

    input   logic               bmem_ready, // input from dram when ready to send data
    input   logic   [31:0]      bmem_raddr, // response address from memory
    input   logic   [63:0]      bmem_rdata, // data that comes from dram
    input   logic               bmem_rvalid, // coming from cache when ready to read

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,

    input   logic               i_cache_read, // input from cache that data should be read
    input   logic   [31:0]      i_cache_addr, // input address from cache
    input   logic   [255:0]     i_cache_wdata,
    input   logic               i_cache_write,

    output  logic   [255:0]     burst_line, // data being sent to cache
    output  logic               cacheline_resp, // mem response
    output  state_t             state_out,
    input   cache_state_t       cache_state
);


    logic [1:0] burst_counter, prefetch_burst_counter, write_counter;

    state_t state, next_state;

    logic bmem_ready_latched, skip_bursting_reg, special_case_done;
    logic valid_prefetch, skip_bursting;

// New logic for prefetch
    logic [31:0] prefetch_addr, addr_next, addr_next_reg;
    logic [255:0] prefetch_buffer;
    logic prefetch_valid;

    assign state_out = next_state;

    always_comb begin
        addr_next = i_cache_addr;
        if ((state == BURSTING) && (cache_state == INSTRUCTION)) begin
            if (bmem_rvalid && (bmem_raddr == prefetch_addr) && (bmem_addr != prefetch_addr)) begin
                addr_next = i_cache_addr + 32;
            end
        end else if ((state == PREFETCH_BURSTING) && (cache_state == INSTRUCTION))begin
            if (bmem_rvalid && (bmem_raddr == prefetch_addr)) begin
                addr_next = i_cache_addr + 32;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            addr_next_reg <= '0;
        end else if ((cache_state == INSTRUCTION))begin
            if (valid_prefetch) begin
                addr_next_reg <= prefetch_addr;
            end            
        end else begin
            addr_next_reg <= addr_next_reg;
        end
    end



    always_ff @(posedge clk) begin
        if (rst) begin
            state <= WAIT;
        end else begin
            state <= next_state;
        end
        if (rst) begin
            burst_line <= 256'b0;
            burst_counter <= 2'b0;
            prefetch_burst_counter <= 2'b0;
            write_counter <= '0;
            prefetch_buffer <= 256'b0;
            prefetch_valid <= 1'b0;
            valid_prefetch <= 1'b0;
            skip_bursting <= 1'b0;
            special_case_done <= 1'b0;
        end else begin
            if (state == BURSTING) begin
                if (bmem_rvalid && (bmem_raddr == bmem_addr)) begin
                    burst_line[burst_counter * BURST_SIZE +: BURST_SIZE] <= bmem_rdata;
                    if (burst_counter != 2'b11) begin
                        burst_counter <= burst_counter + 2'b01;
                    end
                    prefetch_burst_counter <= prefetch_burst_counter;
                end
                if (bmem_rvalid && (bmem_raddr == prefetch_addr) && (bmem_addr != prefetch_addr)) begin
                    prefetch_buffer[prefetch_burst_counter * BURST_SIZE +: BURST_SIZE] <= bmem_rdata;
                    if (prefetch_burst_counter != 2'b11) begin
                        prefetch_burst_counter <= prefetch_burst_counter + 2'b01;
                    end
                    burst_counter <= burst_counter;
                    prefetch_valid <= 1'b1;
                    state <= PREFETCH_BURSTING;
                end
            end
            else if (state == PREFETCH_BURSTING) begin
                if ((bmem_rvalid && (bmem_raddr == prefetch_addr)) || (bmem_rvalid && skip_bursting) || (bmem_rvalid && special_case_done)) begin
                    prefetch_buffer[prefetch_burst_counter * BURST_SIZE +: BURST_SIZE] <= bmem_rdata;
                    if (prefetch_burst_counter != 2'b11) begin
                        prefetch_burst_counter <= prefetch_burst_counter + 2'b01;
                    end
                    burst_counter <= burst_counter;
                    prefetch_valid <= 1'b1;
                end
                if ((skip_bursting == 1'b1) && prefetch_burst_counter == 2'b11) begin
                    skip_bursting <= 1'b0;
                end
                if ((special_case_done == 1'b1) && prefetch_burst_counter == 2'b11) begin
                    special_case_done <= 1'b0;
                end
            end
            else if (state == WRITING) begin
                write_counter <= write_counter + 2'b01;
            end else if (state == DONE) begin
                burst_counter <= 2'b0;
                prefetch_burst_counter <= 2'b0;
                if (i_cache_read && prefetch_valid && (i_cache_addr == addr_next_reg) && skip_bursting_reg) begin
                    special_case_done <= 1'b1;
                end
            end else if (state == REQUEST_PREFETCH) begin
                prefetch_valid <= 1'b0;
                if (valid_prefetch) begin
                    skip_bursting <= 1'b1;
                end
            end else begin
                write_counter <= '0;
            end

            valid_prefetch <= 1'b0;
            // Prefetch buffer usage
            if (i_cache_read && prefetch_valid && (i_cache_addr == addr_next_reg)
             && ((state == WAIT) || ((state == DONE) && skip_bursting_reg) || ((state == PREFETCH_BURSTING) && special_case_done)) && (cache_state == INSTRUCTION)) begin
                burst_line <= prefetch_buffer;
                prefetch_valid <= 1'b0;
                valid_prefetch <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            bmem_ready_latched <= '0;
            skip_bursting_reg <= '0;
        end else begin
            bmem_ready_latched <= bmem_ready;
            skip_bursting_reg <= skip_bursting;
        end
    end
    logic test;
    always_comb begin
        bmem_addr = '0;
        bmem_read = 1'b0;
        bmem_write = '0;
        cacheline_resp = 1'b0;
        bmem_wdata = '0;
        prefetch_addr = i_cache_addr + 32;
        next_state = state;
        case(state)
            WAIT : begin
                cacheline_resp = 1'b0;
                if(bmem_ready_latched && i_cache_read) begin
                    bmem_addr = i_cache_addr;
                    bmem_read = 1'b1;
                    prefetch_addr = i_cache_addr + 32;
                    next_state = REQUEST_PREFETCH;
                    if (cache_state == DATA) begin
                        next_state = BURSTING;
                    end
                end
                if((bmem_ready_latched && i_cache_write) && (cache_state == DATA)) begin
                    bmem_addr = i_cache_addr;
                    next_state = WRITING;
                end
                if ((cache_state == INSTRUCTION) && i_cache_read && prefetch_valid && (i_cache_addr == addr_next_reg)
                 && ((state == WAIT) || ((state == DONE) && skip_bursting_reg) || ((state == PREFETCH_BURSTING) && special_case_done))) begin
                    bmem_read = 1'b0;
                    next_state = REQUEST_PREFETCH;
                end
                if (valid_prefetch && (cache_state == INSTRUCTION)) begin
                    cacheline_resp = 1'b1;
                    bmem_read = 1'b0;
                    next_state = REQUEST_PREFETCH;
                end
            end
            REQUEST_PREFETCH : begin
                bmem_addr = prefetch_addr;
                bmem_read = 1'b1;
                next_state = BURSTING;
                if (valid_prefetch && (cache_state == INSTRUCTION)) begin
                    cacheline_resp = 1'b1;
                    next_state = PREFETCH_BURSTING;
                end
                if (special_case_done && (cache_state == INSTRUCTION)) begin
                    next_state = PREFETCH_BURSTING;
                end
            end
            BURSTING : begin
                bmem_addr = i_cache_addr;
                if(((burst_counter == 2'b11) && (prefetch_burst_counter == 2'b11)) || ((burst_counter == 2'b11) && (cache_state == DATA))) begin
                    next_state = DONE;
                end
                else if(burst_counter == 2'b11) begin
                    next_state = PREFETCH_BURSTING;
                end
            end
            PREFETCH_BURSTING : begin
                bmem_addr = prefetch_addr;
                if(((burst_counter == 2'b11) && (prefetch_burst_counter == 2'b11)) 
                || (((special_case_done == 1'b1) || (skip_bursting == 1'b1)) && prefetch_burst_counter == 2'b11) && (cache_state == INSTRUCTION)) begin
                    next_state = DONE;
                end
                else if(prefetch_burst_counter == 2'b11) begin
                    next_state = BURSTING;
                end
            end
            WRITING : begin
                bmem_addr = i_cache_addr;
                bmem_write = 1'b1;
                bmem_wdata = i_cache_wdata[write_counter * BURST_SIZE +: BURST_SIZE];
                if(write_counter == 2'b11) begin
                    next_state = DONE;
                end
            end
            DONE : begin
                bmem_read = 1'b0;
                bmem_write = 1'b0;
                cacheline_resp = 1'b1;
                if (i_cache_read && prefetch_valid && (i_cache_addr == addr_next_reg) && skip_bursting_reg && (cache_state == INSTRUCTION)) begin
                    cacheline_resp = 1'b0;
                end
                next_state = WAIT;
            end
            default begin
                next_state = WAIT;
            end
        endcase
    end

endmodule : cacheline_adapter