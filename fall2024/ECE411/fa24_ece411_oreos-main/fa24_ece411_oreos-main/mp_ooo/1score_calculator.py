import math

def process_section(section, area):
    updated_lines = []
    pd3a_sums = []  # Collect all PD^3A^(1/2) values to calculate the average
    for line in section:
        if "IPC:" in line and "Delay:" in line and "Power:" in line:
            parts = line.split("|")
            # Extract Delay and Power
            delay = float(parts[1].split(":")[1].strip())
            power = float(parts[2].split(":")[1].strip())
            # Calculate PD^3A^(1/2)
            result = ((delay / 1000) ** 3) * (math.sqrt(area)) * power / 1000
            pd3a_sums.append(result)
            # Reformat the line to place the result correctly
            updated_line = f"{parts[0].strip()} | {parts[1].strip()} | {parts[2].strip()} | PD^3A^(1/2) = {result:.6f} | {parts[3].strip()}"
            updated_lines.append(updated_line)
        else:
            updated_lines.append(line.strip())
    if pd3a_sums:
        # Calculate the average score
        average_score = sum(pd3a_sums) / len(pd3a_sums)
        updated_lines.append(f"AVERAGE PD^3A^(1/2) SCORE: {average_score:.6f}\n\n\n")
    return updated_lines

# Clear the output file before processing
with open("1score_calculator_out.txt", "w") as output_file:
    output_file.truncate(0)

# Read the file and process it
with open("1queue_exploration_out.txt", "r") as file:
    lines = file.readlines()

processed_lines = []
current_section = []
area = None

for line in lines:
    if "Total cell area::" in line:
        # Extract the area
        area = float(line.split("::")[1].split("|")[0].strip())
    if "====" in line:
        # Process the previous section
        if current_section and area is not None:
            processed_lines.extend(process_section(current_section, area))
            current_section = []
        processed_lines.append(line.strip())  # Keep the delimiter lines
    else:
        current_section.append(line)

# Process the last section if needed
if current_section and area is not None:
    processed_lines.extend(process_section(current_section, area))

# Write the processed lines to a new file
with open("1score_calculator_out.txt", "w") as output_file:
    for line in processed_lines:
        output_file.write(line + "\n")

print("Processing complete. Results written to 1score_calculator_out.txt.")
