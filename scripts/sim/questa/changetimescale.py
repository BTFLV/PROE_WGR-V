import re
import os
import sys

def process_vcd(input_file):
    if not os.path.isfile(input_file):
        print(f"Error: File '{input_file}' does not exist.")
        return

    base, ext = os.path.splitext(input_file)
    output_file = f"{base}_ns{ext}"

    in_timescale_block = False

    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if "$timescale" in line:
                in_timescale_block = True
                outfile.write("$timescale\n")
            
            elif in_timescale_block and "1ps" in line.strip():
                outfile.write("\t1ns\n")
            
            elif in_timescale_block and "$end" in line:
                in_timescale_block = False
                outfile.write("$end\n")
            
            elif line.startswith('#'):
                timestamp = line[1:].strip()
                if len(timestamp) > 3:
                    scaled_timestamp = timestamp[:-3]
                else:
                    scaled_timestamp = '0'
                outfile.write(f'#{scaled_timestamp}\n')
            
            else:
                outfile.write(line)

    print(f"Processed VCD saved as: {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python process_vcd.py <input_file.vcd>")
    else:
        input_file = sys.argv[1]
        process_vcd(input_file)
