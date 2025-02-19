transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vmap -link {C:/Users/cam82/OneDrive/Documents/College/FA23ECE385/lab62/lab62a/lab62a.cache/compile_simlib/riviera}
vlib riviera/xil_defaultlib

vlog -work xil_defaultlib  -incr -v2k5 -l xil_defaultlib \
"../../../../lab62a.gen/sources_1/ip/hdmi_tx_0/hdl/encode.v" \
"../../../../lab62a.gen/sources_1/ip/hdmi_tx_0/hdl/serdes_10_to_1.v" \
"../../../../lab62a.gen/sources_1/ip/hdmi_tx_0/hdl/srldelay.v" \
"../../../../lab62a.gen/sources_1/ip/hdmi_tx_0/hdl/hdmi_tx_v1_0.v" \
"../../../../lab62a.gen/sources_1/ip/hdmi_tx_0/sim/hdmi_tx_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

