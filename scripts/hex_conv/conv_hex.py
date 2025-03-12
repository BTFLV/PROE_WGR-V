"""

Converts the hex file from objcopy to a Quartus compatible hex file.
When using a Quartus RAM Megafunction, 32bit memory is word addressed.
In general the RAM Initialization hex file doesn't follow any standard.
The hex file from objcopy needs to be converted to a word adressed hex
file with only one word per line.

:AABBBBCCDDDDDDDDEE

AA = number of data bytes (for 32 bits, "04")
BBBB = starting word address (in words, not bytes)
CC = record type (00 for data records)
DDDDDDDD = the 4 data bytes (MSB first in the record output)
EE = checksum

Example:
    Instruction:        addi x2, x2, -8
    Opcode:             0xFF810113
    Converted hex:      :04000400FF81011364

The WGR-V CPU is using memory mapped peripherals below 0x4000, so the memory
needs to be shifted by 0x4000. When the CPU is accessing the memory at
0x4008, it is actually accessing the physical memory at 0x0008.

Remaining memory is set to 0x00000000 for the whole <memory_depth>.
An EOF record (:00000001FF) is appended at the end.

Usage:
    conv_hex.py <input.hex> <output.hex> <shift_amount in hex> <memory_depth>

Example:
    conv_hex.py wgr.hex wgr_flat.hex 0x4000 8192

"""

#!/usr/bin/env python3
import sys

def parse_original_ihex(original_hex_path, shift_amount, memory_depth, word_width=32):
    bytes_per_word = word_width // 8
    memory = [0] * memory_depth
    current_extended_linear_address = 0
    instruction_count = 0

    with open(original_hex_path, 'r') as f:
        for line_number, line in enumerate(f, 1):
            line = line.strip()
            if not line or line[0] != ':':
                continue

            try:
                byte_count = int(line[1:3], 16)
                address     = int(line[3:7], 16)
                record_type = int(line[7:9], 16)
                data_str    = line[9:9 + byte_count*2]
                checksum    = int(line[9 + byte_count*2:9 + byte_count*2 + 2], 16)
            except ValueError as ve:
                print(f"Error parsing line {line_number}: {ve}. Skipping.", file=sys.stderr)
                continue

            if record_type == 0x00:
                absolute_address = (current_extended_linear_address << 16) + address
                if absolute_address < shift_amount:
                    continue
                shifted_address = absolute_address - shift_amount
                if shifted_address % bytes_per_word != 0:
                    print(f"Warning: Non-word aligned address {shifted_address:#06X} on line {line_number}. Skipping.", file=sys.stderr)
                    continue
                word_index = shifted_address // bytes_per_word
                if word_index >= memory_depth:
                    print(f"Warning: Instruction {word_index} exceeds memory.", file=sys.stderr)
                    continue

                data_bytes = [int(data_str[i:i+2], 16) for i in range(0, len(data_str), 2)]
                num_words = len(data_bytes) // bytes_per_word

                instruction_count += num_words

                for w in range(num_words):
                    word = 0
                    for b in range(bytes_per_word):
                        shift = 8 * b
                        word |= data_bytes[w * bytes_per_word + b] << shift
                    target_index = word_index + w
                    if target_index < memory_depth:
                        memory[target_index] = word
                    else:
                        print(f"Warning: Instruction {target_index} exceeds memory.", file=sys.stderr)
            elif record_type == 0x04:
                current_extended_linear_address = int(data_str, 16)
            elif record_type == 0x01:
                break
            else:
                continue

    print(f"Instructions: {instruction_count} ({instruction_count * 4} of {memory_depth * 4} bytes used).")
    return memory

def compute_checksum(byte_count, address, record_type, data_bytes):
    total = byte_count
    total += (address >> 8) & 0xFF
    total += address & 0xFF
    total += record_type
    for b in data_bytes:
        total += b
    checksum = ((0x100 - (total & 0xFF)) & 0xFF)
    return checksum

def write_memory_hex(memory, output_hex_path):
    bytes_per_word = 4
    with open(output_hex_path, 'w', newline='\n') as f:
        for i, word in enumerate(memory):
            address = i
            byte_count = bytes_per_word
            record_type = 0x00

            data_bytes = [
                (word >> 24) & 0xFF,
                (word >> 16) & 0xFF,
                (word >> 8) & 0xFF,
                word & 0xFF,
            ]

            record = f":{byte_count:02X}{address:04X}{record_type:02X}"
            for b in data_bytes:
                record += f"{b:02X}"
            checksum = compute_checksum(byte_count, address, record_type, data_bytes)
            record += f"{checksum:02X}"
            f.write(record + "\n")
        f.write(":00000001FF\n")
        print(f"Output file {output_hex_path} written.")

def main():
    if len(sys.argv) != 5:
        print(" - Usage: conv_hex.py <input.hex> <output.hex> <shift_amount in hex> <memory_depth>\n")
        sys.exit(1)

    print("\n  -- gcc objcopy .hex to quartus ram .hex converter -- ")
    input_file = sys.argv[1]
    output_file = sys.argv[2]

    try:
        shift_amount = int(sys.argv[3], 16)
    except ValueError:
        print(" - Error: shift_amount must be a hexadecimal value.\n", file=sys.stderr)
        sys.exit(1)

    try:
        memory_depth = int(sys.argv[4])
    except ValueError:
        print(" - Error: memory_depth must be an integer.\n", file=sys.stderr)
        sys.exit(1)

    print(f"Converting {input_file} to {output_file} ({memory_depth * 4} bytes)")
    
    memory = parse_original_ihex(input_file, shift_amount, memory_depth)
    write_memory_hex(memory, output_file)

if __name__ == '__main__':
    main()
