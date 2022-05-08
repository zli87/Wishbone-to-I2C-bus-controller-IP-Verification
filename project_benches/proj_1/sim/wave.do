onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider I2C_MB
add wave -noupdate -divider {WB Signals}
add wave -noupdate /top/DUT/clk_i
add wave -noupdate /top/DUT/rst_i
add wave -noupdate /top/DUT/cyc_i
add wave -noupdate /top/DUT/stb_i
add wave -noupdate /top/DUT/ack_o
add wave -noupdate /top/DUT/adr_i
add wave -noupdate /top/DUT/we_i
add wave -noupdate /top/DUT/dat_i
add wave -noupdate /top/DUT/dat_o
add wave -noupdate /top/DUT/irq
add wave -noupdate -divider {I2C Signals}
add wave -noupdate /top/DUT/scl_i
add wave -noupdate /top/DUT/sda_i
add wave -noupdate /top/DUT/scl_o
add wave -noupdate /top/DUT/sda_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 263
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {888 ns}
