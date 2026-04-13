%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN    2
%define SYS_CLOSE   3
%define SYS_EXIT    60

section .data
    msg_f       db "Имя файла: "
    len_f       equ $ - msg_f
    msg_n       db "Сдвиг N: "
    len_n       equ $ - msg_n
    msg_t       db "Текст (Ctrl+D для завершения):", 10
    len_t       equ $ - msg_t
    
    space       db ' '
    newline     db 10

section .bss
    filename    resb 256      
    n_str       resb 32       ; сдвиг как строка
    shift_n     resq 1        ; сдвиг как число 
    fd_out      resq 1        ; файловый дескриптор
    
    char_buf    resb 1        
    word_buf    resb 1048576  ; длина одного слова как строка
    word_len    resq 1        ; длина одного слова как число
    is_first    resb 1

section .text
    global _start

_start :


    ; ввод имени файла
    mov rax, SYS_WRITE         ; номер системеного вызова в rax
    mov rdi, 1                 ; 1, так как stdout
    mov rsi, msg_f             ; куда смотреть (адрес)
    mov rdx, len_f             ; сколько взять байт 
    syscall

    mov rdi, filename
    call read_line  

    ; Ввод числа сдвига
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, msg_n
    mov rdx, len_n
    syscall

    mov rdi, n_str
    call read_line
    call parse_str_to_num

    ; открытие файла
    mov rax, SYS_OPEN
    mov rdi, filename
    mov rsi, 577            ; флгаи O_WRONLY | O_CREAT | O_TRUNC =  1 + 64 + 512 = 577
    mov rdx, 420            ; прав 0644 (rw-r--r--) в восьм = 420 в дес
    syscall
    mov [fd_out], rax       ; дескиптор - индекс в таблице ядра

    ; ввода текста               
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, msg_t
    mov rdx, len_t
    syscall

    mov byte [is_first], 1        ; первое слово в строке
    mov qword [word_len], 0       ; длина текущего слова

    ; читаем по одному слову
read_loop:
    mov rax, SYS_READ
    mov rdi, 0                     ; 0, так как stdin
    mov rsi, char_buf
    mov rdx, 1
    syscall
    
    cmp rax, 0          
    jle eof                  ;if (eof) 

    mov al, [char_buf]
    cmp al, ' '         ; пробел
    je handle_space
    cmp al, 9           ; \t
    je handle_space
    cmp al, 10          ; \n
    je handle_nl

    ; иначе обычный символ
    mov rcx, [word_len]
    mov [word_buf + rcx], al
    inc qword [word_len]
    jmp read_loop

handle_space:
    call flush_word     ; записываем накопленное слово
    jmp read_loop

handle_nl:
    call flush_word     ; записываем слово

    mov rax, SYS_WRITE
    mov rdi, [fd_out]
    mov rsi, newline
    mov rdx, 1
    syscall
    mov byte [is_first], 1
    jmp read_loop

eof:
    call flush_word     ; записываем наколпенное слово перед выходом
    
    ; закрываем файл
    mov rax, SYS_CLOSE
    mov rdi, [fd_out]
    syscall
    
    ; завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall


; вход: rdi - адреc буфера
read_line:
    push r12                ; r12-r15 non-volatile
    mov r12, rdi            ; записали в r12 адрес буфера
.read_line_loop:
    mov rax, SYS_READ       
    mov rdi, 0              ; 0, так как stdin
    mov rsi, char_buf       ; адрес буфера 
    mov rdx, 1              ; количество считываемых байт 
    syscall
    
    cmp rax, 0
    jle .read_line_done
    mov al, [char_buf]
    cmp al, 10
    je .read_line_done
    
    mov [r12], al
    inc r12
    jmp .read_line_loop
.read_line_done:
    mov byte [r12], 0
    pop r12
    ret

; Перевод строки в число N
parse_str_to_num:
    mov rsi, n_str              
    xor rax, rax
    xor rcx, rcx
.parse_loop:
    movzx rcx, byte [rsi]     ; читаем байт
    test rcx, rcx             
    jz .parse_done            ; if (rcx == 0) (то есть \0)
    sub rcx, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .parse_loop
.parse_done:
    mov [shift_n], rax
    ret

; сдвиг накопленного слова и запись его в файл
flush_word:
    mov rcx, [word_len]
    test rcx, rcx       
    jz .fw_ret                  ; если длина слова 0

    cmp byte [is_first], 0
    jne .calc_shift            ; если слово первое
    
    ; вывод пробела
    mov rax, SYS_WRITE
    mov rdi, [fd_out]
    mov rsi, space
    mov rdx, 1
    push rcx            ; сохранить rcx (sys_write его затирает)
    syscall
    pop rcx

.calc_shift:
    ; расчет сдвига: n % длина
    mov rax, [shift_n]
    xor rdx, rdx
    div rcx
    
    ; rdx - сколько символов нужно отрубить с конца (хвост)
    ; rcx - полная длина слова
    mov r8, rdx
    mov r9, rcx
    sub r9, r8          ; r9 = длина левой части, которая останется на месте

    ; выводим хвост (правую часть)
    test r8, r8
    jz .fw_left       ; если хвоста нет
    
    mov rax, SYS_WRITE
    mov rdi, [fd_out]
    mov rsi, word_buf
    add rsi, r9         ; Смещаемся к хвосту
    mov rdx, r8
    push r8
    push r9
    syscall
    pop r9
    pop r8

.fw_left:
    ; выводим левую часть
    test r9, r9
    jz .fw_end

    mov rax, SYS_WRITE
    mov rdi, [fd_out]
    mov rsi, word_buf
    mov rdx, r9
    syscall

.fw_end:
    mov byte [is_first], 0   ; следующее слово уже не первое
    mov qword [word_len], 0  ; очищаем буфер слова для следующего
.fw_ret:
    ret
