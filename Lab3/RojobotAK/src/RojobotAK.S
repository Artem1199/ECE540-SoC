# Place holder register values
#define MOTCTL_IN   0x80001500 
#define LOCX_REG    0x80001540
#define LOCY_REG    0x80001580
#define BOTINFO_REG 0x80001600
#define SENSOR_REG  0x80001640


# Artem Kulakevich - 12 Oct 2020
# RojoBOT RISC-V Program
# Input:        Verilog Rojobot from Memory
# Output:       Motion controls Memory
# Description: 

.globl _start
_start:

li s7, MOTCTL_IN
li s8, LOCX_REG
li s9, LOCY_REG
li s10, BOTINFO_REG
li s11, SENSOR_REG
////////////////////////////////////////////////////////////////////////////////////////
// |map1[7] | map0[6] | x[5] | ProxL[4] | ProxR[3] | BlkLL[2] | BlkLC[1] | BlkLR[0] | //
////////////////////////////////////////////////////////////////////////////////////////

rd_sensor:
    lw t0, 0(s11)
    andi t0, t0, 0x7  # Mask all but 1st 3 bits

    li t1, 0x4  # 100 
    beq t0, t1, right
    li t1, 0x1  # 001
    beq t0, t1, left
    li t1, 0x5  # 101
    beq t0, t1, fwd
    li t1, 0x6  # 110
    beq t0, t1, rev_right
    li t1, 0x3  # 011
    beq t0, t1, rev_left

bne zero, zero, rd_sensor



fwd:
    # no reg to save
    li t0, 0x33     # 001 1 001 1 (Move forward @ 1 speed)
    sw t0, 0(s7)
    bne zero, zero, rd_sensor           # return

rev_right:
    li t0, 0x22     # 001 0 001 0 (Move back @ 1 speed)
    sw t0, 0(s7)
    
    li t0, 0x30     # 001 1 000 0 (Turn right 45 Deg)
    sw t0, 0(s7)

    bne zero, zero, rd_sensor

rev_left:
    li t0, 0x22     # 001 0 001 0 (Move back @ 1 speed)
    sw t0, 0(s7)

    li t0, 0x03     # 000 0 001 1 (Turn Left 45 Deg)
    sw t0, 0(s7)

    bne zero, zero, rd_sensor

right:
    li t0, 0x32     # 001 1 001 0 (Turn Right 90Deg)
    sw t0, 0(s7)

    bne zero, zero, rd_sensor

left:
    li t0, 0x23     # 001 1 001 0 (Turn left 90Deg)
    sw t0, 0(s7)

    bne zero, zero, rd_sensor

.end