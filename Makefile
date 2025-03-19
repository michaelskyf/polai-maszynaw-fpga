BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: top.fs

# Synthesis
top.json: top.sv
	yosys -p "read_verilog -sv top.sv led_driver.sv; synth_gowin -top top -json top.json"

# Place and Route
top_pnr.json: top.json
	nextpnr-himbaechel --force --top top --json top.json --freq 27 --write top_pnr.json --device ${DEVICE} --vopt family=${FAMILY} --vopt cst=${BOARD}.cst

# Generate Bitstream
top.fs: top_pnr.json
	gowin_pack -d ${FAMILY} -o top.fs top_pnr.json

# Program Board
load: top.fs
	openFPGALoader -b ${BOARD} top.fs -f

.PHONY: load
.INTERMEDIATE: top_pnr.json top.json