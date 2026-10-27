.globl coord_tohash

.equiv POSX, 0xcc9e2d51
.equiv POSY, 0x1b873593
.equiv POSZ, 0xe6546b64
.equiv SEED, 0x85ebca6b
.equiv AVAL, 0xc2b2ae35

.section .text

.type coord_tohash,@function
coord_tohash:
    imull $POSX, %edi
    imull $POSY, %esi
    imull $POSZ, %edx
    imull $SEED, %r8d

    leal (%edi, %esi), %eax
    leal (%edx, %r8d, 1), %ecx
    addl %ecx, %eax

    /**
     * h = h ^ (h >> 13) * Avalanche
     * h = h ^ (h >> 16)
    */
    movl %eax, %ecx
    shrl $13, %ecx
    xorl %ecx, %eax
    imull $AVAL, %eax

    movl %eax, %ecx
    shrl $16, %ecx
    xorl %ecx, %eax
    ret
