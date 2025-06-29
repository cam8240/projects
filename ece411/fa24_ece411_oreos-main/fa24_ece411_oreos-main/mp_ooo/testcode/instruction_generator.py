import random

instructions = [
    "add", "mul", "mulh", "mulhsu", "mulhu", "div", "divu", "rem", "remu",
    "addi", "slti", "sltiu", "xori", "ori", "andi", "slli", "srli", "srai",
    "sub", "slt", "sltu", "xor", "sll", "srl", "sra", "or", "and", "lui", 
    "auipc"
]

def generate_initial_loads():
    loads = []
    for i in range(0, 30):
        imm = random.randint(-2048, 2047)
        loads.append(f"li x{i}, {imm}")
    for i in range(30, 32):
        imm = random.randint(0, 0)
        loads.append(f"li x{i}, {imm}")
    return loads

def generate_initial_setup():
    setup_instructions = []
    for i in range(1, 6):
        base_addr = 0x1fceb
        offset_increment = random.randint(0x00, 0x7F)
        bit_increment = random.choice([0x0, 0x4, 0x8, 0xC])

        lui_instr = f"lui x{i}, 0x{base_addr:X}"
        addi_instr = f"addi x{i}, x{i}, 0x{offset_increment:02x}{bit_increment:01x}"

        setup_instructions.append(f"{lui_instr}\n{addi_instr}")
    return setup_instructions

def generate_random_instruction():
    inst = random.choice(instructions)

    if inst in ["addi", "slti", "sltiu", "xori", "ori", "andi"]:
        rd = f"x{random.randint(6, 31)}"
        rs1 = f"x{random.randint(6, 31)}"
        imm = random.randint(-2048, 2047)
        return f"{inst} {rd}, {rs1}, {imm}"

    elif inst == "lui":
        rd = f"x{random.randint(6, 31)}"
        imm = random.randint(0, (1 << 20) - 1)
        return f"{inst} {rd}, {imm}"

    elif inst in ["slli", "srli", "srai"]:
        rd = f"x{random.randint(6, 31)}"
        rs1 = f"x{random.randint(6, 31)}"
        shamt = random.randint(6, 31)
        return f"{inst} {rd}, {rs1}, {shamt}"

    elif inst == "auipc":
        rd = f"x{random.randint(6, 31)}"
        imm = random.randint(0, (1 << 20) - 1)
        return f"auipc {rd}, 0x{imm:X}"


    else:
        rd = f"x{random.randint(6, 31)}"
        rs1 = f"x{random.randint(6, 31)}"
        rs2 = f"x{random.randint(6, 31)}"
        return f"{inst} {rd}, {rs1}, {rs2}"

def generate_random_load_or_store():
    load_instructions = ["lb", "lh", "lw", "lbu", "lhu"]
    store_instructions = ["sb", "sh", "sw"]
    
    if random.choice([True, False]):
        inst = random.choice(load_instructions)
        rd = f"x{random.randint(6, 30)}"
        base_register = f"x{random.randint(1, 5)}"
        instruction = f"{inst} {rd}, 0({base_register})"
    else:
        inst = random.choice(store_instructions)
        rs2 = f"x{random.randint(6, 30)}"
        base_register = f"x{random.randint(1, 5)}"
        instruction = f"{inst} {rs2}, 0({base_register})"
    
    return instruction


def generate_riscv_assembly():
    with open("new_rand1.s", "w") as file:

        file.write("new_rand1.s:\n.align 4\n.section .text\n.globl _start\n_start:\n\n")

        initial_setup = generate_initial_setup()
        file.write("\n".join(initial_setup) + "\n\n")

        file.write("\n".join(["nop"] * 5) + "\n\n")

        for _ in range(1000000):
            if random.choice([True, False]):
                instruction = generate_random_load_or_store()
            else:
                instruction = generate_random_instruction()
            file.write(instruction + "\n")

        file.write("\nhalt:\n    # Infinite loop to stop the program\n    slti x0, x0, -256\n")

generate_riscv_assembly()