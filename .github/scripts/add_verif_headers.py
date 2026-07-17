from pathlib import Path
import re

HEADER_MARKER = "Copyright 2026 Avant Labs PVT LTD"
TOKEN_MAP = {
    "eiu": "EIU", "eth": "Ethernet", "ethernet": "Ethernet", "uart": "UART",
    "rx": "RX", "tx": "TX", "mac": "MAC", "cpu": "CPU", "phy": "PHY",
    "fifo": "FIFO", "bkp": "BKP", "krd": "KRD", "kst": "KST", "kwr": "KWR",
    "nrz": "NRZ", "inp": "input", "out": "output", "app": "application",
    "env": "environment", "cfg": "configuration", "config": "configuration",
    "intf": "interface", "if": "interface", "seq": "sequence", "seqs": "sequences",
    "vseq": "virtual sequence", "vsqr": "virtual sequencer", "vsqncr": "virtual sequencer",
    "pkt": "packet", "pkts": "packets", "rd": "read", "wr": "write",
    "duplex": "duplex", "standalone": "standalone", "loopback": "loopback",
    "unified": "unified", "common": "common", "cuboid": "cuboid", "dynamic": "dynamic",
    "chaos": "chaos", "clean": "clean", "smart": "smart", "physical": "physical",
    "whitebox": "whitebox", "host": "host", "line": "line", "serial": "serial",
    "fault": "fault", "inject": "injection", "injector": "injector", "error": "error",
    "data": "data", "main": "main", "static": "static", "stimulus": "stimulus",
    "master": "master", "short": "short", "long": "long", "new": "new",
}
ROLE_TOKENS = {
    "agent", "driver", "monitor", "config", "cfg", "env", "scoreboard", "sequence",
    "seq", "seqs", "item", "pkg", "package", "test", "base", "tb", "top",
    "intf", "if", "interface", "vseq", "vsqr", "vsqncr",
}
CONTEXT_BY_TOP = {"EIU": "EIU", "eth_1": "Ethernet", "kernel": "Kernel", "uart_1": "UART"}
REPLACEMENTS = {
    "top-level testbench for EIU vlib verification": "top-level testbench for EIU verification",
    "top-level testbench for Ethernet vlib verification": "top-level testbench for Ethernet verification",
    "top-level testbench for Kernel vlib verification": "top-level testbench for Kernel verification",
    "top-level testbench for UART vlib verification": "top-level testbench for UART verification",
    "UVM environment for loopback uartfifo verification": "UVM environment for UART loopback FIFO verification",
    "UVM package for loopback uartfifo verification": "UVM package for UART loopback FIFO verification",
    "UVM scoreboard for loopback uartfifo verification": "UVM scoreboard for UART loopback FIFO verification",
    "top-level testbench for loopback UART FIFO verification": "top-level testbench for UART loopback FIFO verification",
    "long UVM test for UART long verification": "long UVM test for UART verification",
    "UVM test for UART new verification": "UVM test for UART verification",
    "short UVM test for UART RX short verification": "short UVM test for UART RX verification",
    "short UVM test for UART short verification": "short UVM test for UART verification",
    "UVM sequence for UART FIFO sequences verification": "UVM sequence collection for UART FIFO verification",
}

def context_for(path: Path) -> str:
    return CONTEXT_BY_TOP.get(path.parts[1], path.parts[1]) if len(path.parts) > 1 else "verification"

def split_tokens(stem: str):
    return [tok for tok in re.sub(r"\s+", " ", stem.lower().replace(".", " ").replace("-", " ").replace("_", " ")).strip().split(" ") if tok]

def context_present(words, context):
    joined = " ".join(words).lower()
    return context.lower() in joined or (context == "Ethernet" and "ethernet" in joined) or (context == "UART" and "uart" in joined) or (context == "EIU" and "eiu" in joined) or (context == "Kernel" and "kernel" in joined)

def subject_from_path(path: Path):
    stem = path.stem
    if stem.lower() in {"test", "scoreboard", "env", "tb_top", "top_tb"}:
        stem = f"{path.parent.name}_{stem}"
    tokens = split_tokens(stem)
    kept = [] if ("command" in tokens or "commands" in tokens) else [tok for tok in tokens if tok not in ROLE_TOKENS]
    words = [TOKEN_MAP.get(tok, tok) for tok in kept]
    context = context_for(path)
    if not words:
        return context
    if not context_present(words, context):
        words = [context] + words
    collapsed = []
    for word in words:
        if not collapsed or collapsed[-1].lower() != word.lower():
            collapsed.append(word)
    return " ".join(collapsed)

def description_for(path: Path) -> str:
    parts = set(path.parts)
    name = path.name.lower()
    stem = path.stem.lower()
    subject = subject_from_path(path)
    context = context_for(path)
    if "commands" in name and "run" in name:
        return f"simulation command notes for {context} verification"
    if "vlib" in parts:
        return f"top-level testbench for {subject} verification"
    if "test" in parts:
        if stem.endswith("base_test"):
            return f"base UVM test for {subject} verification"
        if "short_test" in stem:
            return f"short UVM test for {subject} verification"
        if "long_test" in str(path).lower():
            return f"long UVM test for {subject} verification"
        return f"UVM test for {subject} verification"
    if "sequence_item" in parts:
        return f"UVM sequence item for {subject} verification"
    if "sequence" in parts:
        if "vsqr" in stem or "vsqncr" in stem:
            return f"UVM virtual sequencer for {subject} verification"
        if "vseq" in stem:
            return f"UVM virtual sequence for {subject} verification"
        if stem.endswith("seqs") or "_seqs" in stem:
            return f"UVM sequence collection for {subject} verification"
        return f"UVM sequence for {subject} verification"
    if "scoreboard" in parts:
        return f"UVM scoreboard for {subject} verification"
    if "env" in parts:
        return f"UVM environment for {subject} verification"
    if "config" in parts:
        return f"UVM configuration object for {subject} verification"
    if "agent" in parts:
        if stem.endswith("driver"):
            return f"UVM driver for {subject} verification"
        if stem.endswith("monitor"):
            return f"UVM monitor for {subject} verification"
        if stem.endswith("agent"):
            return f"UVM agent for {subject} verification"
        return f"UVM agent component for {subject} verification"
    if "interface" in parts:
        return f"SystemVerilog interface for {subject} verification"
    if "package" in parts or "pkg" in parts:
        return f"UVM package for {subject} verification"
    return f"SystemVerilog verification component for {subject} verification"

def header_for(path: Path) -> str:
    return f"""////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : {path.name}
//  Author        : Ahmed Ali
//  Creation Date : 16/04/2026
//
//  Copyright 2026 Avant Labs PVT LTD. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    First Floor, Jumaira Arcade,
//    Fateh Jang Road,
//    Sector F-17, Islamabad, 45230
//
//  All information contained in this document is Avant Labs PVT LTD
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  {description_for(path)}
////////////////////////////////////////////////////////////////////////////////

"""

def main():
    files = sorted(Path("verif").rglob("*.sv")) + sorted(Path("verif").rglob("*.svh"))
    changed = 0
    for path in files:
        data = path.read_text(errors="surrogateescape")
        if HEADER_MARKER not in data[:2500]:
            path.write_text(header_for(path) + data, errors="surrogateescape")
            changed += 1
    for path in files:
        data = path.read_text(errors="surrogateescape")
        updated = data
        for old, new in REPLACEMENTS.items():
            updated = updated.replace(old, new)
        if updated != data:
            path.write_text(updated, errors="surrogateescape")
    print(f"Added headers to {changed} files")

if __name__ == "__main__":
    main()
