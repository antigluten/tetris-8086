.model small
.stack 100h
.8086

.data

field              byte       200       DUP(0)
FIELD_HEIGHT       equ        25
FIELD_WIDTH        equ        30

CONSOLE_WIDTH      equ        160

.code

clear proc
    mov ax, 3
    int 10h 
clear endp

draw proc
    mov si, offset field
    mov di, 0
    mov bx, FIELD_HEIGHT

    @row:
        mov ax, 0b800h
        mov es, ax

        mov cx, FIELD_WIDTH

        @col:
            cmp bx, 1
            je @border

            cmp bx, FIELD_HEIGHT
            je @border

            cmp cx, 1
            je @border

            cmp cx, FIELD_WIDTH
            je @border
            
            call @space

            @print:
                call @background
                stosw

            loop @col

        ; DI = CONSOLE_WIDTH * Y + X
        add di, CONSOLE_WIDTH - 2 * FIELD_WIDTH

        dec bx
        jnz @row
    ret

    @background:
        mov ah, 0Fh          ; white/black
        ret

    @space:
        mov al, 020h         ; empty space
        ret

    @border:
        mov al, 040h ; @
        jmp @print

draw endp

main proc
	mov ax,@data
	mov ds,ax

    call clear
    call draw

    ; wait for a keypress
    mov ah, 00
    int 16h

    ; exit
    mov ah, 4ch
    int 21h

	.exit
main endp
end main
