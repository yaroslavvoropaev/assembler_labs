extern printf
extern scanf
extern fopen
extern fprintf
extern fclose
extern logf
extern exit

section .data
    usage_msg    db "Ошибка: неверное количество аргументов.", 10, "Использование: %s <имя_выходного_файла>", 10, 0
    err_open     db "Ошибка: не удалось открть файл для записи.", 10, 0
    info_msg   db "Введите значение x (-1 < x <= 1) и точность: ", 0
    format_in       db "%f %f", 0
    format_out_term db "Член ряда %d: %f", 10, 0
    format_result   db "Сумма ряда: %f", 10, "Значение log(1+x) (libm): %f", 10, 0
    mode_w       db "w", 0         ; реижим открытия файла на запись

    float_1       dd 1.0
    float_minus_1 dd -1.0

    align 16     ; следующую метку в памяти расположи так, чтобы адрес был кратен 16
    abs_mask     dd 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF

section .bss
    x        resd 1      ;float
    eps      resd 1      ; float
    file_ptr resq 1     ; 8 байт под FILE *

section .text
    global main

main:
    ; пролог для создания стекового кадра
    push rbp                    ; кладем в стек старый указатель базы кадрка
    mov rbp, rsp                
    sub rsp, 16                 
    
    cmp rdi, 2                 ; rdi содержит args - количество аргументов
    jl .err_args

    mov r12, qword [rsi + 8]          ; в r12 - argv[1] (второй аргумент)

    ; открытия файла на запись 
    mov rdi, r12                    ; имя файла
    mov rsi, mode_w                 ; режим  "w"
    call fopen                          

    test rax, rax                  ; проверяем что указатель FILE * не 0
    jz .err_open
    mov [file_ptr], rax             ; сохраняем FILE * 

    ; ввод данных 
    mov rdi, info_msg
    mov al, 0              ; количество аргументов с плавающей точкой
    call printf

    mov rdi, format_in
    mov rsi, x                      
    mov rdx, eps
    mov al, 0                   
    call scanf

    movss xmm0, dword [x]           ; старшие биты зануляются
    movss xmm1, dword [eps]         
                                
    xorps xmm2, xmm2                ; xmm2 = 0  (накапливаемая сумма)
    movss xmm3, dword [float_1]     ; n
    movaps xmm4, xmm0               ; для x^n
    movss xmm5, dword [float_1]     ; для знака
    mov r13d, 1                      ; счетчик для вывода
.loop:
    movaps xmm6, xmm4           ; xmm6 = x^n
    mulss xmm6, xmm5            ; умножем на  (-1)^(n-1)
    divss xmm6, xmm3            ; делим на n

    movaps xmm7, xmm6            ; копируем член ряда в xmm7
    pand xmm7, [abs_mask]        ; побитовое and c маской (cбрасываем старший знаковой бит)
    ucomiss xmm7, xmm1           ; 
    jb .done

    addss xmm2, xmm6

    ; все нужные регистры в стек
    sub rsp, 32
    movss [rsp+0],  xmm0
    movss [rsp+4],  xmm1
    movss [rsp+8],  xmm2
    movss [rsp+12], xmm3
    movss [rsp+16], xmm4
    movss [rsp+20], xmm5

    ; вызываем fprintf(file, "Член ряда %d: %f\n", n, term)
    mov rdi, [file_ptr]
    mov rsi, format_out_term
    mov edx, r13d               ; номер члена
    cvtss2sd xmm0, xmm6         ; конвертируем float в double для printf
    mov al, 1                   ; 1 аргумент с плавающей точкой
    call fprintf

    movss xmm0, [rsp+0]
    movss xmm1, [rsp+4]
    movss xmm2, [rsp+8]
    movss xmm3, [rsp+12]
    movss xmm4, [rsp+16]
    movss xmm5, [rsp+20]
    add rsp, 32

    mulss xmm4, xmm0                     ; x^n = x^(n-1) * x
    mulss xmm5, dword [float_minus_1]    ; меняем знак: (-1)^(n-1) * (-1)
    addss xmm3, dword [float_1]         ; n = n + 1
    inc r13d                            ; r13d++ (для вывода номер)

    jmp .loop

.done:
    ; вычисляем log(1+x) через библиотеку
    addss xmm0, dword [float_1] ; xmm0 = 1 + x
    sub rsp, 16                 ; выравнивание стека
    movss [rsp], xmm2           ; сохраняем нашу сумму
    call logf
    movss xmm1, [rsp]           ; xmm1 = наша сумма, xmm0 = logf(1+x)
    add rsp, 16

    ; double -> float 
    cvtss2sd xmm0, xmm0             
    cvtss2sd xmm1, xmm1             
    
    ; меняем местами для printf
    movaps xmm2, xmm0               
    movaps xmm0, xmm1               
    movaps xmm1, xmm2               

    mov rdi, format_result
    mov al, 2                       
    call printf

    mov rdi, [file_ptr]
    call fclose

    mov eax, 0                  ; return 0
    add rsp, 16
    pop rbp
    ret
.err_args:
    mov rdi, usage_msg
    mov rsi, [rsi]              ; argv[0] — имя программы
    mov al, 0
    call printf
    mov edi, 1                  ; код возврата 1
    call exit                   ; завершение программы

.err_open:
    mov rdi, err_open
    mov al, 0
    call printf
    mov edi, 1
    call exit

