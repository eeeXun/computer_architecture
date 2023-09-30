.data
num_1: .dword 0x0000000000000010

.text

main:
	la,  t0, num_1
	lw,  a0, 0(t0)
	lw,  a1, 4(t0)
	jal, ra, count_leading_zeros
	mv,  a1, a0
	li,  a0, 1
	jal, ra, logp2
	li,  a7, 1 # print
	ecall
	li   a7, 10 # exit
	ecall

# arg
# a0: num_l
# a1: num_u
count_leading_zeros:
	li, s0, 1
	li, s1, 32

# x |= (x >> 1)
# x |= (x >> 2)
# x |= (x >> 4)
# x |= (x >> 8)
# x |= (x >> 16)
# x |= (x >> 32)
_clz_loop:
	srl,  s2, a0, s0 # s2 = a0 >> s0
	sub,  t0, s1, s0 # t0 = 32 - s0
	sll,  t0, a1, t0 # t0 = a1 << (32 - s0)
	or,   s2, s2, t0 # s2 |= t0
	srl,  s3, a1, s0 # s3 = a1 >> s0
	slli, s0, s0, 1 # s0 *= 2
	or,   a0, a0, s2
	or,   a1, a1, s3
	bge   s1, s0, _clz_loop
	mv    s0, a0
	mv,   s1, a1

# continued from _clz_loop
# s0: num_l
# s1: num_u
_clz:
	srli, s2, s0, 1 # s2 = s0 >> 1
	slli, t0, s1, 31 # t0 = s1 << (32 - 1)
	or,   s2, s2, t0 # s2 |= t0
	srli, s3, s1, 1 # s3 = s1 >> 1
	li,   t0, 0x55555555
	and,  s2, s2, t0 # s2 = s2 & 0x55555555
	and,  s3, s3, t0 # s3 = s3 & 0x55555555
	sub,  t0, s0, s2 # t0 = s0 - s2
	sltu, t1, s0, t0 # borrow
	sub,  s1, s1, s3 # s1 = s1 - s3
	sub,  s1, s1, t1
	mv    s0, t0

	srli, s2, s0, 2 # s2 = s0 >> 2
	slli, t0, s1, 30 # t0 = s1 << (32 - 2)
	or,   s2, s2, t0 # s2 |= t0
	srli, s3, s1, 2 # s3 = s1 >> 2
	li,   t0, 0x33333333
	and,  s2, s2, t0 # s2 = s2 & 0x33333333
	and,  s3, s3, t0 # s3 = s3 & 0x33333333
	and,  s4, s0, t0 # s4 = s0 & 0x33333333
	and,  s5, s1, t0 # s5 = s1 & 0x33333333
	add,  s0, s2, s4
	sltu, t0, s0, s2 # carry
	add,  s1, s3, s5
	add,  s1, s1, t0

	srli, s2, s0, 4 # s2 = s0 >> 4
	slli, t0, s1, 28 # t0 = s1 << (32 - 4)
	or,   s2, s2, t0 # s2 |= t0
	srli, s3, s1, 4 # s3 = s1 >> 4
	add,  s4, s0, s2 # s4 = s0 + s2
	sltu, t0, s4, s0 # carry
	add,  s5, s1, s3 # s5 = s1 + s3
	add,  s5, s5, t0
	li,   t0, 0x0f0f0f0f
	and,  s0, s4, t0
	and,  s1, s5, t0

	srli, s2, s0, 8 # s2 = s0 >> 8
	slli, t0, s1, 24 # t0 = s1 << (32 - 8)
	or,   s2, s2, t0 # s2 |= t0
	srli, s3, s1, 8 # s3 = s1 >> 8
	add,  s0, s0, s2
	sltu, t0, s0, s2 # carry
	add,  s1, s1, s3
	add,  s1, s1, t0

	srli, s2, s0, 16 # s2 = s0 >> 16
	slli, t0, s1, 16 # t0 = s1 << (32 - 16)
	or,   s2, s2, t0 # s2 |= t0
	srli, s3, s1, 16 # s3 = s1 >> 16
	add,  s0, s0, s2
	sltu, t0, s0, s2 # carry
	add,  s1, s1, s3
	add,  s1, s1, t0

	mv,   s2, s1 # >> 32 => s2 = s1
	li,   s3, 0 # s3 = 0
	add,  s0, s0, s2
	sltu, t0, s0, s2 # carry
	add,  s1, s1, s3
	add,  s1, s1, t0

	li,   t0, 64
	andi, t1, s0, 0x7f
	sub,  a0, t0, t1
	jr,   ra

# arg
# a0: power (for power 2)
# a1: clz
# return
# a0: result
logp2:
	mv,  s0, a0
	mv,  s1, a1
	mv,  a0, zero
	li,  t0, 64
	sub, t0, t0, s1

logp2_loop:
	sub,  t0, t0, s0
	bge,  zero, t0, logp2_ret
	addi, a0, a0, 1
	j,    logp2_loop

logp2_ret:
	jr, ra
