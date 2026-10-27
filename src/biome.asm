.globl biome_type

.extern coord_tohash
.section .text

.macro clamp value, min, max, tmp 
    movss \min, \tmp
    maxss \tmp, \value

    movss \max, \tmp
    minss \tmp, \value
.endm

.type biome_type,@function
biome_type:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp

    movl %edi, -4(%rbp)      # x
    movl %esi, -8(%rbp)      # y
    movl %edx, -12(%rbp)     # z
    movl %r8d, -16(%rbp)     # seed

1:  # temperature
    movl -4(%rbp), %edi
    movl -8(%rbp), %esi
    movl -12(%rbp), %edx
    movl -16(%rbp), %r8d

    call coord_tohash
    cvtsi2ss %eax, %xmm0
    mulss scale(%rip), %xmm0
    clamp %xmm0, minu(%rip), maximum(%rip), %xmm4
    
2:  # humidity
    movl -4(%rbp), %edi
    movl -8(%rbp), %esi
    movl -12(%rbp), %edx
    movl -16(%rbp), %r8d
    addl $12345, %r8d

    call coord_tohash
    cvtsi2ss %eax, %xmm1
    mulss scale(%rip), %xmm1
    clamp %xmm1, minu(%rip), maximum(%rip), %xmm5
    movss %xmm1, -24(%rbp)

3:  # altitude
    cvtsi2ss -8(%rbp), %xmm2
    subss v64f(%rip), %xmm2
    mulss v0_0016f(%rip), %xmm2
    subss %xmm2, %xmm0

    clamp %xmm0, minu(%rip), maximum(%rip), %xmm4
    movss %xmm0, -20(%rbp)

4:
    movss -20(%rbp), %xmm0
    movss -24(%rbp), %xmm1
5:
    leaq type(%rip), %rsi
    movss distance(%rip), %xmm2
    xorl %eax, %eax

.Lloop:
    cmpq $end, %rsi
    jge .Lbiome

    movss 0(%rsi), %xmm3
    subss %xmm0, %xmm3
    mulss %xmm3, %xmm3

    movss 4(%rsi), %xmm4
    subss %xmm1, %xmm4
    mulss %xmm4, %xmm4

    addss %xmm4, %xmm3

    comiss %xmm2, %xmm3
    jae .Lnext

    movss %xmm3, %xmm2
    movl 8(%rsi), %eax
.Lnext:
    addq $12, %rsi
    jmp .Lloop

.Lbiome:

6:  # end
    leave
    ret


.section .rodata
    .balign 4
minu:       .float -1.0
maximum:    .float 1.0
v0_0016f:   .float 0.0016
v64f:       .float 64.0
distance:   .float 999.0
scale:      .float 4.656612875e-10

type:
    .float  1.0, -1.0;  .long 0   # Desert / Badlands
    .float  0.5, -0.5;  .long 1   # Savanna
    .float  0.0,  0.0;  .long 2   # Plains
    .float  0.0,  0.4;  .long 3   # Forest
    .float  0.8,  0.8;  .long 4   # Jungle
    .float -0.5,  0.2;  .long 5   # Taiga
    .float -1.0,  0.0;  .long 6   # Snowy Plains
    .float  0.2,  0.9;  .long 7   # Swamp
end:

/*
type:
    .float  0.65, -0.25,  0.4,   0.6,  0.0,  0.4,  0.65, 0.2,   0.75, 
    .float -0.75, -0.1,  -0.25,  0.35, 0.2,  0.6, -0.25, 0.25, -0.25,
    .float  0.2,  -0.75, -0.25, -0.2, -0.65, 0.2
biome_id:
    .long 0, 1, 2, 3, 4, 5, 6, 7
*/
