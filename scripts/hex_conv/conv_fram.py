"""
Converts a Quartus HEX file into a file for readmemh.
Should be used with the output from conv_hex.py.

<memory_size> is interpreted as the number of 32 bit words in the input hex.
So for a 8192 byte fram, use a memory_size of 2048.

Example Conversion:
    :04000400FF81011364 -> FF 81 01 13

Usage:
    conv_fram.py <input.hex> <output.hex> <memory_size>

Example:
    conv_fram.py wgr_flat.hex wgr_fram.hex 2048

"""

#!/usr/bin/env python3
import sys

def convert_quartus_hex_to_readmemh(input_file, output_file, memory_size=2048):
    memory_size *= 4  # Word count to byte count
    data_bytes = []
    with open(input_file, 'r') as fin:
        for line in fin:
            line = line.strip()
            if not line or line[0] != ':':
                continue

            rec_len = int(line[1:3], 16)
            record_type = line[7:9]
            
            if record_type == "00":
                data_str = line[9:9 + rec_len * 2]
                for i in range(0, len(data_str), 2):
                    byte = data_str[i:i+2]
                    data_bytes.append(byte)
            elif record_type == "01":  # EOF
                break

    if len(data_bytes) < memory_size:
        data_byte_len = len(data_bytes)
        size_diff = (memory_size - data_byte_len)
        data_bytes.extend(["00"] * size_diff)
        print(f"\n - Extended {data_byte_len // 4} instructions with {size_diff // 4} zero words.")
    elif len(data_bytes) > memory_size:
        data_byte_len = len(data_bytes)
        size_diff = data_byte_len - memory_size
        data_bytes = data_bytes[:memory_size]
        print(f"\n - Warning: {size_diff // 4} instructions not written")
        print(f"\n - {data_byte_len} byte needed, but only {memory_size} byte available.")

    byte_count = 0

    for i in range(len(data_bytes) - 1, -1, -1):
        if data_bytes[i] == 0:
            count += 1
        else:
            break

    instruction_count = (memory_size - byte_count) // 4

    print(f"Instructions: {instruction_count} ({memory_size - byte_count} of {memory_size} bytes used).")

    with open(output_file, 'w') as fout:
        for i in range(0, len(data_bytes), 4):
            fout.write(" ".join(data_bytes[i:i+4]) + "\n")
        print(f"Output file {output_file} written.")

def main():
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print(" - Usage: input.hex output.hex <memory_size>")
        sys.exit(1)
    print("\n  -- quartus ram .hex to verilog readmemh file converter -- ")
    input_file = sys.argv[1]
    output_file = sys.argv[2]

    memory_size = 8192  
    if len(sys.argv) == 4:
        try:
            memory_size = int(sys.argv[3])
        except ValueError:
            print(" - Error: memory_size must be an integer.")
            sys.exit(1)

    print(f"Converting {input_file} to {output_file} ({memory_size * 4} bytes)")
    convert_quartus_hex_to_readmemh(input_file, output_file, memory_size)

if __name__ == '__main__':
    main()
