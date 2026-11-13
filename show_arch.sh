#!/bin/bash
cd /home/kali/Risc-v-
rm -f *.o *.cf top_level
ghdl -i --std=08 *.vhdl
ghdl -m --std=08 top_level
yosys -q -m ghdl -p "ghdl --std=08 top_level; hierarchy -top top_level; proc; write_json riscv_netlist.json"
netlistsvg riscv_netlist.json -o circuit_schematic.svg
rm -f *.o *.cf top_level riscv_netlist.json
firefox riscv_block_diagram.svg circuit_schematic.svg &
