.globl _start

.extern biome_type
.section .text

.type _start,@function
_start:
    movl $42, %edi
    movl $64,  %esi
    movl $12, %edx
    movl $99,  %r8d
    call biome_type

.exit_program:
    movl %eax, %edi
    movq $60, %rax
    syscall

