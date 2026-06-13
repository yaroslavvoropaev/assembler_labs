section .text
global sobel_asm


; const uint8_t *in - rdi
; uint8_t *out - rsi
; int width - rdx
; int height - rcx

sobel_asm:
    push rbp        ; сохраняем указатель базы кадра стека
    mov rbp, rsp 
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r8, 1            ; r8 = 1 - счетчик строк
.loop_y:
    mov rax, rcx
    dec rax              ; rax = height - 1 
    cmp r8, rax
    jge .done            ; if (r8 >= rax)

    mov r9, 1            ; r9 = 1 - счетчик стобцов
.loop_x:
    mov rax, rdx
    dec rax              ; rax = weight - 1
    cmp r9, rax
    jge .next_y          ; if (r9 >= rax) 

    mov rax, r8
    imul rax, rdx
    add rax, r9
    mov r10, rax  ; r10 - текущий пиксель

    xor r11, r11   ; Gx
    xor r12, r12   ; Gy

    mov rax, r10
    sub rax, rdx   ; rax = над текущем пикселем        
    
    movzx r13, byte [rdi + rax - 1]      ; верхней левый
    sub r11, r13                         ; Gx -= p
    add r12, r13                         ; Gy += p

    movzx r13, byte [rdi + rax]          ; средней левый
    shl r13, 1           
    add r12, r13                         ; Gy += 2*p


    movzx r13, byte [rdi + rax + 1]     ; верхней правый
    add r11, r13                        ; Gx += p  
    add r12, r13                        ; Gy += p

    movzx r13, byte [rdi + r10 - 1]     ; средний левый
    shl r13, 1                          
    sub r11, r13                        ; Gx -= 2*p

    movzx r13, byte [rdi + r10 + 1]     ; средний правый
    shl r13, 1
    add r11, r13                        ; Gx += 2*p


    mov rax, r10
    add rax, rdx    ; rax = под текущем пикселем         

    movzx r13, byte [rdi + rax - 1]     ; левый нижний
    sub r11, r13                        ; Gx -= p
    sub r12, r13                        ; Gy -= p

    movzx r13, byte [rdi + rax]         ; нижний средний
    shl r13, 1
    sub r12, r13                        ; Gy -= 2*p

    movzx r13, byte [rdi + rax + 1]     ; нижний прапрвый
    add r11, r13                        ; Gx += p
    sub r12, r13                        ; Gy -= p

    mov rax, r11
    cmp rax, 0
    jge .positive_skip_x
    neg rax

.positive_skip_x:
    mov r11, rax

    mov rax, r12
    cmp rax, 0
    jge .positive_skip_y
    neg rax
    
.positive_skip_y:
    mov r12, rax

    add r11, r12     ; сумма

    cmp r11, 255
    jle .store
    mov r11, 255
.store:
    mov byte [rsi + r10], r11b

    inc r9
    jmp .loop_x

.next_y:
    inc r8
    jmp .loop_y

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
