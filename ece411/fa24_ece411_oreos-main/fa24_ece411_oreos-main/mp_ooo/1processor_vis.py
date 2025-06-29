import matplotlib.pyplot as plt
import re

def parse_log_file(file_path, variable_types):
    data = {var: [] for var in variable_types}

    pattern = re.compile(r"Time: (\d+) ns, (\w+): (\d+)")
    
    with open(file_path, 'r') as f:
        for line in f:
            match = pattern.match(line)
            if match:
                time = int(match.group(1))
                var = match.group(2)
                count = int(match.group(3))
                if var in data:
                    data[var].append((time, count))
    
    return data

def plot_graphs(data, variable_types):
    num_vars = len(variable_types)
    cols = 3
    rows = (num_vars + cols - 1) // cols

    plt.figure(figsize=(15, rows * 4))
    for i, var in enumerate(variable_types):
        plt.subplot(rows, cols, i + 1)
        if var in data and data[var]:
            times, counts = zip(*data[var])
            plt.plot(times, counts, marker='o', linestyle='-')
            plt.title(f"{var}")
            plt.xlabel("Time (ns)")
            plt.ylabel("Count")
            plt.grid(True)
        else:
            plt.title(f"{var} (No Data)")
            plt.grid(True)
    plt.tight_layout()
    plt.show()

def print_final_counts(data):
    print("Final Counts for Each Variable:")
    for var, values in data.items():
        if values:
            final_count = values[-1][1]
            print(f"{var}: {final_count}")
        else:
            print(f"{var}: 0 or no data available")

if __name__ == "__main__":
    log_file_path = "1processor_vis_out.log"
    
    variable_types_to_plot = ["stall_from_dispatch_count", "rob_full_top_count", "ls_queue_full_count", "load_queue_full_count", "control_queue_full_count", 
                              "load_count", "store_count", "br_count", "monitor_count", "br_en_count", "cache_total_count", "cache_miss_count"]
    
    parsed_data = parse_log_file(log_file_path, variable_types_to_plot)
    
    print_final_counts(parsed_data)
    
    plot_graphs(parsed_data, variable_types_to_plot)
