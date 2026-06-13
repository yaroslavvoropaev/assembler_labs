section .text
global sobel_simd


; const uint8_t *in - rdi
; uint8_t *out - rsi
; int width - rdx
; int height - rcx


sobel_simd:
    push rbp
    mov rbp, rsp
    push rbx

    pxor xmm7, xmm7      ; для распаковки 8-битных пикселей в 16-битные

    mov r8, 1            ; y = 1
.loop_y:
    mov rax, rcx         
    dec rax         
    cmp r8, rax
    jge .done            ; if (y >= height - 1) 

    mov r9, 1            ; x = 1
.loop_x:
    mov rax, rdx
    dec rax              
    cmp r9, rax          ; if (x >= width - 1)
    jge .next_y

    mov rbx, rax
    sub rbx, 8           ; rbx - максимально возможный x при котором влезет 8 пикселей
    
    cmp r9, rbx
    jle .calculation            ; if (x <= rbx)

    mov r9, rbx        ; сдвигаем x назад   

.calculation:
    ; r10 = y * width + x
    mov rax, r8
    imul rax, rdx
    add rax, r9
    mov r10, rax   

    mov rax, r10
    sub rax, rdx ; индекс пикселя над текщим
    
    movq xmm0, [rdi + rax - 1]   ; левый верхний 
    punpcklbw xmm0, xmm7
    movq xmm1, [rdi + rax]       ; средний верхний
    punpcklbw xmm1, xmm7
    movq xmm2, [rdi + rax + 1]   ; правый верхний
    punpcklbw xmm2, xmm7

    movq xmm3, [rdi + r10 - 1]   ; левый средний
    punpcklbw xmm3, xmm7
    movq xmm4, [rdi + r10 + 1]   ; правый средний
    punpcklbw xmm4, xmm7

    mov rbx, r10                 
    add rbx, rdx
    movq xmm5, [rdi + rbx - 1]   ; левый нижний
    punpcklbw xmm5, xmm7
    movq xmm6, [rdi + rbx]       ; средний нижний
    punpcklbw xmm6, xmm7
    movq xmm8, [rdi + rbx + 1]   ; правый нижний 
    punpcklbw xmm8, xmm7

    ; Gx (xmm9) ---
    movdqa xmm9, xmm2
    psubw xmm9, xmm0

    movdqa xmm10, xmm4
    psubw xmm10, xmm3
    psllw xmm10, 1
    paddw xmm9, xmm10

    movdqa xmm10, xmm8
    psubw xmm10, xmm5
    paddw xmm9, xmm10

    ; |Gx|
    movdqa xmm10, xmm9
    psraw xmm10, 15
    pxor xmm9, xmm10
    psubw xmm9, xmm10

    ;Gy (xmm11) 
    movdqa xmm11, xmm0
    movdqa xmm10, xmm1
    psllw xmm10, 1
    paddw xmm11, xmm10
    paddw xmm11, xmm2

    movdqa xmm12, xmm5
    movdqa xmm10, xmm6
    psllw xmm10, 1
    paddw xmm12, xmm10
    paddw xmm12, xmm8

    psubw xmm11, xmm12

    ; |Gy|
    movdqa xmm10, xmm11
    psraw xmm10, 15
    pxor xmm11, xmm10
    psubw xmm11, xmm10

    ; cумма и сатурация
    paddw xmm9, xmm11
    packuswb xmm9, xmm9
    
    ; запись 8 пикселей
    movq [rsi + r10], xmm9

    add r9, 8
    jmp .loop_x

.next_y:
    inc r8
    jmp .loop_y

.done:
    pop rbx
    pop rbp
    ret
