#define GPIO_SWs    0x80001400
#define GPIO_LEDs   0x80001404
#define GPIO_INOUT  0x80001408
#define SegEn_ADDR    0x80001038
#define SegDig_ADDR   0x8000103C

.globl _start
_start:

li x28, 0xFFFF                  # Enable LED registers
li x29, GPIO_INOUT              
sw x28, 0(x29)                  # Write the Enable Register

li x28, 0x0                     # Enable 7segment reigsters
li x29, SegEn_ADDR
sw x28, 0(x29)
li x29, SegDig_ADDR             # 7seg data address


li s1, 0x0                      # timer register
li s2, 0x0                      # beq register
li s3, 0x0                      # compass register
li s4, 0x0                      # indicator register
poll:
    li  a1, GPIO_SWs            # Read the Switches
    lw  t0, 0(a1)
    addi s1, s1, 1
    srl a1, t0, 27

    li t0, 0x0fff
    and s3, t0, s3

    li t1, 0x0
    or t1, t1, s4
    sll t1, t1, 12
    or s3, t1, s3

    sw s3, 0(x29)           # write to 7seg-reg

    beq a1, s2, stop # 0000
    add s2, s2, 1
    beq a1, s2, right1 # 0001
    add s2, s2, 1
    beq a1, s2, left1  # 0010
    add s2, s2, 1
    beq a1, s2, forward # 0011
    add s2, s2, 1
    beq a1, s2, left1 # 0100
    add s2, s2, 1
    beq a1, s2, stop # 0101
    add s2, s2, 1
    beq a1, s2, left2 # 0110
    add s2, s2, 1
    beq a1, s2, left1 # 0111
    add s2, s2, 1
    beq a1, s2, right1 # 1000
    add s2, s2, 1
    beq a1, s2, right2 # 1001
    add s2, s2, 1
    beq a1, s2, stop # 1010
    add s2, s2, 1
    beq a1, s2, right1 # 1011
    add s2, s2, 1
    beq a1, s2, reverse # 1100
    add s2, s2, 1
    beq a1, s2, right1 # 1101
    add s2, s2, 1
    beq a1, s2, left1 # 1110
    add s2, s2, 1
    beq a1, s2, stop # 1111
    li s2, 0x0000
    j poll

  #  li  a0, GPIO_LEDs
  #  srl t0, t0, 16
  #  sw  t0, 0(a0)               # Write the LEDs

stop:
    # li s2, 0x0
    # li t0, 0x0fff # digits to turn on g
    # and s3, s3, t0
    # li t0, 0xf000
    # or s3, s3, t0
    li s4, 0xf
    beq zero, zero, poll

forward:
    li s2, 0x0  # reset case register

    li s4, 0xa # turn off bits
    li t0, 0x20000
    blt s1, t0, fon # stay on if below t0 value
    li t0, 0x40000
    blt s1, t0, poll # stay on if below higher t0 value
    li s1, 0x0
    beq zero, zero, poll
fon:
    li s4, 0xb
    beq zero, zero, poll

reverse:
    li s2, 0x0  # reset case register

    li s4, 0xa # turn off bits
    li t0, 0x20000
    blt s1, t0, ron # stay on if below t0 value
    li t0, 0x40000
    blt s1, t0, poll # stay on if below higher t0 value
    li s1, 0x0
    beq zero, zero, poll
ron:
    li s4, 0xd
    beq zero, zero, poll

right1:
    li s2, 0x0                      # reset case statement
    li t0, 0x10000
    blt s1, t0, poll
    li s1, 0x0
    jal display_inc

right2:
    li s2, 0x0                      # reset case statement
    li t0, 0x5000
    blt s1, t0, poll
    li s1, 0x0
    jal display_inc

left1:
    li s2, 0x0                      # reset case statement
    li t0, 0x10000
    blt s1, t0, poll
    li s1, 0x0
    jal display_dec

left2:
    li s2, 0x0                      # reset case statement
    li t0, 0x5000
    blt s1, t0, poll
    li s1, 0x0
    jal display_dec

display_dec: # does the math to increment from 0-360, instead of 0-0xFFF
    addi s3, s3, -0x1

    li t1, 0xb
    blt t1, s4, num_dec   # 
    li s4, 0xf           # 
    # isolate and check lsB
num_dec:
    addi s4, s4, -0x1
    andi t0, s3, 0xf
    li t1, 0xf
    bne t1, t0, poll # if the value of the lsB is not eql to 0xa, then go display the ouput
    addi s3, s3, -0x6 # if the value is 0xf then set lsB to 0
 #   addi s3, s3, -0x010 # increment the next digit
    
    # isolate and check 2nd lsB
    andi t0, s3, 0x0F0
    li t1, 0xf0
    bne t1, t0, poll
    addi s3, s3, -0x60
    # increment 3rd lsB if 2nd byte overflowed
 #   addi s3, s3, -0x100

    li t1, 0xf00
    and t0, s3, t1
    bne t1, t0, poll
    li s3, 0x359
    beq zero, zero, poll

display_inc: # does the math to increment from 0-360, instead of 0-0xFFF
    addi s3, s3, 0x1

    li t1, 0xe
    blt s4, t1, num_inc   # if indicator is != f then go to next step
    li s4, 0xa            # if indicator is = f then, reset to a  

    # isolate and check lsB
num_inc:
    addi s4, s4, 0x1
    andi t0, s3, 0xF
    li t1, 0xa
    bne t1, t0, comp_out # if the value of the lsB is not eql to 0xa, then go display the ouput
    addi s3, s3, -0xa # if the value is 0xa then set lsB to 0
    addi s3, s3, 0x010 # increment the next digit
    
    # isolate and check 2nd lsB
    andi t0, s3, 0x0F0
    li t1, 0xa0
    bne t1, t0, comp_out
    addi s3, s3, -0xa0
    # increment 3rd lsB if 2nd byte overflowed
    addi s3, s3, 0x100

    beq zero, zero, comp_out
    


comp_out:
    # sw s3, 0(x29)           # write to 7seg-reg
    li t0, 0x0fff
    and t0, s3, t0
    li t1, 0x360
    bne t1,t0, poll # t1 != s3 then branch to poll
    li s3, 0x0 # else reset s3, then branch
    beq zero, zero, poll


.end