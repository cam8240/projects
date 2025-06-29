# UIUC ECE Project Showcase Repository

This repository is a collection of advanced technical projects demonstrating expertise in computer engineering, systems programming, and hardware design. These projects were developed as part of academic and personal exploration into low-level systems, processor design, and hardware programming. Linked on my resume, this showcase highlights my skills in RISC-V, C, x86 assembly, SystemVerilog, and more. Projects can be found in the `main` branch.

## Table of Contents

* [Projects](#projects)

  * [Out-of-Order RISC-V Processor](#out-of-order-riscv-processor)
  * [Linux Kernel with Multi-Terminal Scheduling](#linux-kernel-with-multi-terminal-scheduling)
  * [Hardware-Based Game in SystemVerilog](#hardware-based-game-in-systemverilog)
  * [Global Crypto Market Data Extraction](#global-crypto-market-data-extraction)
  * [Artificial Intelligence Course Projects](#artificial-intelligence-course-projects)
  * [LLM Chat Assistant](#llm-chat-assistant)
* [File Structure](#file-structure)
* [Installation](#installation)
* [Usage](#usage)
* [Skills Demonstrated](#skills-demonstrated)
* [Contributing](#contributing)
* [License](#license)

## Projects

### Out-of-Order RISC-V Processor (ECE 411)

* **Description**: Designed and implemented an out-of-order processor based on RISC-V assembly, featuring advanced performance optimizations.
* **Features**:

  * 4-way set associative L1 data and instruction cache.
  * Next-line prefetcher for improved instruction fetching.
  * Gselect branch predictor for efficient branch handling.
  * Split Load/Store Queue (LSQ) for out-of-order execution.
* **Technologies**: RISC-V assembly, hardware simulation tools.

### Linux Kernel with Multi-Terminal Scheduling (ECE 391)

* **Description**: Developed a custom Linux operating system kernel with support for multitasking and multi-terminal operations.
* **Features**:

  * Paging for memory management.
  * System calls for user-kernel interaction.
  * Multi-terminal scheduling supporting up to 6 simultaneous tasks and 3 active terminals.
* **Technologies**: C, x86 assembly.

### Hardware-Based Game in SystemVerilog (ECE 385)

* **Description**: Created a hardware-implemented game using SystemVerilog, showcasing low-level hardware design and programming.
* **Features**:

  * Graphics rendering on hardware.
  * User input handling.
  * Multiple levels with obstacles for dynamic gameplay.
* **Technologies**: SystemVerilog, FPGA tools.

### Global Crypto Market Data Extraction (IE 497)

* **Description**: Built a real-time crypto market data pipeline with hardware timestamping and cloud integration for public access and visualization.
* **Features**:

  * Real-time data collection from multiple exchanges using WebSockets.
  * Hardware-level timestamping for high-frequency data accuracy.
  * AWS-hosted infrastructure using S3, DynamoDB, Kinesis, and CloudFront.
  * Public-facing front-end built with React and JavaScript for visualizing live and historical data.
* **Technologies**: C, C++, Python, JavaScript, React, AWS (S3, RDS, DynamoDB, Kinesis), WebSockets.

### Artificial Intelligence Course Projects (CS 440)

* **Description**: A suite of academic projects implementing core AI concepts including search, planning, probabilistic reasoning, regression, and deep learning.
* **Features**:

  * Focus on foundational AI topics such as MDPs, Naive Bayes, linear regression, and neural networks.
  * Projects coded from scratch to reflect core understanding of algorithms and statistical modeling.
  * Deep learning components implemented with PyTorch and NumPy.
* **Technologies**: Python, NumPy, PyTorch, scikit-learn.

### LLM Chat Assistant (Independent Project)

* **Description**: A full-stack conversational assistant powered by OpenAI's API, demonstrating integration of Flask, Vue, PostgreSQL, and Dockerized microservices.
* **Features**:

  * Backend built with Flask exposing `/chat` and `/history/<session_id>` REST endpoints.
  * GPT-4.1-nano based conversational interface with personality switching (e.g., friendly, tutor, coder).
  * Frontend Vue interface with markdown rendering, syntax highlighting, and dark mode.
  * PostgreSQL session logging with SQLAlchemy and rate limiting via Flask-Limiter.
  * A Go-based microservice for auxiliary analysis like word and character counts.
  * Bash script for CLI interaction; Docker Compose setup for full-stack orchestration.
  * JavaFX desktop client for native GUI chat access, sharing the same API and session backend.
* **Technologies**: Python, Java, Flask, OpenAI API, JavaScript, Vue, HTML/CSS, PostgreSQL, Go, Bash, Docker.

## File Structure

```
showcase-repo/
├── ece385/               # ECE 385 Project
│   └── ece385-finalproject/
├── ece411/               # ECE 411 Project
│   └── fa24\_ece411\_oreos-main/
├── ece391/               # ECE 391 Project
├── ece448/               # ECE 448 Project
├── ie497/                # IE 497 Project
│   └── Global-Crypto-Market-Continuous-Data-Extraction/
├── llm_project/          # Independent LLM project
│   ├── gpt
└── README.md             # Project showcase documentation
```

## Installation

Each project has unique setup requirements:

1. **RISC-V Processor**: Requires a RISC-V simulator (e.g., RARS or Spike) or FPGA tools for synthesis.
2. **Linux Kernel**: Needs a Linux environment, GCC, and QEMU for x86 emulation.
3. **Hardware Game**: Requires an FPGA board (e.g., DE10-Nano) and Quartus or Vivado for synthesis.
4. **Crypto Market Data**: Requires WSL or Linux, libwebsockets, AWS credentials, and Node.js for the front end.
5. **AI Projects**: Requires Python 3, NumPy, PyTorch, and optionally scikit-learn for ML-based assignments.
6. **LLM Chat**: Requires Python 3, `flask`, `openai`, `flask-cors`, `flask-limiter`, `python-dotenv`, and optionally a bash-compatible terminal.  
   For the desktop client, install JDK 17+, Maven, and JavaFX SDK (or use Docker).

## Usage

* **RISC-V Processor**: Run simulations or synthesize to test processor performance with provided test benches.
* **Linux Kernel**: Compile and boot in QEMU to interact with the custom OS and terminals.
* **Hardware Game**: Deploy to an FPGA to play the game via hardware inputs and display.
* **Crypto Market Data**: Launch backend collectors with C or Python, store and stream data to AWS, and access the public UI via browser.
* **AI Projects**: Run individual scripts for model training, evaluation, or planning depending on the assignment context.
* **LLM Chat**: Start Flask backend and interact via terminal (`ask.sh`) or browser (`index.html`).

Refer to each project’s `README` for detailed usage instructions where applicable.

## Skills Demonstrated

* Processor architecture and optimization (RISC-V).
* Operating system design and kernel programming (C, x86).
* Hardware description languages and FPGA development (SystemVerilog).
* Real-time network programming and data collection (C, WebSockets).
* Cloud infrastructure and serverless architecture (AWS).
* Full-stack LLM app development (Flask, Java, JavaScript, OpenAI API, SQL).
* Front-end development and data visualization (React, JavaScript, Markdown).
* Machine learning, inference, and deep learning (Python, PyTorch, NumPy).

## Contributing

This repository is a personal showcase and not actively seeking contributions. However, feedback or collaboration inquiries are welcome via email or GitHub Issues.

## License

© 2025 Cameron Marchese. All rights reserved. These projects are shared for demonstration purposes. Usage or reproduction requires explicit permission.
