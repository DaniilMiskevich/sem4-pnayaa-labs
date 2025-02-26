.model small

.stack 100h

.data 
    buf db 200 dup("$")
    buf_end dw buf+200

    msg_start db "-- reverse words in a string --", 0Ah, 0Dh, "$"
    msg_input_string db "enter a string (til '\n'): ", "$"
    msg_output_string db "resulted stirng with words reversed: ", "$"
.code

_start:
    mov AX, @data
    mov DS, AX

    ; print start message
    lea DX, msg_start
    call println

    ; print input string message
    lea DX, msg_input_string
    call println

    lea DI, buf
    mov BX, buf_end
    loop_read_char:
        ; read char from stdin
        mov AL, 00h
        mov AH, 01h
        int 21h

        ; add read char to the buf and move to the next element
        mov [DI], AL
        inc DI

        ; if got '\n' - end loop
        cmp AL, 0Dh
        je end_loop_read_char

        ; if end of the buf - end loop
        cmp DI, BX
        jge end_loop_read_char

        ; otherwise - continue
        jmp loop_read_char
    end_loop_read_char:
    ; make string start with space and remove the trailing '\n'
    mov CX, 1
    lea SI, buf
    call rotate_string
    mov byte ptr [SI], " "

    ; shrink the buffer to the size of a string
    mov BX, DI

    ; the main algo
    lea SI, buf
    loop_main:
        ; find length of the last word = -addr(last space) + addr(end) 
        call find_last_space
        neg CX 
        add CX, BX

        ; rotate the string to the length of a last word
        call rotate_string

        ; shift the beginning of the string to the length of that word
        add SI, CX

        ; until end of the string - repeat
        cmp SI, BX
        jnge loop_main
    end_loop_main:

    ; return the trailing '\n' by setting it and rotating string to the len-1
    lea SI, buf
    mov byte ptr [SI], 0Dh
    mov CX, SI
    neg CX
    add CX, BX
    add CX, -1
    call rotate_string

    ; print the output result message
    lea DX, msg_output_string
    call println

    ; print the result
    lea DX, buf
    call println
    ; newline for prettier output
    mov AH, 02h
    mov DL, 0Ah
    int 21h
    mov AH, 02h
    mov DL, 0Dh
    int 21h
    
    ; exit
    mov AL, 00h
    exit:
        mov AH, 4Ch
        int 21h


println:; (DX: string pointer) -> ()
    push AX

    mov AH, 09h
    int 21h

    pop AX
    ret


find_last_space:; (BX: string end pointer, SI: string pointer) -> (CX: last space pointer)
    push BX

    loop_find_last_space:
        dec BX
        cmp BX, SI
        jl end_loop_find_last_space;

        cmp byte ptr [BX], " "
        jne loop_find_last_space
    end_loop_find_last_space:

    mov CX, BX

    pop BX
    ret


rotate_string:; (BX: string end pointer, CX: shift amount, SI: string pointer) -> ()
    push CX
    push DX
    push DI

    loop_shift_string:
        mov DI, SI
        mov DL, byte ptr [BX-1]
        loop_shift_char:
            mov DH, [DI]
            mov [DI], DL

            ; fast swapping
            rol DX, 8
            
            inc DI

            ; if past the end - end loop
            cmp DI, BX
            jge end_loop_shift_char;

            ; mov DL, [DI]
            ; mov [DI], AL
            jmp loop_shift_char
        end_loop_shift_char:
        loop loop_shift_string

    pop DI
    pop DX
    pop CX
    ret


end

