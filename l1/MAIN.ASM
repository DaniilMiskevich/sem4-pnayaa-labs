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
    read_next_char:
        ; read char from stdin
        mov AL, 00h
        mov AH, 01h
        int 21h

        ; if got '\n' - end loop
        cmp AL, 0Dh
        je end_read_next_char

        ; add read char to the buf and move to the next element
        mov [DI], AL
        inc DI

        ; if end of the buf - end loop
        cmp DI, BX
        jge end_read_next_char

        ; otherwise - continue
        jmp read_next_char
    end_read_next_char:
    ; shrink the buffer to the size of a string
    mov BX, DI

    ; the main part of the algo is:
    ; - to find the last word in a string
    ; - rotate string to the length of that word
    ; - repeat, with the beginning of a string is shifted the same amount

    ; find last word
    do_the_job:
        mov SI, BX
        find_the_last_space:
            dec SI
            cmp byte ptr [SI], " "
            jne find_the_last_space

        ; len(last word) = addr(end)-1 - addr(last space)
        mov CX, SI
        neg CX 
        add CX, BX
        add CX, -1

        lea SI, buf
        shift_string:
            mov DI, SI
            mov DL, byte ptr [BX-1]
            shift_char:
                mov DH, [DI]
                mov [DI], DL

                ; fast swapping
                rol DX, 8
                
                inc DI

                ; if past the end - end loop
                cmp DI, BX
                jge end_shift_char;

                ; mov DL, [DI]
                ; mov [DI], AL
                jmp shift_char
            end_shift_char:

            inc SI

            loop shift_string
            
            
            
    



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


end

