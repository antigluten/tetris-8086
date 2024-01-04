.model small
.stack 100h
.8086

.data

field              byte       200       DUP(0)
FIELD_HEIGHT       equ        25
FIELD_WIDTH        equ        30

CONSOLE_WIDTH      equ        160

cur_figure     dw         offset    square
cur_x              db         0
cur_y              db         1

z_figure   db 0,3,0,0
           db 3,3,0,0
           db 3,0,0,0
           db 0,0,0,0

l_figure   db 3,0,0,0
           db 3,0,0,0
           db 3,0,0,0
           db 3,0,0,0

square     db 4,4,0,0
           db 4,4,0,0
           db 0,0,0,0
           db 0,0,0,0

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

draw_figure proc
    mov bx, word ptr [cur_x] ; BL = cur_x, BH = cur_y
    ; cur_y * 160
    mov al, bh
    mov ah, 160
    mul ah
    ; += cur_x * 2 + 1
    mov bh, 0
    shl bx, 1
    inc bx
    shl bx, 1
    add ax, bx

    ;add ax, FIELD_WIDTH * 2 - 4 - 16

    mov di, ax

    mov ax, 0b800h
    mov es, ax

    mov si, word ptr [cur_figure]
    mov bx, 4
@@row: 
    mov cx, 4
    @@col: 
        lodsb
        or al, al
        jz @@skip
        mov ah, al
        mov al, 0dbh
        stosw
        stosw
        loop @@col
        jmp @@end
@@skip:
    add di, 4
    loop @@col
@@end:
    add di, CONSOLE_WIDTH - 2 * 8
    dec bx
    jnz @@row

    ret
draw_figure endp

main proc
	mov ax,@data
	mov ds,ax

    call clear
    call draw
    call draw_figure

    ; wait for a keypress
    mov ah, 00
    int 16h

    ; exit
    mov ah, 4ch
    int 21h

	.exit
main endp
end main
