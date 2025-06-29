import os
import subprocess

def parse_completed_tasks(output_file):
    """
    Parse the output file to extract completed parameter-command combinations,
    including synthesis steps and printed parameter sections.
    """
    completed_tasks = set()
    completed_synth = set()
    logged_params = set()
    current_params = None

    if os.path.exists(output_file):
        with open(output_file, 'r') as file:
            for line in file:
                line = line.strip()
                if line.startswith("Running for parameters:"):
                    params_str = line.split(":", 1)[1].strip()
                    current_params = eval(params_str)
                    logged_params.add(frozenset(current_params.items()))
                elif "Command:" in line and current_params:
                    command = line.split("Command:")[1].strip()
                    if "synth" in command:
                        # Mark synthesis step as completed
                        completed_synth.add(frozenset(current_params.items()))
                    else:
                        # Mark regular task as completed
                        completed_tasks.add((frozenset(current_params.items()), command))
    return completed_tasks, completed_synth, logged_params


def modify_localparam(file_path, param_name, param_value):
    """
    Modify the value of a specific localparam in the specified file.
    """
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()
        
        modified = False
        for i, line in enumerate(lines):
            if f"localparam {param_name}" in line:
                parts = line.split('=')
                if len(parts) == 2:
                    lines[i] = f"{parts[0].strip()} = {param_value};\n"
                    modified = True
                    print(f"Modified line: {lines[i].strip()}")
                    break
        
        if not modified:
            print(f"localparam {param_name} not found in the file.")
            return False
        
        with open(file_path, 'w') as file:
            file.writelines(lines)
        
        print(f"File modification for {param_name} completed successfully.")
        return True
    except Exception as e:
        print(f"An error occurred while modifying {param_name}: {e}")
        return False

def run_command(command):
    """
    Run a command in the command line and wait until it completes.
    """
    try:
        print(f"Executing command: {command}")
        process = subprocess.run(
            command,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        print(f"Command output:\n{process.stdout}")
        if process.stderr:
            print(f"Command error:\n{process.stderr}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Command failed with error: {e}")
        return False

def load_power_values(file_path):
    """
    Load power values from a text file into a dictionary.
    """
    power_dict = {}
    try:
        with open(file_path, 'r') as file:
            for line in file:
                if ":" in line:
                    name, power = line.strip().split(":")
                    power_dict[name.strip()] = power.strip()
    except Exception as e:
        print(f"Error loading power values: {e}")
    return power_dict

def extract_values(file_path, ipc_terms, time_terms, output_file_path, command, power_dict):
    """
    Extract IPC, Segment Time, and Power values from a file and save them to the output file.
    """
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return None

    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()

        ipc_value = None
        segment_time_value = None

        for line in lines:
            for term in ipc_terms:
                if term in line and ipc_value is None:
                    ipc_value = line.split(term)[1].strip()

            for term in time_terms:
                if term in line and segment_time_value is None:
                    raw_value = line.split(term)[1].strip()
                    try:
                        segment_time_value = int(float(raw_value) / 1_000_000)
                    except ValueError:
                        print(f"Error converting segment time: {raw_value}")

            if ipc_value and segment_time_value is not None:
                file_name = command.split("PROG=")[-1].strip()
                power_value = power_dict.get(file_name, "N/A")

                with open(output_file_path, 'a') as output:
                    output.write(
                        f"IPC: {ipc_value} | Delay: {segment_time_value} | Power: {power_value} | Command: {command}\n"
                    )
                print(f"Saved IPC: {ipc_value}, Segment Time: {segment_time_value}, Power: {power_value}")
                return

        if ipc_value is None:
            print(f"Could not find any of {ipc_terms} in {file_path}.")
        if segment_time_value is None:
            print(f"Could not find any of {time_terms} in {file_path}.")

    except Exception as e:
        print(f"An error occurred while processing the file: {e}")



def extract_value(file_path, search_terms, output_file_path, command):
    """
    Extract values for any matching search terms from a file and save them to the output file with the associated command.
    """
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return None
    
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()
        
        for line in lines:
            for term in search_terms:
                if term in line:
                    parts = line.split(term)
                    if len(parts) > 1:
                        value = parts[1].strip()
                        print(f"Found {term} {value}")
                        with open(output_file_path, 'a') as output:
                            output.write(f"{term}: {value} | Command: {command}\n")
                        print(f"Result saved to {output_file_path}")
                        return value
        
        print(f"No matches for terms {search_terms} found in {file_path}.")
        return None
    except Exception as e:
        print(f"An error occurred while processing the file: {e}")
        return None

# Main script logic
if __name__ == "__main__":
    file_path = "../pkg/types.sv"
    log_file = "vcs/simulation.log"
    area_log_file = "../synth/reports/area.rpt"
    timing_file = "../synth/reports/timing.rpt"
    output_file = "1queue_exploration_out.txt"
    power_file = "1power.txt"

    power_dict = load_power_values(power_file)

    resume = input("Resume (Y/N)? ").strip().lower() == 'y'

    if not resume:
        with open(output_file, 'w') as output:
            output.write("")

    completed_tasks, completed_synth, logged_params = parse_completed_tasks(output_file) if resume else (set(), set(), set())

    # Define configurations for parameter exploration
    configurations = [
        {
            "params": {"QUEUE_DEPTH": 4, "ROB_DEPTH": 4, "RESERVATION_STATION_SIZE": 4, "LS_QUEUE_DEPTH": 4},
            "commands": [
                # "make run_vcs_top_tb PROG=../testcode/ooo_test.s",
                # "make run_vcs_top_tb PROG=../testcode/dependency_test.s",
                "make run_vcs_top_tb PROG=../testcode/coremark_im.elf",
                "make run_vcs_top_tb PROG=../testcode/additional_testcases/compression_im.elf",
                "make run_vcs_top_tb PROG=../testcode/cp3_release_benches/mergesort.c",
                "make run_vcs_top_tb PROG=../testcode/cp3_release_benches/fft.c",
                "make run_vcs_top_tb PROG=../testcode/cp3_release_benches/aes_sha.c"
            ]
        },
        {
            "params": {"QUEUE_DEPTH": 8, "ROB_DEPTH": 4, "RESERVATION_STATION_SIZE": 4, "LS_QUEUE_DEPTH": 4},
            "commands": [
                # "make run_vcs_top_tb PROG=../testcode/ooo_test.s",
                # "make run_vcs_top_tb PROG=../testcode/dependency_test.s",
                "make run_vcs_top_tb PROG=../testcode/coremark_im.elf",
                "make run_vcs_top_tb PROG=../testcode/additional_testcases/compression_im.elf",
                "make run_vcs_top_tb PROG=../testcode/cp3_release_benches/mergesort.c",
                "make run_vcs_top_tb PROG=../testcode/cp3_release_benches/fft.c",
                "make run_vcs_top_tb PROG=../testcode/cp3_release_benches/aes_sha.c"
            ]
        },
        {
            "params": {"QUEUE_DEPTH": 16, "ROB_DEPTH": 4, "RESERVATION_STATION_SIZE": 4, "LS_QUEUE_DEPTH": 4},
            "commands": [
                # "make run_vcs_top_tb PROG=../testcode/ooo_test.s",
                # "make run_vcs_top_tb PROG=../testcode/dependency_test.s",
                "make run_vcs_top_tb PROG=../testcode/coremark_im.elf",
                "make run_vcs_top_tb PROG=../testcode/additional_testcases/compression_im.elf",
                "make run_vcs_top_tb PROG=../testcode/cp3_release_benches/mergesort.c",
                "make run_vcs_top_tb PROG=../testcode/cp3_release_benches/fft.c",
                "make run_vcs_top_tb PROG=../testcode/cp3_release_benches/aes_sha.c"
            ]
        }
    ]

    command2 = "cd ../synth && make synth"

    for config in configurations:
        params = config["params"]
        param_frozen = frozenset(params.items())

        # Skip writing parameter sections if already logged
        if param_frozen not in logged_params:
            with open(output_file, 'a') as output:
                output.write("\n" + "="*100 + "\n")
                output.write(f"Running for parameters: {params}\n")
                output.write("="*100 + "\n")

        # Modify each specified localparam in the file
        all_params_success = True
        for param_name, param_value in params.items():
            if not modify_localparam(file_path, param_name, param_value):
                all_params_success = False
                with open(output_file, 'a') as output:
                    output.write(f"Failed to modify {param_name} to {param_value}\n")

        if all_params_success:
            # Run test commands
            for command1 in config["commands"]:
                if (param_frozen, command1) in completed_tasks:
                    print(f"Skipping completed task: {command1} for {params}")
                    continue

                if run_command(command1):
                    ipc_terms = ["Monitor: Total IPC:", "Monitor: Segment IPC:"]
                    time_terms = ["Monitor: Segment Time:", "Monitor: Total Time:"]

                    extract_values(log_file, ipc_terms, time_terms, output_file, command1, power_dict)

            # Run the synthesis command if not already completed
            if param_frozen not in completed_synth:
                if run_command(command2):
                    extract_value(area_log_file, ["Total cell area:"], output_file, command2)
                    extract_value(timing_file, ["slack (MET)"], output_file, command2)
            else:
                print(f"Skipping synthesis for parameters: {params}")