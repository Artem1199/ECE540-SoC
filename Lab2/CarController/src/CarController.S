#define GPIO_But    0x80001440
#define SegDig_ADDR2  0x8000103c
#define SegDig_ADDR  0x80001038
#define RSHORT       0x4000
#define RLONG        0x8000

# Artem Kulakevich - 12 Oct 2020
# SimpleBot RISC-V Program
# Input: 4 PushButton inputs on Nexys-A7 demo board
# Output: 7 Segment display on demo board
# Description: Displays direction in degrees in the first 3 digits (0-359) for a faux robot.
#              4th digit displays an indicator that shows the direction of robot movement by
#              either chasing CCW, CC or blinking forward/back.

.globl _start
_start:

li s9, 0x0
li s1, 0x1
li x1, 0x1
li s2, 0x5
li s3, 0x00000004
start:
sw x1, 0(s3)
addi s9, s9, 0x1
bne s9, x1, start
inc:
sw s1, 0(s3)
beq s1, x1, start
addi s1, s1, 0x1
bne s1, x1, inc
addi x1, x1, 0x1
bne x1, s2, start

ori s0, s2, 0x3

.end