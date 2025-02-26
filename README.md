# UIUC ECE Project Showcase Repository

This repository is a collection of advanced technical projects demonstrating expertise in computer engineering, systems programming, and hardware design. These projects were developed as part of academic and personal exploration into low-level systems, processor design, and hardware programming. Linked on my resume, this showcase highlights my skills in RISC-V, C, x86 assembly, SystemVerilog, and more. Projects can be found in the `Master` branch.

## Table of Contents
- [Projects](#projects)
  - [Out-of-Order RISC-V Processor](#out-of-order-risc-v-processor)
  - [Linux Kernel with Multi-Terminal Scheduling](#linux-kernel-with-multi-terminal-scheduling)
  - [Hardware-Based Game in SystemVerilog](#hardware-based-game-in-systemverilog)
- [File Structure](#file-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Skills Demonstrated](#skills-demonstrated)
- [Contributing](#contributing)
- [License](#license)

## Projects

### Out-of-Order RISC-V Processor (ECE 411)
- **Description**: Designed and implemented an out-of-order processor based on RISC-V assembly, featuring advanced performance optimizations.
- **Features**:
  - 4-way set associative L1 data and instruction cache.
  - Next-line prefetcher for improved instruction fetching.
  - Gselect branch predictor for efficient branch handling.
  - Split Load/Store Queue (LSQ) for out-of-order execution.
- **Technologies**: RISC-V assembly, hardware simulation tools.

### Linux Kernel with Multi-Terminal Scheduling (ECE 391)
- **Description**: Developed a custom Linux operating system kernel with support for multitasking and multi-terminal operations.
- **Features**:
  - Paging for memory management.
  - System calls for user-kernel interaction.
  - Multi-terminal scheduling supporting up to 6 simultaneous tasks and 3 active terminals.
- **Technologies**: C, x86 assembly.

### Hardware-Based Game in SystemVerilog (ECE 385)
- **Description**: Created a hardware-implemented game using SystemVerilog, showcasing low-level hardware design and programming.
- **Features**:
  - Graphics rendering on hardware.
  - User input handling.
  - Multiple levels with obstacles for dynamic gameplay.
- **Technologies**: SystemVerilog, FPGA tools.

## File Structure
```
showcase-repo/
├── riscv-processor/         # Out-of-Order RISC-V Processor
│   ├── src/                # Source files (RISC-V assembly, simulation scripts)
│   └── docs/               # Documentation and design notes
├── linux-kernel/           # Linux Kernel Project
│   ├── src/                # Source files (C, x86 assembly)
│   └── docs/               # Kernel documentation
├── hardware-game/          # SystemVerilog Game
│   ├── src/                # Source files (SystemVerilog)
│   └── docs/               # Hardware design specs
└── README.md               # This file
```

## Installation
Each project has unique setup requirements:
1. **RISC-V Processor**: Requires a RISC-V simulator (e.g., RARS or Spike) or FPGA tools for synthesis.
2. **Linux Kernel**: Needs a Linux environment, GCC, and QEMU for x86 emulation.
3. **Hardware Game**: Requires an FPGA board (e.g., DE10-Nano) and Quartus or Vivado for synthesis.

## Usage
- **RISC-V Processor**: Run simulations or synthesize to test processor performance with provided test benches.
- **Linux Kernel**: Compile and boot in QEMU to interact with the custom OS and terminals.
- **Hardware Game**: Deploy to an FPGA to play the game via hardware inputs and display.

Refer to each project’s `docs/` folder for detailed usage instructions.

## Skills Demonstrated
- Processor architecture and optimization (RISC-V).
- Operating system design and kernel programming (C, x86).
- Hardware description languages and FPGA development (SystemVerilog).
- Low-level programming and system integration.

## Contributing
This repository is a personal showcase and not actively seeking contributions. However, feedback or collaboration inquiries are welcome via email or GitHub Issues.

## License
© 2025 Cameron Marchese. All rights reserved. These projects are shared for demonstration purposes. Usage or reproduction requires explicit permission.
