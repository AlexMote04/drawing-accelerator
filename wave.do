# 1. Clear previous waves
delete wave *

# 2. Add Global Signals
add wave -noupdate -divider "Global"
add wave -noupdate -color white /unit_Testbench/clk
add wave -noupdate -color yellow /unit_Testbench/rst_n

# 3. Add Input Commands
add wave -noupdate -divider "Command Inputs"
add wave -noupdate /unit_Testbench/req
add wave -noupdate /unit_Testbench/ack
add wave -noupdate /unit_Testbench/busy
add wave -noupdate -radix unsigned -group "Registers" /unit_Testbench/r*

# 4. Add Memory Interface (CRITICAL FOR DEBUGGING)
add wave -noupdate -divider "Output (Mem Interface)"
add wave -noupdate -color cyan /unit_Testbench/de_req
add wave -noupdate -color cyan /unit_Testbench/de_ack
# View Address in Decimal to match your coordinates (X, Y) logic
add wave -noupdate -radix hex /unit_Testbench/de_addr
# View Byte Enable in Binary to see which byte is active
add wave -noupdate -radix binary /unit_Testbench/de_nbyte
# View Data in Hex to match your color codes (0x99, etc.)
add wave -noupdate -radix hex /unit_Testbench/de_data

# 5. Formatting
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
