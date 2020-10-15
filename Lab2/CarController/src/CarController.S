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

li x29, SegDig_ADDR             # 7seg data address for Left digits
li x30, SegDig_ADDR2            # 7seg data add for right digits


li s1, 0x0                      # timer register
li s3, 0x0                      # compass register
li s4, 0x0                      # indicator register

# Poll: Increments timer, reads switches, cleans up overflow, 
# Write to 7segment register, Case statement jump
poll:
    addi s1, s1, 1              # increment counter

    li  t0, GPIO_But            # Read the Switches
    lw  a1, 0(t0)               # Store switch values in a1
    
    li t0, 0x000f0f0f           # clean up overflow/underflow
    and s3, s3, t0

    sll t0, s4, 24              # shift left into MSB
    or t0, s3, t0
    sw t0, 0(x30)               # write to 7seg-reg
    li t0, 0x00000000           # put zeros on left bits
    sw t0, 0(x29)               # write to 7seg-reg

# Case statement to jump to each state depending on button inputs
    li s2, 0x0000
    beq a1, s2, stop # 0000
    li s2, 0x0001
    beq a1, s2, right1 # 0001
    li s2, 0x0002
    beq a1, s2, left1  # 0010
    li s2, 0x0003
    beq a1, s2, forward # 0011
    li s2, 0x0004
    beq a1, s2, left1 # 0100
    li s2, 0x0005
    beq a1, s2, stop # 0101
    li s2, 0x0006
    beq a1, s2, left2 # 0110
    li s2, 0x0007
    beq a1, s2, left1 # 0111
    li s2, 0x0008
    beq a1, s2, right1 # 1000
    li s2, 0x0009
    beq a1, s2, right2 # 1001
    li s2, 0x000a
    beq a1, s2, stop # 1010
    li s2, 0x000b
    beq a1, s2, right1 # 1011
    li s2, 0x000c
    beq a1, s2, reverse # 1100
    li s2, 0x000d
    beq a1, s2, right1 # 1101
    li s2, 0x000e
    beq a1, s2, left1 # 1110
    li s2, 0x000f
    beq a1, s2, stop # 1111
    j poll

stop:
    li s4, 0x19                 # output "g" to 7seg
    beq zero, zero, poll        # return

forward:
    li s4, 0x11                 # turn off bits
    li t0, 0x20000              # timer value check
    blt s1, t0, fon             # stay on if below t0 value
    li t0, 0x40000              # 2nd timer value check
    blt s1, t0, poll            # stay on if below higher t0 value
    li s1, 0x0                  # reset timer
    beq zero, zero, poll
fon:
    li s4, 0x1a                 # turn on "a" segment
    beq zero, zero, poll

reverse:
    li s4, 0x11                 # turn off bits
    li t0, 0x20000              # timer value
    blt s1, t0, ron             # stay on if below t0 value
    li t0, 0x40000              # second timer value
    blt s1, t0, poll            # stay on if below higher t0 value
    li s1, 0x0                  # reset timer
    beq zero, zero, poll
ron:
    li s4, 0x1d                 # turn on "d" segment
    beq zero, zero, poll

right1:
    li t0, RLONG                # timer value for 10Hz
    blt s1, t0, poll            # check if timer overflow, return if not
    li s1, 0x0                  # reset timer if overflowed
    jal display_inc             # jmp to display_inc

right2:
    li t0, RSHORT               # timer for 15Hz
    blt s1, t0, poll            # check if timer overflow, return if not
    li s1, 0x0                  # reste timer if overflowed
    jal display_inc             # jmp to display_inc

left1:
    li t0, RLONG                # timer value for 10Hz 
    blt s1, t0, poll            # check if timer overflow, return if not
    li s1, 0x0                  # reset timer if overflowed
    jal display_dec             # jmp to display_dec

left2:
    li t0, RSHORT               # same as above code, check for 15Hz instead
    blt s1, t0, poll
    li s1, 0x0
    jal display_dec             

 # display_dec + num_dec: does the subtraction of s3, deals with underflow.
 # Will decrement each byte to match the necessary 7segment format
display_dec:                   
    addi s3, s3, -0x1           # subtract 1 from s3
    li t1, 0x1a                 # load 0x1a for indicator
    blt t1, s4, num_dec         # If t1, is less than S4, then decrement, to keep indicator aligned
                                # (if indicator is A, then this should fail since A is the last bit)
    li s4, 0x20                 # isolate and check lsB
num_dec:
    addi s4, s4, -0x1           # subtracts indicator value
    andi t0, s3, 0xf            # 
    li t1, 0x000f
    bne t1, t0, poll            # if the value of the lsB is not eql to 0xa, then go display the ouput
    addi s3, s3, -0x6           # if the value is 0xf then set lsB to 0
    
    # isolate and check 2nd lsB
    li t0, 0x0f00               # value for masking
    and t0, s3, t0              # mask all, but byte #2
    li t1, 0x0f00               # load value for compare
    bne t1, t0, poll            # return if no underflow
    addi s3, s3, -0x600         # if underflow, the subtract 0xf - 0x6 = 0x9

    li t1, 0xf0000              # mask all, but byte #4
    and t0, s3, t1              #
    bne t1, t0, poll            # check for underflow from 0x0 -> 0xfff...
    li s3, 0x030509             # if underflowed, then reset back to 359
    beq zero, zero, poll        # return

# display_inc+ num_inc (similar to functions display_dec+ num_dec)
# does the math to increment from 0-360, instead of 0-0xFFF
display_inc:                    
    addi s3, s3, 0x1            # increment by1
    li t1, 0x1f                 # load value to check indicator
    bne s4, t1, num_inc         # if S4 is less than t1 then this will fail
                                # We want this to succeed when S4 is 
    li s4, 0x19                 # reset indicator if it overflows

num_inc:
    addi s4, s4, 0x1            # increment indicator
    andi t0, s3, 0xf            # value to mask all but byte 0
    li t1, 0xa                  # value for compare
    bne t1, t0, comp_out        # if the value of the lsB is not eql to 0xa, then go display the ouput
    addi s3, s3, -0xa           # if the value is 0xa then set lsB to 0
    addi s3, s3, 0x0100         # increment the next digit
    
# isolate and check 2nd lsB
    li t0, 0x0f00               # mask all but byte #2
    and t0, s3, t0              # 
    li t1, 0xa00                # check for overflow to 0xa
    bne t1, t0, comp_out        # jump to comp_out if no overflow
    li t0, -0xa00               # subtract if overflow
    add s3, s3, t0 

# increment 3rd lsB if 2nd byte overflowed
    li t0, 0x10000
    add s3, s3, t0

    beq zero, zero, comp_out

# comp_out: resets s3 back to 0 when we reach 360
comp_out:
    li t0, 0xf0f0f              # mask all, but digits
    and t0, s3, t0              # mask
    li t1, 0x030600             # value for comparison
    bne t1,t0, poll             # t1 != s3 then branch to poll
    li s3, 0x0                  # else reset s3, then branch
    beq zero, zero, poll         

.end