.model small

.stack 100h

.data 

    BUF_LEN equ (6+1)

    buf_x_suff db BUF_LEN, ?
    buf_x db BUF_LEN dup("_"), "$"

    buf_y_suff db BUF_LEN, ?
    buf_y db BUF_LEN dup("_"), "$"

    buf_res db BUF_LEN dup("_"), "$"

    x dw ?
    y dw ?

    msg_greet db "=== the simplest calculator ===", 0Ah, 0Dh, "$"
    msg_input_x db "input x: ", "$"
    msg_input_y db "input y: ", "$"
    msg_res_add db "x + y = ", "$"
    msg_res_sub db "x - y = ", "$"
    msg_res_mul db "x * y = ", "$"
    msg_res_div db "x / y = ", "$"


.code

newline MACRO
    mov AH, 02h
    mov DL, 0Ah
    int 21h
    mov AH, 02h
    mov DL, 0Dh
    int 21h
ENDM

readln MACRO buf_suff
    push AX
    push BX
    push DX

    mov DX, offset buf_suff
    mov AH, 0Ah
    int 21h

    xor AX, AX
    mov AL, buf_suff[1]
    mov BX, offset buf_suff + 2
    add BX, AX
    mov byte ptr [BX], "$"

    pop DX
    pop BX
    pop AX
ENDM

writeln MACRO msg
    mov AH, 09h
    mov DX, offset msg
    int 21h
ENDM


START:
    mov AX, @data
    mov DS, AX


    writeln msg_greet

    writeln msg_input_x
    readln buf_x_suff
    newline 

    writeln msg_input_y
    readln buf_y_suff
    newline

    mov BX, offset buf_x
    mov CX, 10
    call str2num
    mov SI, AX

    mov BX, offset buf_y
    mov CX, 10
    call str2num
    mov DI, AX


    mov BX, offset buf_res
    mov CX, 10

    ; add

    mov AX, SI
    add AX, DI

    call num2str
    writeln msg_res_add
    writeln buf_res
    newline

    ; sub

    mov AX, SI
    sub AX, DI

    call num2str
    writeln msg_res_sub
    writeln buf_res
    newline

    ; mul

    mov AX, SI
    add AX, DI

    call num2str
    writeln msg_res_mul
    ; writeln buf_res
    newline

    ; div

    mov AX, SI
    add AX, DI

    call num2str
    writeln msg_res_div
    ; writeln buf_res
    newline


    ; exit
    mov AL, 00h
    exit:
        mov AH, 4Ch
        int 21h


    str2num PROC ; BX - str ptr, CX - base  ->  AX - result
        push BX
        push CX
        push DX

        ; move if the first char is a sign
        cmp byte ptr [BX], "-"
        je str2num_move_sign
        cmp byte ptr [BX], "+"
        jne str2num_skip_move_sign
        str2num_move_sign:
        inc BX
        str2num_skip_move_sign:

        xor AX, AX
        str2num_loop_next_char:
            imul CX
            ; TODO check overflow (DX != 0)

            push CX
            xor CX, CX
            mov CL, byte ptr [BX]
            sub CL, "0"
            ; TODO check for base overflow !('0' <= CX <= '9')
            add AX, CX
            pop CX
        
            inc BX
            cmp byte ptr [BX], "$"
            jne str2num_loop_next_char
            
        pop DX
        pop CX
        pop BX

        ; if there was a minus
        cmp byte ptr [BX], "-"
        jne str2num_skip_neg
        neg AX
        str2num_skip_neg:

        ret
    str2num ENDP

    num2str PROC ; AX - num, BX - str ptr, CX - base  ->  [BX] - result
        push AX
        push BX
        push CX
        push DX

        ; check if the msb is set = num is negative
        test AX, 8000h
        jz num2str_skip_minus
        mov byte ptr [BX], "-"
        neg AX ; make num positive for convinient conversion
        inc BX
        num2str_skip_minus:

        push -1
        num2str_loop_next_char:
            xor DX, DX
            idiv CX

            ; TODO check for base overflow (DH != 0 || DL >= CX)
            push DX
        
            test AX, AX
            jnz num2str_loop_next_char

        num2str_loop_pop_digits:
            pop DX

            cmp DX, 0
            jl num2str_end_loop_pop_digits

            add DL, "0"
            mov byte ptr [BX], DL

            inc BX
            jmp num2str_loop_pop_digits
        num2str_end_loop_pop_digits:

        mov byte ptr [BX], "$"
            
        pop DX
        pop CX
        pop BX
        pop AX
        ret
    num2str ENDP


END
