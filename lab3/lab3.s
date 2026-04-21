%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN    2
%define SYS_CLOSE   3
%define SYS_EXIT    60
%define BUF_SIZE    4096    

section .data
    msg_f       db "Имя файла: "
    len_f       equ $ - msg_f
    msg_n       db "Сдвиг N: "
    len_n       equ $ - msg_n
    msg_t       db "Текст:", 10
    len_t       equ $ - msg_t
 
    err_open    db 10, "Ошибка: Не удалось открыть/создть файл", 10
    len_err_o   equ $ - err_open
    err_n       db 10, "Ошибка: Некорректное значение N (введите число)", 10
    len_err_n   equ $ - err_n
    err_write   db 10, "Ошибка: Сбой при записи в файл", 10
    len_err_w   equ $ - err_write
    err_ovf     db 10, "Ошибка: Слово слишком длинное для буфера", 10
    len_err_ovf equ $ - err_ovf

    space       db ' '
    newline     db 10

section .bss
    filename    resb 256      ; под имя файла
    n_str       resb 32       ; строка для ввода сдвига
    shift_n     resq 1        ; число сдвига
    fd_out      resq 1    ; rax < 0    ; файловый дескриптор 
    
    in_buf      resb BUF_SIZE ; буфер для ввода
    in_pos      resq 1        ; текущая позиция чтения в буфере
    in_bytes    resq 1        ; количество прочитанных байт в буфере

    word_buf    resb 1048576  ; буфер для одного слова 1 мб
    word_len    resq 1        ; длина одного слова
    is_first    resb 1

section .text
    global _start

_start:
    ; ввод имени файла
    mov rdi, 1                  ; 1, так как stdout
    mov rsi, msg_f              ; адрес строки
    mov rdx, len_f              ; длина строки
    call safe_write

    mov rdi, filename
    call read_line  

    ; ввод числа сдвига
    mov rdi, 1             
    mov rsi, msg_n       
    mov rdx, len_n
    call safe_write

    mov rdi, n_str         
    call read_line 
    call parse_str_to_num

    ; открытие файла
    mov rax, SYS_OPEN
    mov rdi, filename
    mov rsi, 577            ; флаги O_WRONLY | O_CREAT | O_TRUNC = 577
    mov rdx, 420            ; права 0644 (rw-r--r--) в восьм = 420 в дес
    syscall
    test rax, rax 
    js exit_err_open      ; еcли rax отрицательный, ошибка открытия фалйа

    mov [fd_out], rax           ; сохраняем файловый дескриптор

    ; ввод текста для сдвига        
    mov rdi, 1
    mov rsi, msg_t
    mov rdx, len_t
    call safe_write

    mov byte [is_first], 1        ; первое слово в строке
    mov qword [word_len], 0       ; длина текущего слова

    ; читаем по одному слову через буфер
read_loop:
    call get_char
    jc eof              ; if  (carry == 1)  флаг (CF), значит eof

    cmp al, ' '         ; пробел
    je handle_space
    cmp al, 9           ; \t
    je handle_space
    cmp al, 10          ; \n
    je handle_new_line

    ; иначе обычный символ
    mov rcx, [word_len]
    cmp rcx, 1048575
    jae exit_err_ovf        ; ошибка переполнение 

    mov [word_buf + rcx], al
    inc qword [word_len]
    jmp read_loop

handle_space:
    call flush_word     ; записываем накопленное слово
    jmp read_loop

handle_new_line:
    call flush_word     ; записываем слово

    mov rdi, [fd_out]
    mov rsi, newline
    mov rdx, 1
    call safe_write    ; проверяем щапись    

    mov byte [is_first], 1
    jmp read_loop

eof:
    call flush_word     ; записываем накопленное слово перед выходом

    ; закрываем файл
    mov rax, SYS_CLOSE
    mov rdi, [fd_out]
    syscall
    
    ; завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall


exit_err_open:
    mov rdi, 2
    mov rsi, err_open
    mov rdx, len_err_o
    jmp exit_with_msg

exit_err_n:
    mov rdi, 2
    mov rsi, err_n
    mov rdx, len_err_n
    jmp exit_with_msg

exit_err_write:
    mov rdi, 2
    mov rsi, err_write
    mov rdx, len_err_w
    jmp exit_with_msg

exit_err_ovf:
    mov rdi, 2
    mov rsi, err_ovf
    mov rdx, len_err_ovf

exit_with_msg:
    mov rax, SYS_WRITE
    syscall
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

; обертка над SYS_WRITE для проверки ошибок
safe_write:
    mov rax, SYS_WRITE  
    syscall
    test rax, rax  
    js exit_err_write ; rax < 0
    ret

; функция получения 1 символа из буфера
get_char:
    mov rax, [in_pos]       ; в rax позиция в буфере
    cmp rax, [in_bytes]     
    jl .fetch_from_buf      ; если в буфере еще есть данные, берем оттуда

    ; читаем новую порцию
    mov rax, SYS_READ
    mov rdi, 0              ; 0, так как stdin
    mov rsi, in_buf         ; адрес буфера
    mov rdx, BUF_SIZE       ; размер
    syscall

    cmp rax, 0
    jle .eof                ; if (rax == 0) => eof 

    mov [in_bytes], rax     ; cохраняем количество прочитанных байт
    mov qword [in_pos], 0   ; cбрасываем позицию на 0

.fetch_from_buf:
    mov rcx, [in_pos]
    mov al, [in_buf + rcx]  ; достаем символ
    inc rcx
    mov [in_pos], rcx
    clc                        ; oчищаем carray флаг (CF=0)  (успех)
    ret 
.eof:
    stc                     ; устанавливаем carry флаг (CF=1) (не успех)
    ret

; вход: rdi - адрес буфер
read_line:
    push r12                ; сохраняем регист
    mov r12, rdi            ; записали в r12 адрес буфера
.read_line_loop:
    call get_char           ; символ из буфера
    jc .read_line_done      ; if (eof) 
    
    cmp al, 10              ; if (\n)
    je .read_line_done
    
    mov [r12], al
    inc r12
    jmp .read_line_loop
.read_line_done:
    mov byte [r12], 0       ; нуль-терминатор
    pop r12
    ret

; перевод строки в число N
parse_str_to_num:
    mov rsi, n_str        
    xor rax, rax         
    xor rcx, rcx

    cmp byte [rsi], 0
    je exit_err_n
.parse_loop:
    movzx rcx, byte [rsi]     

    test rcx, rcx             
    jz .parse_done
    ;символ должен быть цифрой 
    cmp rcx, '0'
    jl exit_err_n
    cmp rcx, '9'
    jg exit_err_n

    sub rcx, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .parse_loop
.parse_done:
    mov [shift_n], rax
    ret

; сдвиг и запись накоплненного слова
flush_word:
    mov rcx, [word_len]
    test rcx, rcx       
    jz .fw_ret                  ; если длина слова 0

    cmp byte [is_first], 0
    jne .calc_shift            ; если слово первое
    
    ; вывод пробела
    mov rdi, [fd_out]
    mov rsi, space
    mov rdx, 1
    push rcx
    call safe_write
    pop rcx

.calc_shift:
    mov rax, [shift_n]
    xor rdx, rdx
    div rcx
    
    mov r8, rdx
    mov r9, rcx
    sub r9, r8          ; r9 = длина левой части

    test r8, r8
    jz .fw_left         ; если хвоста нет
    
    mov rdi, [fd_out]
    mov rsi, word_buf
    add rsi, r9         ; смещаемся к хвосту
    mov rdx, r8
    push r8
    push r9
    call safe_write
    pop r9
    pop r8

.fw_left:
    test r9, r9
    jz .fw_end

    mov rdi, [fd_out]
    mov rsi, word_buf
    mov rdx, r9
    call safe_write

.fw_end:
    mov byte [is_first], 0
    mov qword [word_len], 0
.fw_ret:
    ret
