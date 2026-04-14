import re

OPCODES = {
    "ADD":   0x0,
    "ADDI":  0x1,
    "LOAD":  0x2,
    "STORE": 0x3,
    "BEQ":   0x4,
    "BNE":   0x5,
    "JMP":   0x6,
    "CMP":   0x8,
    "ANDI":  0xA,
    "ORI":   0xB,
    "HALT":  0xF
}

# -------------------------
# Parsing Helpers
# -------------------------

def parse_reg(token: str) -> int:
    token = token.strip().upper()
    if not re.fullmatch(r"R[0-7]", token):
        raise ValueError(f"Bad register '{token}' (use R0..R7)")
    return int(token[1])

def parse_imm6(token: str) -> int:
    val = int(token, 0)
    if val < -32 or val > 31:
        raise ValueError(f"imm6 out of range (-32..31): {val}")
    return val & 0x3F

def parse_off3(token: str) -> int:
    val = int(token, 0)
    if val < -4 or val > 3:
        raise ValueError(f"off3 out of range (-4..3): {val}")
    return val & 0x7

def clean_line(line: str) -> str:
    line = line.split(";")[0].split("#")[0]
    line = line.replace(",", " ")
    return line.strip()

def is_label(line: str) -> bool:
    return re.fullmatch(r"[A-Za-z_]\w*:", line) is not None

def label_name(line: str) -> str:
    return line[:-1]

def is_symbol(tok: str) -> bool:
    return re.fullmatch(r"[A-Za-z_]\w*", tok) is not None

# -------------------------
# Encoding
# -------------------------

def encode(parts, pc, labels):
    inst = parts[0].upper()

    if inst not in OPCODES:
        raise ValueError(f"Unknown instruction '{inst}'")

    op = OPCODES[inst]

    # ---- Immediate (6-bit)
    def imm6_from(tok: str) -> int:
        if is_symbol(tok):
            if tok not in labels:
                raise ValueError(f"Unknown label '{tok}'")
            off = labels[tok] - (pc + 1)
            if off < -32 or off > 31:
                raise ValueError(f"imm6 label offset out of range: {off}")
            return off & 0x3F
        return parse_imm6(tok)

    # ---- Packed offset (3-bit)
    def off3_from(tok: str) -> int:
        if is_symbol(tok):
            if tok not in labels:
                raise ValueError(f"Unknown label '{tok}'")
            off = labels[tok] - (pc + 1)
            if off < -4 or off > 3:
                raise ValueError(f"off3 label offset out of range: {off}")
            return off & 0x7
        return parse_off3(tok)

    # -------------------------
    # Instructions
    # -------------------------

    if inst == "HALT":
        return (op << 12)

    if inst == "ADD":
        rd = parse_reg(parts[1])
        rs = parse_reg(parts[2])
        rt = parse_reg(parts[3])
        return (op << 12) | (rd << 9) | (rs << 6) | (rt << 3)

    if inst == "CMP":
        rs = parse_reg(parts[1])
        rt = parse_reg(parts[2])
        return (op << 12) | (rs << 6) | (rt << 3)

    if inst in ("ADDI", "ANDI", "ORI", "LOAD"):
        rd = parse_reg(parts[1])
        rs = parse_reg(parts[2])
        imm6 = imm6_from(parts[3])
        return (op << 12) | (rd << 9) | (rs << 6) | imm6

    if inst in ("BEQ", "BNE"):
        rs = parse_reg(parts[1])
        rt = parse_reg(parts[2])
        off3 = off3_from(parts[3])
        return (op << 12) | (rs << 6) | (rt << 3) | off3

    if inst == "JMP":
        imm6 = imm6_from(parts[1])
        return (op << 12) | imm6

    if inst == "STORE":
        rt = parse_reg(parts[1])
        rs = parse_reg(parts[2])
        off3 = off3_from(parts[3])
        return (op << 12) | (rs << 6) | (rt << 3) | off3

    raise ValueError(f"Unsupported instruction '{inst}'")

# -------------------------
# Main
# -------------------------

def main():
    asm_in = "program.asm"
    mem_out = "program.mem"

    with open(asm_in, "r") as f:
        raw_lines = f.readlines()

    # PASS 1: labels
    labels = {}
    cleaned = []
    pc = 0

    for lineno, raw in enumerate(raw_lines, start=1):
        line = clean_line(raw)
        if not line:
            continue

        if is_label(line):
            name = label_name(line).upper()
            if name in labels:
                raise SystemExit(f"Duplicate label '{name}' on line {lineno}")
            labels[name] = pc
            continue

        cleaned.append((lineno, line))
        pc += 1

    # PASS 2: encode
    machine = []

    for pc, (lineno, line) in enumerate(cleaned):
        parts = line.split()
        parts = [p.upper() if is_symbol(p) else p for p in parts]

        try:
            instr = encode(parts, pc, labels)
        except Exception as e:
            raise SystemExit(f"Error on line {lineno}: {line}\n  {e}")

        machine.append(instr)

    with open(mem_out, "w") as f:
        for instr in machine:
            f.write(f"{instr:016b}\n")

    print(f"Wrote {mem_out} with {len(machine)} instructions.")
    if labels:
        print("Labels:", labels)

if __name__ == "__main__":
    main()
