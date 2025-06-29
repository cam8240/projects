module top_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps;
    initial begin
        $value$plusargs("CLOCK_PERIOD_PS_ECE411=%d", clock_half_period_ps);
        clock_half_period_ps = clock_half_period_ps / 2;
    end

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    bit rst;

    int timeout = 100000000; // in cycles, change according to your needs

    logic dequeue_test_flag;
    logic is_full_flag;
    logic is_empty_flag;

    assign is_full_flag = 1'b1;
    assign is_empty_flag = 1'b1;

    logic valid_out;
    logic            stall_from_dispatch;

    logic dequeue_free_list;
    logic   [5:0] avail_phys_reg;
    logic          free_list_empty;
    logic       enqueue_phys_reg;
    logic    [5:0]   freed_phys_reg;

    // logic    [2:0]   rob_idx;
    // logic            rob_full;
    logic                   ready_commit;
    logic       [2:0]       rob_idx_cdb;

    mem_itf_banked mem_itf(.*);
    dram_w_burst_frfcfs_controller mem(.itf(mem_itf));

    //random_tb random_tb(.itf(mem_itf));

    mon_itf #(.CHANNELS(8)) mon_itf(.*);
    monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));

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

        // .dequeue_test_flag(dequeue_test_flag),
        // .is_full_flag(is_full_flag),
        // .is_empty_flag(is_empty_flag),
        // // .stall_from_dispatch(dequeue_test_flag),

        // //testing free list
        // // .dequeue_free_list(dequeue_free_list),
        // .avail_phys_reg(avail_phys_reg),
        // .free_list_empty(free_list_empty),
        // .enqueue_phys_reg(enqueue_phys_reg),
        // .freed_phys_reg(freed_phys_reg),
    
        // //dispatch <-> ROB
        // // .rob_idx(rob_idx),
        // // .rob_full(rob_full)   
        // // .rob_enqueue(1'b1)

        // .ready_commit_in(ready_commit),
        // .rob_idx_cdb_in(rob_idx_cdb)
        
    );

    `include "rvfi_reference.svh"

    initial begin
        $fsdbDumpfile("dump.fsdb");
        if ($test$plusargs("NO_DUMP_ALL_ECE411")) begin
            $fsdbDumpvars(0, dut, "+all");
            $fsdbDumpoff();
        end else begin
            $fsdbDumpvars(0, "+all");
        end
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;


        // repeat (1000) @(posedge clk);

        //dequeue_test_flag <= 1'b0;

        // Test 1 - Basic fill queue
        //fill_queue();

        // Test 2 - Dequeue from empty queue
        // dequeue_empty();

        // Test - Fill queue then test dequeue
        // dequeue_full();


        //TEST free_list
        //test_free_list_init();

        //TEST dispatch-rat-free_list
        //test_dispatch();

        //TEST dispatch_rob
        //test_dispatch_rob();
        
    end

    task fill_queue;
        wait(is_full_flag);
        repeat (4) @(posedge clk);
    endtask

    task dequeue_empty;
        wait(is_empty_flag);
        dequeue_test_flag <= 1'b1;
        repeat (16) begin
            // @(posedge clk);
            // dequeue_test_flag <= 1'b1;
            @(posedge clk);
            // dequeue_test_flag <= 1'b0;
        end
        repeat (4) @(posedge clk);
    endtask

    task dequeue_full;
        wait(is_full_flag);
        repeat (16) begin
            @(posedge clk);
            dequeue_test_flag <= 1'b1;
            @(posedge clk);
            dequeue_test_flag <= 1'b0;
        end
        wait(is_full_flag);
        repeat (4) @(posedge clk);
    endtask

    task test_free_list_init;

            dequeue_free_list <= '0;
            enqueue_phys_reg <= 1'b0;
            freed_phys_reg <= 'x;

            @(posedge clk);
            repeat (65) begin
                @(posedge clk);
                dequeue_free_list <= 1'b1;
                @(posedge clk);
                dequeue_free_list <= 1'b0;
            end

            enqueue_phys_reg <= 1'b1;
            freed_phys_reg <= 6'b000001;
        
            repeat (4) @(posedge clk);

    endtask

    task test_dispatch;

        enqueue_phys_reg <= 1'b0;
        freed_phys_reg <= 'x;
        // res_station_full <= '0;
        // rob_idx <= '0;
        // rob_full <='0;

        repeat (20) @(posedge clk);

        // rob_full <='1;

        repeat (10) @(posedge clk);

        // rob_full <='0;

        repeat (1) @(posedge clk);

        // rob_full <='1;

        repeat (10) @(posedge clk);

        // rob_full <='0;

        repeat (40) @(posedge clk);


    endtask

    task test_dispatch_rob;

        enqueue_phys_reg <= 1'b0;
        freed_phys_reg <= 'x;
        // res_station_full <= '0;

        ready_commit <= '0;
        rob_idx_cdb <= '0;

        repeat (20) @(posedge clk);

        ready_commit <= '1;
        rob_idx_cdb <= '0;

        repeat (1) @(posedge clk);

        ready_commit <= '0;
        rob_idx_cdb <= '0;

        repeat (20) @(posedge clk);

        ready_commit <= '1;
        rob_idx_cdb <= 3'b001;

        repeat (1) @(posedge clk);

        ready_commit <= '1;
        rob_idx_cdb <= 3'b010;

        repeat (1) @(posedge clk);

        ready_commit <= '0;
        rob_idx_cdb <= '0;

        repeat (20) @(posedge clk);

    
    endtask


    // assign dequeue_test_flag = 1'b0;

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
            repeat (5) @(posedge clk);
            $fatal;
        end
        if (mem_itf.error != 0) begin
            repeat (5) @(posedge clk);
            $fatal;
        end
        timeout <= timeout - 1;
    end

endmodule
