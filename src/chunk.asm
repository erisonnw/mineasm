.globl chunk
.globl loaded
.section .text

.type chunk,@function
chunk:
    movl %edi, %r8d
    movl %esi, %r9d

    leaq loaded(%rip), %rdx
    xorl %ecx, %ecx

1:
    cmpl $9, %ecx
    jge .Lnop

    movzx 4104(%rdx), %eax
    testb %al, %al
    jz 2f

    movl 0(%rdx), %eax
    cmpl %r8d, %eax
    jne 2f

    movl 4(%rdx), %eax
    cmpl %r9d, %eax
    jne 2f

    movq %rdx, %rax
    ret

2:
    addq $4112, %rdx
    incl %ecx
    jmp 1b

.Lnop:
    xorl %eax, %eax
    ret

.section .bss
    .balign 16
loaded: .zero 40000
