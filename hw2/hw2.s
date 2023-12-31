.data
# test data 
test0: .word 0x4141f9a7,0x423645a2 
test1: .word 0x3fa66666,0x42c63333
test2: .word 0x43e43a5e,0x42b1999a

#string
str: .string "\n"

.text
main:
    li a7,1     
    la a2,test0           # load test data address to a2
    lw a6,0(a2)           # load test data to a6
    jal ra,f32_b16_p1     # call fp32 to bf16 function 
    add a5,a6,x0          # store first bfloat in a5
    
    lw a6,4(a2)           # load test data to a6
    jal ra,f32_b16_p1     # jump to float32 transform to bfloat function 
    add a4,a6,x0          # store the result to a4
    
    jal ra,encoder        # jump to encoder funtion
    add s9,s3,x0          # save s3(data after encode) to s9
    jal ra,decoder        # jump to decoder function
    jal ra,Multi_bfloat   # jump to bfloat Multiplication funcition
    
    # Output second bfloat after decoder
    li a7,2               # set a7 as float mode 
    add a0,x0,s5          # set a0 as s5 
    ecall                 # ecall
    
    # change line
    li a7,4               # set a7 as string mode 
    la a0,str             # load str to a0
    ecall                 # ecall 
    
    # Output first bfloat after decoder
    li a7,2               # set a7 as float mode  
    add a0,x0,s6          # set a0 as s6
    ecall                 # ecall
    
    # change line
    li a7,4               # set a7 as string mode 
    la a0,str             # load str to a0
    ecall                 # ecall 
    
    # Output Multiplication result
    li a7,2               # set a7 as float mode                
    add a0,x0,s3          # set a0 as s3(Multiplication results)      
    ecall                 # ecall
    
    j exit                # jump to exit this program

### function converts IEEE754 fp32 to bfloat16
f32_b16_p1:
    sw a6,0(sp)
    add t0,a6,x0          # a6 will be only for this funtion to access
    
    # exponent
    li t6,0x7F800000
    and t1,t0,t6          # let exponent save to t1
    
    # fraction
    li t6,0x007FFFFF
    and t2,t0,t6          # let fraction save to t2
    
    # check this number if 0 or inf (exponent + fraction)
    li t6,0x7F800000
    beq t1,t6,inf_or_zero # exp == 0x7F800000
    or t3,t1,t2 
    beq t3,x0,inf_or_zero # exp == 0 && man == 0 
    
    # add integer to fraction
    li t6,0x800000
    or t2,t2,t6           # add integer
    
    # round to nearest for fraction
    li t6,0x8000
    add t2,t2,t6          # add round number
    srli t5,t2,24         # shift left 24 to t5 
    beq t5,x0,no_overflow # if t5 equal to 0 move to no_overflow
    # if overflow
    li t6,0x800000
    add t1,t1,t6          # add 1 to exponent
    srli t2,t2,17         # shift t2 to left 1 integer and 7 fraction
    li t6,0x7f
    and t2,t2,t6          # let t2 only have integer
    slli t2,t2,16         # shift right 16
    j f32_b16_p2
    # if not overflow
no_overflow:
    srli t2,t2,16         # shift t2 to left 1 integer and 7 fraction
    li t6,0x7f
    and t2,t2,t6          # let t2 only have integer
    slli t2,t2,16         # shift right 16
    #f32_b16 end function
f32_b16_p2:
    # save to a6
    srli t0,t0,31         # shift left to let t0 remain sign
    slli t0,t0,31         # shift right to let t0 sign to the right position
    or t0,t0,t1           # combine sign and exponent together
    or t0,t0,t2           # combine sign,exponent and fraction together
    add a6,t0,x0          # save t0 to a6
    ret                   # move back to main function
    
inf_or_zero:  
    srli a6,a6,16        
    slli a6,a6,16
    ret                   # return to main
### end of funtion  
    
### encode two bfloat to one register
encoder:
    add t0,a5,x0          # load a5(first bfloat) to t0
    add t1,a4,x0          # load a4(second bfloat) to t1
    srli t1,t1,16         # shift to let second bfloat fit in one register
    or t0,t0,t1           # combine two bfloat in one register
    add s3,t0,x0          # load t0 to s3
    ret                   # return to main
    
### decode two bfloat on one register to two registers
decoder:
    add t0,s9,x0          # load s9(data encode) to t0
    li s2,0xFFFF0000
    and t1,t0,s2          # use mask to specification bfloat 1
    slli t2, t0, 16
    add s6,t1,x0          # store t1(bfloat 1) to s6
    add s5,t2,x0          # store t2(bfloat 2) to s5
    ret                   # return to main

### Multiplication with bfloat in one register
Multi_bfloat:
    # decoder function input is a0
    # jal ra,decoder        # load a0(two bloat number in one register) to t0
    # decoder function output is s5,s6
    add t0,s5,x0          # store s5(bfloat 2) to t0
    add t1,s6,x0          # store s6(bfloat 1) to t1
    li t6,0x7F800000
    # get exponent to t2,t3
    and t3,t0,t6          # use mask 0x7F800000 to get t0 exponent
    and t2,t1,t6          # use mask 0x7F800000 to get t1 exponent
    add t3,t3,t2          # add two exponent to t3
    li t6,0x3F800000
    sub t3,t3,t6          # sub 127 to exponent

    # get sign
    xor t2,t0,t1          # get sign and store on t2
    srli t2,t2,31         # get rid of useless data
    slli t2,t2,31         # let sign back to right position
    
    # get sign and exponent together
    or t3,t3,t2
    # set the sign and exponent to t0
    slli t0,t0,9
    srli t0,t0,9
    or t0,t3,t0

    # get fraction to t2 and t3
    li t6,0x7F0000        # shift mask to 0x7F0000
    and t2,t0,t6          # use mask 0x7F0000 get fraction
    and t3,t1,t6          # use mask 0x7F0000 get fraction
    slli, t2,t2,8
    li t6,0x80000000
    or t2,t2,t6           # use mask 0x80000000 to add integer
    srli t2,t2,1          # shift right to add space for overflow

    slli t3,t3,8          # shift left let no leading 0
    or t3,t3,t6           # use mask 0x80000000 to add integer
    srli t3,t3,1          # shift right to add space for overflow

    add t1,x0,x0          # reset t1 to 0 and let this register be result
    li t6,0x80000000

# unroll multiplication 8 times
    srli t6,t6,1          # shift right at 1 every loop
    and t4,t2,t6          # use mask to specified number at that place
    sltu s0,zero,t4       # s0 = 1 if t4 > 0, otherwise 0
    sub s0,zero,s0        # s0 = 0xFFFFFFFF if s0 = 1, otherwise 0
    and s1,s0,t3
    add t1,t1,s1          # add t3 to s1
    srli t3,t3,1          # shift left 1 bit to t3

    srli t6,t6,1          # shift right at 1 every loop
    and t4,t2,t6          # use mask to specified number at that place
    sltu s0,zero,t4       # s0 = 1 if t4 > 0, otherwise 0
    sub s0,zero,s0        # s0 = 0xFFFFFFFF if s0 = 1, otherwise 0
    and s1,s0,t3
    add t1,t1,s1          # add t3 to s1
    srli t3,t3,1          # shift left 1 bit to t3

    srli t6,t6,1          # shift right at 1 every loop
    and t4,t2,t6          # use mask to specified number at that place
    sltu s0,zero,t4       # s0 = 1 if t4 > 0, otherwise 0
    sub s0,zero,s0        # s0 = 0xFFFFFFFF if s0 = 1, otherwise 0
    and s1,s0,t3
    add t1,t1,s1          # add t3 to s1
    srli t3,t3,1          # shift left 1 bit to t3

    srli t6,t6,1          # shift right at 1 every loop
    and t4,t2,t6          # use mask to specified number at that place
    sltu s0,zero,t4       # s0 = 1 if t4 > 0, otherwise 0
    sub s0,zero,s0        # s0 = 0xFFFFFFFF if s0 = 1, otherwise 0
    and s1,s0,t3
    add t1,t1,s1          # add t3 to s1
    srli t3,t3,1          # shift left 1 bit to t3

    srli t6,t6,1          # shift right at 1 every loop
    and t4,t2,t6          # use mask to specified number at that place
    sltu s0,zero,t4       # s0 = 1 if t4 > 0, otherwise 0
    sub s0,zero,s0        # s0 = 0xFFFFFFFF if s0 = 1, otherwise 0
    and s1,s0,t3
    add t1,t1,s1          # add t3 to s1
    srli t3,t3,1          # shift left 1 bit to t3

    srli t6,t6,1          # shift right at 1 every loop
    and t4,t2,t6          # use mask to specified number at that place
    sltu s0,zero,t4       # s0 = 1 if t4 > 0, otherwise 0
    sub s0,zero,s0        # s0 = 0xFFFFFFFF if s0 = 1, otherwise 0
    and s1,s0,t3
    add t1,t1,s1          # add t3 to s1
    srli t3,t3,1          # shift left 1 bit to t3

    srli t6,t6,1          # shift right at 1 every loop
    and t4,t2,t6          # use mask to specified number at that place
    sltu s0,zero,t4       # s0 = 1 if t4 > 0, otherwise 0
    sub s0,zero,s0        # s0 = 0xFFFFFFFF if s0 = 1, otherwise 0
    and s1,s0,t3
    add t1,t1,s1          # add t3 to s1
    srli t3,t3,1          # shift left 1 bit to t3

    srli t6,t6,1          # shift right at 1 every loop
    and t4,t2,t6          # use mask to specified number at that place
    sltu s0,zero,t4       # s0 = 1 if t4 > 0, otherwise 0
    sub s0,zero,s0        # s0 = 0xFFFFFFFF if s0 = 1, otherwise 0
    and s1,s0,t3
    add t1,t1,s1          # add t3 to s1
    srli t3,t3,1          # shift left 1 bit to t3
# end of unroll 
  
    # check if overflow
    li t6,0x80000000
    and t4,t1,t6          # get t1 max bit
    
    # if t4 max bit equal to 0 will not overflow
    beq t4,x0,not_overflow
    
    # if overflow
    slli t1,t1,1          # shift left 1 bits to remove integer
    li t6,0x800000
    add t0,t0,t6          # exponent add 1 if overflow
    j Mult_end            # jump to Mult_end
     
    # if not overflow
not_overflow:
    slli t1,t1,2          # shift left 2 bits to remove integer
Mult_end:
    srli t1,t1,24         # shift right to remove useless bits
    addi t1,t1,1          # add 1 little bit to check if carry
    srli t1,t1,1          # shift right to remove useless bits
    slli t1,t1,16         # shift left to let fraction be right position
    
    srli t0,t0,23         # shift right to remove useless bits
    slli t0,t0,23         # shift left to let sign and exponent be right position
    or t0,t0,t1           # combine t0 and t1 together to get bfloat

    add s3,t0,x0          # store bfloat after multiplication to  s3
    ret                   # return to main
### end of function    

exit:
    li a7,10              # set a7 as exit
    ecall                 # ecall
    
############ Check every bits
# li a7,35                # set a7 as binary mode
# add a0,t0,x0            # store print data to a0
# ecall                   # ecall
############
