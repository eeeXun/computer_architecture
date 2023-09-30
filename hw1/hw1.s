.data
num_1: .dword 0x0000000000000010

.text

main:
	li,  a0, 1
	la,  t0, num_1
	lw,  a1, 0(t0)
	lw,  a2, 4(t0)
	jal, ra, shift_or_loop
	mv,  a1, a0
	li,  a0, 1
	jal, ra, log2p
	li,  a7, 1 # print
	ecall
	li   a7, 10 # exit
	ecall

# x |= (x >> 1)
# x |= (x >> 2)
# x |= (x >> 4)
# x |= (x >> 8)
# x |= (x >> 16)
# x |= (x >> 32)
# arg
# a0: shift_times
# a1: num_l
# a2: num_u
shift_or_loop:
	addi, sp, sp, -16 # push
	sw,   ra, 0(sp)
	sw,   a0, 4(sp)
	sw,   a1, 8(sp)
	sw,   a2, 12(sp)
	jal,  ra, shift_right
	mv,   t0, a0
	mv,   t1, a1
	lw,   ra, 0(sp)
	lw,   s0, 4(sp)
	lw,   s1, 8(sp)
	lw,   s2, 12(sp)
	addi, sp, sp, 16 # pop
	slli, a0, s0, 1
	or,   a1, s1, t0
	or,   a2, s2, t1
	li,   t0, 32
	bge   t0, a0, shift_or_loop
	mv    s0, a1
	mv,   s1, a2

# continued from shift_or_loop
# arg
# s0: num_l
# s1: num_u
count_leading_zeros:
	addi, sp, sp, -12 # push
	sw,   ra, 0(sp)
	sw,   s0, 4(sp)
	sw,   s1, 8(sp)
	li,   a0, 1
	mv,   a1, s0
	mv,   a2, s1
	jal,  ra, shift_right
	li,   t0, 0x55555555
	and,  t1, a0, t0
	and,  t2, a1, t0
	lw,   a0, 4(sp)
	lw,   a1, 8(sp)
	mv    a2, t1
	mv    a3, t2
	jal   ra, uint64_sub
	mv,   s0, a0
	mv,   s1, a1
	lw,   ra, 0(sp)
	addi, sp, sp, 12 # pop

	addi, sp, sp, -12 # push
	sw,   ra, 0(sp)
	sw,   s0, 4(sp)
	sw,   s1, 8(sp)
	li,   a0, 2
	mv,   a1, s0
	mv,   a2, s1
	jal,  ra, shift_right
	li,   t0, 0x33333333
	and,  s0, a0, t0
	and,  s1, a1, t0
	lw,   s2, 4(sp)
	lw,   s3, 8(sp)
	and,  s2, s2, t0
	and,  s3, s3, t0
	mv,   a0, s0
	mv,   a1, s1
	mv,   a2, s2
	mv,   a3, s3
	jal,  ra, uint64_add
	lw,   ra, 0(sp)
	addi, sp, sp, 12 # pop

	addi,   sp, sp, -12 # push
	sw,     ra, 0(sp)
	sw,     a0, 4(sp)
	sw,     a1, 8(sp)
	li,     a0, 4
	lw,     a1, 4(sp)
	lw,     a2, 8(sp)
	jal,    ra, shift_right
	lw,     a2, 4(sp)
	lw,     a3, 8(sp)
	jal,ra, uint64_add
	li,     t0, 0x0f0f0f0f
	and,    a0, a0, t0
	and,    a1, a1, t0
	lw,     ra, 0(sp)
	addi,   sp, sp, 12 # pop

	addi, sp, sp, -12 # push
	sw,   ra, 0(sp)
	sw,   a0, 4(sp)
	sw,   a1, 8(sp)
	li,   a0, 8
	lw,   a1, 4(sp)
	lw,   a2, 8(sp)
	jal,  ra, shift_right
	lw,   a2, 4(sp)
	lw,   a3, 8(sp)
	jal,  ra, uint64_add
	lw,   ra, 0(sp)
	addi, sp, sp, 12 # pop

	addi, sp, sp, -12 # push
	sw,   ra, 0(sp)
	sw,   a0, 4(sp)
	sw,   a1, 8(sp)
	li,   a0, 16
	lw,   a1, 4(sp)
	lw,   a2, 8(sp)
	jal,  ra, shift_right
	lw,   a2, 4(sp)
	lw,   a3, 8(sp)
	jal,  ra, uint64_add
	lw,   ra, 0(sp)
	addi, sp, sp, 12 # pop

	addi, sp, sp, -12 # push
	sw,   ra, 0(sp)
	sw,   a0, 4(sp)
	sw,   a1, 8(sp)
	li,   a0, 32
	lw,   a1, 4(sp)
	lw,   a2, 8(sp)
	jal,  ra, shift_right
	lw,   a2, 4(sp)
	lw,   a3, 8(sp)
	jal,  ra, uint64_add
	lw,   ra, 0(sp)
	addi, sp, sp, 12 # pop

	li,   s0, 64
	andi, t0, a0, 0x7f
	sub,  a0, s0, t0
	jr,   ra

# arg
# a0 for shift_times
# a1 for num_l
# a2 for num_u
# return
# a0 for num_l
# a1 for num_u
shift_right:
	srl, s0, a1, a0 # s0 = (num_l >> shift_times)
	li,  t0, 32
	sub, t0, t0, a0 # t0 = 32 - shift_times
	sll, t1, a2, t0 # t1 = (num_u << t0)
	or,  s0, s0, t1 # s0 = (s0 | t0)
	srl, s1, a2, a0 # s1 = (num_u >> shift_times)
	mv,  a0, s0
	mv,  a1, s1
	jr,  ra

# arg
# a0 for num_l of summand
# a1 for num_u of summand
# a2 for num_l of addend
# a3 for num_u of addend
# return
# a0 for num_l
# a1 for num_u
uint64_add:
	add,  s0, a0, a2
	sltu, t0, s0, a0 # carry, from compiler
	add,  s1, a1, a3
	add,  s1, s1, t0
	mv,   a0, s0
	mv,   a1, s1
	jr,   ra

# arg
# a0 for num_l of minuend
# a1 for num_u of minuend
# a2 for num_l of subtrahend
# a3 for num_u of subtrahend
# return
# a0 for num_l
# a1 for num_u
uint64_sub:
	sub,  s0, a0, a2
	sltu, t0, a0, s0 # borrow, from compiler
	sub,  s1, a1, a3
	sub,  s1, s1, t0
	mv,   a0, s0
	mv,   a1, s1
	jr,   ra

# arg
# a0: power (for power 2)
# a1: clz
# return
# a0: result
log2p:
	mv,  s0, a0
	mv,  s1, a1
	mv,  a0, zero
	li,  t0, 64
	sub, t0, t0, s1

log2p_loop:
	sub,  t0, t0, s0
	bge,  zero, t0, log2p_ret
	addi, a0, a0, 1
	j,    log2p_loop

log2p_ret:
	jr, ra
