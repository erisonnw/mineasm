.globl set_block
.globl get_block
.globl break_block

.extern loaded
.extern chunk
.section .text

.type get_block,@function
get_block:
    subq $48, %rsp

    movl %edi, 0(%rsp)
    movl %esi, 4(%rsp)
    movl %edx, 8(%rsp)

    movl 4(%rsp), %esi
    cmpl $0, %esi
    jl .Lair
    cmpl $24, %esi
    jge .Lair

    cvtsi2ss 0(%rsp), %xmm0
    divss v16f(%rip), %xmm0
    roundss $1, %xmm0, %xmm0
    cvttss2si %xmm0, %r8d

    cvtsi2ss 8(%rsp), %xmm0
    divss v16f(%rip), %xmm0
    roundss $1, %xmm0, %xmm0
    cvttss2si %xmm0, %r9d

    movl %r8d, 12(%rsp)
    movl %r9d, 16(%rsp)

    movl %r8d, %edi 
    movl %r9d, %esi
    call chunk

    testq %rax, %rax
    jz .Lair

    movq %rax, %r10

    movl 12(%rsp), %r8d
    imull $16, %r8d, %r8d
    movl 0(%rsp), %edi
    subl %r8d, %edi

    movl 16(%rsp), %r9d
    imull $16, %r9d, %r9d
    movl 8(%rsp), %edx
    subl %r9d, %edx

    movl 4(%rsp), %esi 

    imull $384, %edi, %eax
    shll $4, %esi
    addl %esi, %eax
    addl %edx, %eax

    movzwl 8(%r10,%rax,2), %eax
    jmp .Ledn

.Lair:
    movl $10, %eax

.Ledn:
    addq $48, %rsp
    ret

.type set_block,@function
set_block:
    subq $48, %rsp

    movl %edi, 0(%rsp)
    movl %esi, 4(%rsp)
    movl %edx, 8(%rsp)
    movb %r8b, 12(%rsp)
    movb %r9b, 13(%rsp)

    movl 4(%rsp), %esi
    cmpl $0, %esi
    jl .Lreturn
    cmpl $24, %esi
    jge .Lreturn

    cvtsi2ss 0(%rsp), %xmm0
    divss v16f(%rip), %xmm0
    roundss $1, %xmm0, %xmm0
    cvttss2si %xmm0, %r8d

    cvtsi2ss 8(%rsp), %xmm0
    divss v16f(%rip), %xmm0
    roundss $1, %xmm0, %xmm0
    cvttss2si %xmm0, %r9d

    movl %r8d, 16(%rsp)
    movl %r9d, 20(%rsp)

    movl %r8d, %edi
    movl %r9d, %esi
    call chunk

    testq %rax, %rax
    jz .Lreturn

    movq %rax, %r10

    movl 16(%rsp), %r8d
    imull $16, %r8d, %r8d
    movl 0(%rsp), %edi
    subl %r8d, %edi

    movl 20(%rsp), %r9d
    imull $16, %r9d, %r9d
    movl 8(%rsp), %edx
    subl %r9d, %edx

    movl 4(%rsp), %esi

    imull $384, %edi, %eax
    shll $4, %esi
    addl %esi, %eax
    addl %edx, %eax

    leaq 8(%r10,%rax,2), %rax
    movb 12(%rsp), %cl
    movb %cl, 0(%rax)
    movb 13(%rsp), %cl
    movb %cl, 1(%rax)

.Lreturn:
    addq $48, %rsp
    ret

.type break_block,@function
break_block:
    subq $80, %rsp
    
    movl %edi, 0(%rsp)  # x
    movl %esi, 4(%rsp)  # y
    movl %edx, 8(%rsp)  # z
    movl %r8d, 12(%rsp) # yaw
    movl %r9d, 16(%rsp) # pitch

    // Camera
    cvtsi2ss 4(%rsp), %xmm0
    addss  v1_62f(%rip), %xmm0
    movss %xmm0, 20(%rsp)

    movl $0x00000000, 48(%rsp)
    movl $0x00000000, 52(%rsp)
    movl $0x3F800000, 56(%rsp)
    cvtsi2ss 12(%rsp), %xmm0
    mulss PI(%rip), %xmm0
    divss v180f(%rip), %xmm0
    movss %xmm0, 24(%rsp)

    cvtsi2ss 16(%rsp), %xmm0
    mulss PI(%rip), %xmm0
    divss v180f(%rip), %xmm0
    movss %xmm0, 28(%rsp)

    // yaw
    flds 24(%rsp)
    fsin
    fstps 32(%rsp)
    flds 24(%rsp)
    fcos
    fstps 36(%rsp)

    // pitch
    flds 28(%rsp)
    fsin
    fstps 40(%rsp)
    flds 28(%rsp)
    fcos
    fstps 44(%rsp)
    
    movss 32(%rsp), %xmm0
    mulss 44(%rsp), %xmm0
    movss %xmm0, 48(%rsp)   # x

    movss 40(%rsp), %xmm0
    movss %xmm0, 52(%rsp)   # y

    movss 36(%rsp), %xmm0
    mulss 44(%rsp), %xmm0
    movss %xmm0, 56(%rsp)   # z

    movss 48(%rsp), %xmm0
    mulss %xmm0, %xmm0      # x * x
    movss 52(%rsp), %xmm1
    mulss %xmm1, %xmm1      # y * y
    addss %xmm1, %xmm0
    movss 56(%rsp), %xmm1
    mulss %xmm1, %xmm1      # z * z
    addss %xmm1, %xmm0
    sqrtss %xmm0, %xmm0

    movss 48(%rsp), %xmm1
    divss %xmm0, %xmm1      # x /= len
    movss %xmm1, 48(%rsp)
    movss 52(%rsp), %xmm1
    divss %xmm0, %xmm1      # y /= len
    movss %xmm1, 52(%rsp)
    movss 56(%rsp), %xmm1
    divss %xmm0, %xmm1      # z /= len
    movss %xmm1, 56(%rsp)

    cvtsi2ss 0(%rsp), %xmm0 # mapX = x
    movss 20(%rsp), %xmm1   # mapY = camera 
    cvtsi2ss 8(%rsp), %xmm2 # mapZ = z
    pxor %xmm3, %xmm3
    movss v4_5f(%rip), %xmm4
    movss step(%rip), %xmm5

.Lloop:
    comiss %xmm4, %xmm3
    jae .Lend

    movss 48(%rsp), %xmm6
    mulss %xmm5, %xmm6
    addss %xmm6, %xmm0      # mapX

    movss 52(%rsp), %xmm6
    mulss %xmm5, %xmm6
    addss %xmm6, %xmm1      # mapY

    movss 56(%rsp), %xmm6
    mulss %xmm5, %xmm6
    addss %xmm6, %xmm2      # mapZ

    addss %xmm5, %xmm3      # distance

    roundss $1, %xmm0, %xmm6
    cvttss2si %xmm6, %edi
    roundss $1, %xmm1, %xmm6
    cvttss2si %xmm6, %esi
    roundss $1, %xmm2, %xmm6
    cvttss2si %xmm6, %edx

    movl %edi, 60(%rsp)
    movl %esi, 64(%rsp)
    movl %edx, 68(%rsp)
    call get_block

    cmpb $10, %al   # type != air
    je .Lloop        # je .Lend
    cmpb $11, %al   # type != water
    je .Lloop        # je .Lend
    
    // break block
    movl 60(%rsp), %edi # bx
    movl 64(%rsp), %esi # by
    movl 68(%rsp), %edx # bz
    movb $10, %r8b      # air
    movb $0, %r9b       # false
    call set_block
    jmp .Lend

  .Lend:
    addq $80, %rsp
    ret
    
.section .rodata
    .balign 4
v16f: .float 16.0
v1_62f: .float 1.62
v180f: .float 180.0
step: .float 0.08
distance: .float 0.0
v4_5f: .float 4.5
PI: .float 3.14159265
