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

    err_input_overflow db "(input overflowed, truncated to signed 16 bits)", 0Ah, 0Dh, "$"
    err_result_overflow db "(result overflowed, truncated to signed 16 bits)", 0Ah, 0Dh, "$"
    err_division_by_zero db "it is infinity. probably", 0Ah, 0Dh, "$"

.code

newline MACRO
    push AX
    push DX

    mov AH, 02h
    mov DL, 0Ah
    int 21h
    mov AH, 02h
    mov DL, 0Dh
    int 21h

    pop DX
    pop AX
ENDM

readln MACRO buf_suff
    push AX
    push BX
    push DX

    mov DX, offset buf_suff
    mov AH, 0Ah
    int 21h

    xor AH, AH
    mov AL, buf_suff[1]
    mov BX, offset buf_suff + 2
    add BX, AX
    mov byte ptr [BX], "$"

    pop DX
    pop BX
    pop AX
ENDM

writeln MACRO msg
    push AX
    push DX

    mov AH, 09h
    mov DX, offset msg
    int 21h

    pop DX
    pop AX
ENDM


START:
    mov AX, @data
    mov DS, AX


    writeln msg_greet

    ; read x

    writeln msg_input_x
    readln buf_x_suff
    newline 

    mov BX, offset buf_x
    mov CX, 10
    call str2num
    mov SI, AX


    ; read y

    writeln msg_input_y
    readln buf_y_suff
    newline

    mov BX, offset buf_y
    mov CX, 10
    call str2num
    mov DI, AX


    ; common for all ops

    mov BX, offset buf_res
    mov CX, 10

    ; add

    mov AX, SI
    add AX, DI

    pushf

    call num2str
    writeln msg_res_add
    writeln buf_res
    newline

    popf

    jno skip_report_overflow_0
    writeln err_result_overflow
    skip_report_overflow_0:

    ; sub

    mov AX, SI
    sub AX, DI

    pushf

    call num2str
    writeln msg_res_sub
    writeln buf_res
    newline

    popf

    jno skip_report_overflow_1
    writeln err_result_overflow
    skip_report_overflow_1:

    ; mul

    mov AX, SI
    imul DI

    pushf

    call num2str
    writeln msg_res_mul
    writeln buf_res
    newline

    popf

    jo report_overflow_2
    test DX, DX
    jz skip_report_overflow_2
    report_overflow_2:
    writeln err_result_overflow
    skip_report_overflow_2:

    ; div

    cmp DI, 0
    je divide_by_zero

    mov AX, SI
    cwd 
    idiv DI

    call num2str
    writeln msg_res_div
    writeln buf_res
    newline

    jmp divide_by_non_zero
    divide_by_zero:
    writeln err_division_by_zero
    divide_by_non_zero:


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
            mul CX

            ; test for overflow
            test DX, DX
            jz str2num_skip_detect_overflow_0
            or AX, 8000h 
            str2num_skip_detect_overflow_0:

            xor DH, DH
            mov DL, byte ptr [BX]
            sub DX, "0"
            ; NOTE here base might base overflow (DX > CX)
            add AX, DX
        
            inc BX
            cmp byte ptr [BX], "$"
            jne str2num_loop_next_char

        test AX, 8000h
        jz str2num_no_err

        str2num_err_overflow:
            writeln err_input_overflow

        str2num_no_err:
            
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

    num2str PROC ; AX - num, BX - str ptr (as long to hold the num), CX - base  ->  [BX] - result
        NUM_END equ -1
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

        push NUM_END
        num2str_loop_next_char:
            xor DX, DX
            div CX

            push DX
        
            test AX, AX
            jnz num2str_loop_next_char

        num2str_loop_pop_digits:
            pop DX

            cmp DX, NUM_END
            je num2str_end_loop_pop_digits

            ; NOTE here base might base overflow (DX > CX)
            add DX, "0"
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
