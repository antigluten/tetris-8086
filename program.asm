.model small
.stack 100h
.8086

.data

FIELD_HEIGHT       equ        22
FIELD_WIDTH        equ        20
field              byte       FIELD_HEIGHT * FIELD_WIDTH       DUP(0)

FIGURE_HEIGHT      equ        4
FIGURE_WIDTH       equ        4

CONSOLE_WIDTH      equ        160

cur_figure         dw         offset    z_figure
cur_x              db         0
cur_y              db         0

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
    ; [SI: DI]
    ; [field, 0]
    mov si, offset field                ; array
    mov di, 0                           ; index
    mov bx, FIELD_HEIGHT

    mov ax, 0b800h                      ; videoram
    mov es, ax
    @row:
        mov cx, FIELD_WIDTH

        @col:
            cmp cx, 1
            je @right_border

            cmp cx, 2
            je @mark_sign
            
            cmp cx, FIELD_WIDTH - 1
            je @mark_sign

            cmp cx, FIELD_WIDTH
            je @left_border
            
            cmp bx, 2
            je @border

            cmp bx, 1
            je @border_frame

            @skip:

            call @space

            @print:
                call @background
                ; AX -> ES[DI]
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

    @left_border:
        cmp bx, 1
        je @skip
        mov al, 3ch
        jmp @print

    @mark_sign:
        cmp bx, 1
        je @skip

        mov al, 7ch ;21h
        jmp @print

    @right_border:
        cmp bx, 1
        je @skip

        mov al, 3eh
        jmp @print

    @border:
        mov al, 3dh
        jmp @print

    @border_frame:
        mov dx, cx

        and dx, 1

        cmp dx, 0
        jne @mod

        mov al, 5ch

        jmp @print

        @mod:
        mov al, 2fh
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

    mov di, ax

    ; TODO: - temporary add 3
    add di, 3

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

            mov ah, 0Fh          ; white/black
            mov al, 5bh
            stosw

            mov al, 5dh
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

fallLoop proc
@fallLoop:
    call draw
    call draw_figure

    ret

    ; delay for 1 sec
    mov ah, 86h
    mov dx, 04240h
    mov cx, 0000fh
    int 15h

    ; inc y_cord
    mov al, byte ptr [cur_y]
    inc al
    mov byte ptr [cur_y], al

    ; check for colision
    cmp al, FIELD_HEIGHT - 3
    jbe @fallLoop

    ;call checkCollision
    ;jnc @fallLoop

    ret
fallLoop endp

checkCollision proc
    ; BL = cur_x, BH = cur_y
    mov bx, word ptr [cur_x]
    ; cur_y * field_width
    mov al, bh
    mov ah, field_width
    mul ah

    ; += cur_x
    mov ch, 0
    mov cl, bl
    add ax, cx
    add ax, offset field
    mov di, ax
    ;
    mov si, word ptr [cur_figure]
    ;
    mov dx, FIGURE_HEIGHT
    @@rowC:
        mov cx, FIGURE_WIDTH
        @@colC:
        lodsb
        or al, al
        jz  @@skipC
        cmp bl, FIGURE_WIDTH
        jae @@collides
        cmp bh, FIGURE_HEIGHT
        jae @@collides

        mov al, byte ptr [di]
        or al, al
        jnz @@collides
    @@skipC:
        inc bl
        inc di
        loop @@colC
        add di, FIELD_WIDTH-FIGURE_WIDTH
        sub bl, FIGURE_WIDTH
        inc bh
        dec dx
        jnz @@rowC
        clc
        ret
    @@collides:
        stc
        ret
checkCollision endp

main proc
	mov ax,@data
	mov ds,ax

    call clear
    call fallLoop

    ; wait for a keypress
    mov ah, 00
    int 16h

    ; exit
    mov ah, 4ch
    int 21h

	.exit
main endp
end main
