.section .text
.globl _start
_start:
    # Initialize x30 with current PC, and load to x1
    addi x2, x1, 0x10            # x2 = x1 + 0x10 (RAW hazard, limited to 0x10)
    nop
    nop

    # Test with jump and link instruction
    jal  x5, jump_target_1        # Jump to jump_target_1, return address in x5
    addi x3, x2, 0x20            # x3 = x2 + 0x20 after jump (control hazard, limited to 0x20)
    nop
    nop
    nop

    # Branch tests
    #beq  x2, x3, branch_fail_1    # Test if x2 == x3 (should fail)
    bne  x2, x3, branch_pass_1    # Test if x2 != x3 (should pass)
    nop
    nop
    nop

    # Test jump and control hazards
    jal  x6, jump_target_2        # Jump to jump_target_2, return address in x6
    addi x4, x3, 0x10            # x4 = x3 + 0x10 after jump (control hazard, limited to 0x10)
    nop
    nop
    nop

    # Memory load-store tests with dependencies
    lw   x5, 8(x30)              # Load word to x5
    sw   x5, 12(x2)              # Store x5, address dependent on x2 (addressing hazard)
    addi x6, x5, 0x20            # x6 depends on x5 (limited to 0x20)
    lw   x7, 16(x6)              # Load word from memory address based on x6 (hazard test)

    # Branch tests with memory dependency
    #beq  x7, x5, branch_fail_2    # Compare result of memory load
    #bne  x7, x6, branch_pass_2    # Compare loaded data to dependency result

    # Further branch and jump tests
    jal  x8, jump_target_3        # Test additional jump with dependencies
    addi x9, x8, 0x10            # x9 depends on jump target (limited to 0x10)
    nop
    nop
    nop

    # Test with x0 in arithmetic and branches
    addi x10, x0, 0x20           # x10 = 0x20, check x0 dependency (limited to 0x20)
    #beq  x10, x0, branch_fail_3   # Compare to zero (should fail)
    #bne  x10, x0, branch_pass_3   # This branch should pass

    # Jump to check hazards
    jal  x11, jump_target_4       # Another jump to test control hazards
    addi x12, x11, 0x10          # x12 depends on jump (limited to 0x10)
    nop
    nop


# Jump Targets
jump_target_1:
    addi x1, x0, 0x10            # x1 = 0x10 in jump (limited to 0x10)
    addi x2, x1, 0x20            # x2 = x1 + 0x20 inside jump (limited to 0x20)
    jalr x0, x5, 0               # Return to caller

jump_target_2:
    addi x3, x0, 0x20            # x3 = 0x20 in jump (limited to 0x20)
    addi x4, x3, 0x10            # x4 depends on x3 (limited to 0x10)
    jalr x0, x6, 0               # Return to caller

jump_target_3:
    addi x5, x0, 0x10            # x5 = 0x10 (limited to 0x10)
    addi x6, x5, 0x20            # x6 depends on x5 (limited to 0x20)
    jalr x0, x8, 0               # Return to caller

jump_target_4:
    addi x7, x0, 0x20            # Final jump test (limited to 0x20)
    addi x8, x7, 0x10            # x8 depends on jump (limited to 0x10)
    #jalr x0, x11, 0              # Return to caller

# Branch Fail and Pass Targets
branch_fail_1:
    #addi x9, x0, 0x10            # Fail marker (limited to 0x10)
    #slti x0, x0, -256            # Terminate the simulation

branch_pass_1:
    addi x10, x0, 0x20           # Pass marker (limited to 0x20)
    slti x0, x0, -256            # Terminate the simulation

branch_fail_2:
    #addi x11, x0, 0x10           # Fail marker (limited to 0x10)
    #slti x0, x0, -256            # Terminate the simulation

branch_pass_2:
    #addi x12, x0, 0x20           # Pass marker (limited to 0x20)
    #slti x0, x0, -256            # Terminate the simulation

branch_fail_3:
    #addi x13, x0, 0x10           # Fail marker (limited to 0x10)
    #slti x0, x0, -256            # Terminate the simulation

branch_pass_3:
    #addi x14, x0, 0x20           # Pass marker (limited to 0x20)
    #slti x0, x0, -256            # Terminate the simulation

# End the simulation
halt:
    slti x0, x0, -256            # Magic instruction to end the simulation (proper termination)