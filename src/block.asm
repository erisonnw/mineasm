.globl set_block
.globl get_block

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
    subq $48, %rsp
    


.section .rodata
    .balign 4
v16f: .float 16.0

