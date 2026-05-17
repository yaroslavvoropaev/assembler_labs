global crop_asm
section .text

; rdi =  uint8_t *in_ptr 
; rsi =  uint8_t *out_ptr 
; edx = int in_stride 
; ecx = int row_bytes
; r8d = int out_h
crop_asm:
    movsxd r8, r8d       ; r8 = out_h (высота)
    test r8, r8
    jle .end             ; если высота <= 0, выходим

    movsxd rdx, edx      ; rdx = in_stride (шаг исходной матрицы)
    movsxd r9, ecx       ; r9 = row_bytes (байт в строке для копирования)
 
    ; меяем местами
    mov r10, rdi
    mov rdi, rsi
    mov rsi, r10

.row_loop:
    push rsi             ; cохраняем текущий указатель на источник
    push rdi             ; cохраняем текущий указатель на назначение

    mov rcx, r9          ; rcx = количество байт для копирования в одной строке
    rep movsb            ; копируем строку

    pop rdi              ; cосстанавливаем указатели начала строки
    pop rsi              

    add rsi, rdx         ; cдвигаем источник на следующую строку (на in_stride байт)
    add rdi, r9          ; cдвигаем назначение на следующую строку (на row_bytes байт)

    dec r8              
    jnz .row_loop        ; если остались строки, повторяем цикл

.end:
    ret

section .note.GNU-stack noalloc noexec alloc progbits
