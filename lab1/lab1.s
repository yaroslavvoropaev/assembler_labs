section .rodata
    a dw 10
    b dw 3
    c dd 2
    d dd 150
    e dd 8
    
section .data
    result dq 0

section .text
    global _start

_start:
    mov r8w,  [a]
    mov r9w,  [b]
    mov r10d, [c]
    mov r11d, [d]
    mov r12d, [e]

    ; проверка нуля в знаминателе 

    test r9w, r9w
    jz _error

    test r11d, r11d
    jz _error

    ; расчеты числителя

    movzx eax, word r8w ; записали a в eax c расширением нулями   
    movzx r13d, word r9w
    mul r13d
    
    mul r10

    jc _error

    mov rbx, rax ; результат a * b * c лежит в rbx
    
    mov eax, r10d
    
    mul r11 ; в rax лежит результат c * d
    jc _error
    mul r12 ; в rax лежит результат c * d * e
    jc _error
    
    sub rbx, rax ; числитель лежит в rbx

    ; расчеты знаменателя

    mov ax, r8w
        
    xor dx, dx
    div r9w

    movzx r13, word ax ; результат a/b в  r13
    
    xor edx, edx
    mov eax, r10d 
    div r11d ; результат c/d в rax
    add rax, r13 ; знаминатель в rax
    jc _error    

    test rax, rax
    jz _error

    mov r13, rax
    mov rax, rbx
    cqo
    idiv r13

    mov [result], rax
    
	mov rax, 60 
	xor rdi, rdi
	syscall
                 
_error:
    mov rax, 60
	mov rdi, 1 
	syscall
    
