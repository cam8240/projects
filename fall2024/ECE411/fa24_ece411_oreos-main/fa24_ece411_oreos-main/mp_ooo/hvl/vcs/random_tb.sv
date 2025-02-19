//-----------------------------------------------------------------------------
// Title                 : random_tb
// Project               : ECE 411 mp_verif
//-----------------------------------------------------------------------------
// File                  : random_tb.sv
// Author                : ECE 411 Course Staff
//-----------------------------------------------------------------------------
// IMPORTANT: If you don't change the random seed, every time you do a `make run`
// you will run the /same/ random test. SystemVerilog calls this "random stability",
// and it's to ensure you can reproduce errors as you try to fix the DUT. Make sure
// to change the random seed or run more instructions if you want more extensive
// coverage.
//------------------------------------------------------------------------------
module random_tb
import rv32i_types::*;
(
    mem_itf_banked.mem itf
);

    `include "../../hvl/vcs/randinst.svh"

    RandInst gen = new();
    RandInst gen2 = new();


logic   [31:0]  return_addr;

    // Do a bunch of LUIs to get useful register state.
    task init_register_state();
        logic [63:0] lui_burst [4];

        for (int i = 0; i < 4; ++i) begin
            wait(itf.read == 1'b1);
            for (int j = 0; j < 4; ++j) begin
                gen.randomize() with {
                    instr.j_type.opcode == op_b_lui;
                    instr.j_type.rd == unsigned'((5)'(i * 2*j));
                };

                gen2.randomize() with {
                    instr.j_type.opcode == op_b_lui;
                    instr.j_type.rd == unsigned'((5)'(i * 2*j + 1));
                };

                lui_burst[j] = {gen.instr.word, gen2.instr.word};

            end
            
            @(posedge itf.clk iff |itf.read);
            for (int j = 0; j < 4; ++j) begin
                // @(posedge itf.clk iff |itf.read);

                itf.raddr <= itf.addr;
                itf.rdata <= lui_burst[j];
                // if(j==3) begin
                //     itf.rvalid <=1'b0;
                // end
                // else begin
                itf.rvalid <= 1'b1;  
                // end

                @(posedge itf.clk);
            end
            itf.rdata <= '0;
            itf.rvalid <= 1'b0; 
        end


    endtask : init_register_state

    // Note that this memory model is not consistent! It ignores
    // writes and always reads out a random, valid instruction.
    task run_random_instrs();
        logic [63:0] instruction_burst [4];

        // repeat (5000 / 8) begin
            for (int i = 0; i < 4; ++i) begin
                gen.randomize();
                gen2.randomize();
                instruction_burst[i] = {gen.instr.word, gen2.instr.word};
            end

            //itf.raddr <= itf.addr;
            //@(posedge itf.clk iff (|itf.read || |itf.write));
            @(posedge itf.clk iff |itf.read);
            for (int j = 0; j < 4; ++j) begin
                //@(posedge itf.clk iff (|itf.read || |itf.write));
                //@(posedge itf.clk);
                itf.raddr <= itf.addr;
                //if (|itf.read) begin
                itf.rdata <= instruction_burst[j];
                //end
                // itf.raddr <= itf.addr;

                // If it's a write, do nothing and just respond.
                itf.rvalid <= 1'b1;
                // @(posedge itf.clk);
                //itf.rvalid <= 1'b0;
                //@(posedge itf.clk) itf.resp[0] <= 1'b0;
                @(posedge itf.clk);
            end
            // itf.rdata <= '0;
            // itf.rvalid <= 1'b0; 

        //end
    endtask : run_random_instrs


    always @(posedge itf.clk iff !itf.rst) begin
        if ($isunknown(itf.read) || $isunknown(itf.write)) begin
            $error("Memory Error: mask containes 1'bx");
            itf.error <= 1'b1;
        end
        if ((|itf.read) && (|itf.write)) begin
            $error("Memory Error: Simultaneous memory read and write");
            itf.error <= 1'b1;
        end
        if ((|itf.read) || (|itf.write)) begin
            if ($isunknown(itf.addr[0])) begin
                $error("Memory Error: Address contained 'x");
                itf.error <= 1'b1;
            end
            // Only check for 16-bit alignment since instructions are
            // allowed to be at 16-bit boundaries due to JALR.
            // if (itf.addr[0][0] != 1'b0) begin
            //     $error("Memory Error: Address is not 16-bit aligned");
            //     itf.error <= 1'b1;
            // end
        end
    end

    // A single initial block ensures random stability.
    int covered;
    int total;
    initial begin

        itf.rdata <= 64'h0000001300000013;
        itf.rvalid <= '0;
        itf.ready <= '1;
        @(posedge itf.clk iff itf.rst == 1'b0);
        itf.ready <= '1;
        
        init_register_state();

        //10,000 runs
        repeat(80000/8) begin
            wait(itf.read == 1'b1);
            run_random_instrs();
            itf.rdata <= '0;
            itf.rvalid <= 1'b0; 
        end

        // Run!
        //wait(itf.read);

        gen.instr_cg.all_opcodes.get_coverage(covered, total);
        $display("\nAll Opcodes Coverage: %0d/%0d", covered, total);

        gen.instr_cg.all_funct7.get_coverage(covered, total);
        $display("All Funct7 Coverage: %0d/%0d", covered, total);

        gen.instr_cg.all_funct3.get_coverage(covered, total);
        $display("All Funct3 Coverage: %0d/%0d", covered, total);
        
        gen.instr_cg.all_regs_rs1.get_coverage(covered, total);
        $display("All regs_rs1 Coverage: %0d/%0d", covered, total);
        
        gen.instr_cg.all_regs_rs2.get_coverage(covered, total);
        $display("All regs_rs2 Coverage: %0d/%0d", covered, total);
        
        gen.instr_cg.funct3_cross.get_coverage(covered, total);
        $display("funct3 cross Coverage: %0d/%0d", covered, total);
        
        gen.instr_cg.funct7_cross.get_coverage(covered, total);
        $display("funct7 cross Coverage: %0d/%0d", covered, total);
        // Finish up
        $display("Random testbench finished!\n");
        $finish;
    end

endmodule : random_tb
