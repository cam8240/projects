module top_tb
(
    input   logic   clk,
    input   logic   rst
);

    longint timeout;
    initial begin
        $value$plusargs("TIMEOUT_ECE411=%d", timeout);
    end

    mem_itf_banked mem_itf(.*);
    dram_w_burst_frfcfs_controller mem(.itf(mem_itf));

    mon_itf #(.CHANNELS(8)) mon_itf(.*);
    monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));

    logic dequeue_test_flag;
    logic is_full_flag;
    logic is_empty_flag;

    logic valid_out;
    logic            stall_from_dispatch;

    logic dequeue_free_list;
    logic   [5:0] avail_phys_reg;
    logic          free_list_empty;
    logic       enqueue_phys_reg;
    logic    [5:0]   freed_phys_reg;

    logic            res_station_full;
    // logic    [2:0]   rob_idx;
    // logic            rob_full;
    logic                   ready_commit;
    logic       [2:0]       rob_idx_cdb;

    cpu dut(
        .clk            (clk),
        .rst            (rst),

        .bmem_addr  (mem_itf.addr  ),
        .bmem_read  (mem_itf.read  ),
        .bmem_write (mem_itf.write ),
        .bmem_wdata (mem_itf.wdata ),
        .bmem_ready (mem_itf.ready ),
        .bmem_raddr (mem_itf.raddr ),
        .bmem_rdata (mem_itf.rdata ),
        .bmem_rvalid(mem_itf.rvalid)

        // // .dequeue_test_flag(dequeue_test_flag),
        // .is_full_flag(is_full_flag),
        // .is_empty_flag(is_empty_flag),
        // // .stall_from_dispatch(dequeue_test_flag),

        // //testing free list
        // // .dequeue_free_list(dequeue_free_list),
        // .avail_phys_reg(avail_phys_reg),
        // .free_list_empty(free_list_empty),
        // .enqueue_phys_reg(enqueue_phys_reg),
        // .freed_phys_reg(freed_phys_reg),
    
        // .res_station_full(res_station_full),

        // //dispatch <-> ROB
        // // .rob_idx(rob_idx),
        // // .rob_full(rob_full)   
        // // .rob_enqueue(1'b1)

        // .ready_commit_in(ready_commit),
        // .rob_idx_cdb_in(rob_idx_cdb)
        
    );

    `include "rvfi_reference.svh"

    initial begin
        `ifdef ECE411_FST_DUMP
            $dumpfile("dump.fst");
        `endif
        `ifdef ECE411_VCD_DUMP
            $dumpfile("dump.vcd");
        `endif
        $dumpvars();
        if ($test$plusargs("NO_DUMP_ALL_ECE411")) begin
            $dumpvars(0, dut);
            $dumpoff();
        end else begin
            $dumpvars();
        end
    end

    final begin
        $dumpflush;
    end

    always @(posedge clk) begin
        for (int unsigned i = 0; i < 8; ++i) begin
            if (mon_itf.halt[i]) begin
                $finish;
            end
        end
        if (timeout == 0) begin
            $error("TB Error: Timed out");
            $fatal;
        end
        if (mon_itf.error != 0) begin
            $fatal;
        end
        if (mem_itf.error != 0) begin
            $fatal;
        end
        timeout <= timeout - 1;
    end

endmodule
