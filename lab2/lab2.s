%ifdef SORT_ASCENDING
    DIRECTION_VALUE equ 1
%else
    DIRECTION_VALUE equ 0
%endif

section .data

ROWS_COUNT    equ 4
COLUMNS_COUNT equ 5
ROWS_OFFSET   equ 2 * COLUMNS_COUNT

%define offset      r8
%define full_offset r9

rows_count:    db ROWS_COUNT
columns_count: db COLUMNS_COUNT   
direction: db DIRECTION_VALUE    
matrix_data:
    dw  10,  20, -30,  40,    23  
    dw -50,  60, -70, -80, -1324
    dw   5,   0,-100,  15,  1445
    dw 152, -23,-200,  67,  -329

section .bss
    col_maxes:   resw COLUMNS_COUNT             
    col_indices: resb COLUMNS_COUNT
    temp_buf:    resw COLUMNS_COUNT * ROWS_COUNT * 2    

section .text
    global _start

_start: 
mov offset, matrix_data           

mov rcx, COLUMNS_COUNT            ; rcx - счетчик для столбцов (i)
fill_first_max:
    mov ax, [offset + rcx * 2 - 2]
    mov [col_maxes + rcx * 2 - 2], ax
    sub rcx, 1 
    mov [col_indices + rcx], cl
    add rcx, 1 
loop fill_first_max

mov rcx, COLUMNS_COUNT                      
lea offset, [offset + COLUMNS_COUNT * 2]        
    
find_max_j: 
    mov rdx, ROWS_COUNT
    sub offset, 2
            
    mov  rbx, ROWS_OFFSET
    imul rbx, rdx
    lea full_offset, [offset + rbx]
        
    find_max_i:     
        sub full_offset, ROWS_OFFSET    
        mov si, [full_offset]

        cmp si, [col_maxes + rcx * 2 - 2]    
        jle skip_rearrange

        mov [col_maxes + rcx * 2 - 2], si

skip_rearrange: 
        dec rdx
        test rdx, rdx
        jnz find_max_i
    loop find_max_j

    mov r13, COLUMNS_COUNT      ; r13 = длина массива (5)
    mov r14, r13                ; r14 = gap (шаг) (изначально 5)
    mov r15, 0                  ; r15 = флаг swapped (были ли перестановки)


    movzx r8, byte [direction]
comb_sort_loop:
    ;gap = (gap * 10) / 13 

    mov rax, r14
    mov rbx, 10
    mul rbx                 
    mov rbx, 13
    xor rdx, rdx            
    div rbx             
    mov r14, rax

    cmp r14, 1
    jge .check_swapped
    mov r14, 1                  ; gap >= 1

.check_swapped:
    mov r15, 0          ; swapped = 0

    mov r10, r13                ; r10 = длина массива
    sub r10, r14                ; r10 = длина массива - gap

    xor rcx, rcx                ; i = 0

.inner_loop:
    mov r11, rcx
    add r11, r14                ; r11 = i + gap

    mov ax, [col_maxes + rcx * 2]   ; col_maxes[i]
    mov dx, [col_maxes + r11 * 2]   ; col_maxes[i + gap]


    test r8, r8
    jz .descending

.ascending:
    cmp ax, dx
    jle .no_swap    ; if  col_maxes[i] <= col_maxes[i+gap]
    jmp .swap    

.descending:
    cmp ax, dx
    jge .no_swap    ; if >=

.swap:
    mov [col_maxes + rcx * 2], dx
    mov [col_maxes + r11 * 2], ax

    mov al, [col_indices + rcx]
    mov dl, [col_indices + r11]

    mov [col_indices + rcx], dl
    mov [col_indices + r11], al 
 
    mov r15, 1                  ; swapped = 1

.no_swap:
    inc rcx
    cmp rcx, r10
    jl .inner_loop              ; i < длина массива - gap

.check_end:
    cmp r14, 1
    jne comb_sort_loop          ; gap != 1
    cmp r15, 1
    je comb_sort_loop           ; gap ==  1, но были перестановки (аналог пузырька)
    

;КОПИРОВАНИЕ

    xor r8, r8                  ; r8 = смещение строк ( 0, 10, 20, 30)
    mov r12, ROWS_COUNT
    imul r12, ROWS_OFFSET       ; r12 размер матрицы (40)

.row_loop:  
    cmp r8, r12                 
    jge .done_reorder          ; if r8 >= r12

    xor r9, r9                  ; r9 (i) = индекс нового столбца (от 0 до 4)

.col_loop:
    cmp r9, COLUMNS_COUNT       
    jge .next_row               ; if r9 >= COLUNBS_COUNT

    movzx rax, byte [col_indices + r9]  ; rax = старый индекс (0..4)

    ; 2. Читаем элемент из оригинальной матрицы (matrix_data + смещение_строки + старый_индекс * 2)
    mov cx, [matrix_data + r8 + rax * 2]  

    ; 3. Записываем элемент в новый буфер (temp_buf + смещение_строки + новый_индекс * 2)
    mov [temp_buf + r8 + r9 * 2], cx

    inc r9                      ; Переходим к следующему новому столбцу
    jmp .col_loop

.next_row:
    add r8, ROWS_OFFSET         ; Увеличиваем смещение на размер одной строки (10 байт)
    jmp .row_loop

.done_reorder:
    
    mov rax, 60              
    xor rdi, rdi             
    syscall


error:
    mov rax, 60
    mov rdi, 1
    syscall


















