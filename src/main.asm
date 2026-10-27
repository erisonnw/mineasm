.globl _start

.extern biome_type
.extern loaded
.extern get_chunk

.section .text

.type _start,@function
_start:
    movl $42, %edi
    movl $64,  %esi
    movl $12, %edx
    movl $99,  %r8d
    call biome_type
    
    leaq loaded(%rip), %rdx
    movl $42, 0(%rdx)
    movl $64, 4(%rdx)
    movb $1, 4104(%rdx)

    movl $42, %edi
    movl $64, %esi
    call get_chunk

.exit_program:
    movq %rax, %rdi
    movq $60, %rax
    syscall

