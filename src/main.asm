.globl _start

.extern biome_type
.extern loaded
.extern chunk
.extern get_block
.extern set_block

.section .text

.type _start,@function
_start:
    movl $42, %edi
    movl $64, %esi
    movl $12, %edx
    movl $99, %r8d
    call biome_type

    leaq loaded(%rip), %rdx
    movl $42, 0(%rdx)
    movl $64, 4(%rdx)
    movb $1, 4104(%rdx)

    movl $42, %edi
    movl $64, %esi
    call chunk

    movl $672, %edi
    movl $10, %esi
    movl $1024, %edx
    movb $3, %r8b
    movb $1, %r9b
    call set_block

    movl $672, %edi
    movl $10, %esi
    movl $1024, %edx
    call get_block

.exit_program:
    movq %rax, %rdi
    movq $60, %rax
    syscall